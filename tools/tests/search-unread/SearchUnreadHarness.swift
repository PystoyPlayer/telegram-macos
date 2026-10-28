import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Postbox
import TelegramContext
import TelegramTheme
import Localization

private var searchReadEvidence: SearchReadEvidence?
private final class SearchReadButton: NSButton {
    var invoke: (() -> Void)?
    @objc func run() { invoke?() }
}
private final class SearchReadEvidence {
    let context: any AccountContextProtocol
    let window: Window
    let status: NSTextField
    var peer: Peer?
    var request = MetaDisposable()
    let previewRequest = MetaDisposable()
    var isRunning = false
    var checks: [[String: Any]] = []
    var original = false
    init(context: any AccountContextProtocol) {
        self.context = context
        window = Window(contentRect: NSMakeRect(0, 0, 650, 350), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "Search chat actions — Saved Messages only"
        let host = View(frame: NSMakeRect(0, 0, 650, 350))
        host.backgroundColor = theme.colors.chatBackground
        window.contentView = host
        status = NSTextField(labelWithString: "Production search menus · no chat list or messages")
        status.textColor = theme.colors.text
        status.frame = NSMakeRect(20, 20, 610, 30)
        host.addSubview(status)
        for (i, title) in ["Show result menu", "Show top-peer menu", "Check unread toggle"].enumerated() {
            let button = SearchReadButton(frame: NSMakeRect(20, 75+CGFloat(i)*65, 250, 35))
            button.title = title
            button.bezelStyle = .rounded
            button.target = button
            button.action = #selector(SearchReadButton.run)
            button.invoke = { [weak self, weak button] in
                guard let self, let button else { return }
                if i == 2 { self.run() } else { self.show(top: i == 1, button: button) }
            }
            host.addSubview(button)
        }
        previewRequest.set((context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.peerId)) |> deliverOnMainQueue).start(next: { [weak self] peer in self?.peer = peer?._asPeer() }))
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    func menu(top: Bool) -> Signal<[ContextMenuItem], NoError> {
        guard let peer else { return .single([]) }
        if top { return PopularPeerItem(type: .peer(peer, nil, false), context: context, action: { _ in }).menuItems(in: .zero) }
        let arguments = SearchControllerArguments(context: context, target: .common(.root), removeRecentPeerId: { _ in }, clearRecent: {}, openTopPeer: { _ in }, setPeerAsTag: { _ in }, openStory: { _ in }, openStorySearch: { _ in }, toggleMessageSourceValue: { _ in }, removeAd: { _, _ in }, approveGlobalSearch: { _, _ in })
        return peerContextMenuItems(peer: peer, pinnedItems: [], arguments: arguments, isRecent: true)
    }
    func show(top: Bool, button: NSButton) {
        guard !isRunning else { return }
        previewRequest.set((menu(top: top) |> deliverOnMainQueue).start(next: { [weak self] items in
            guard let self, let host = self.window.contentView else { return }
            host.subviews.filter { $0 is NSPopUpButton }.forEach { $0.removeFromSuperview() }
            let popup = NSPopUpButton(frame: NSMakeRect(300, 90, 310, 35), pullsDown: true)
            let menu = NSMenu(title: "Search chat actions")
            menu.addItem(NSMenuItem(title: top ? "Top-peer context menu" : "Result context menu", action: nil, keyEquivalent: ""))
            for item in items { menu.addItem(item) }
            popup.menu = menu
            popup.setAccessibilityLabel("Production search actions")
            host.addSubview(popup)
        }))
    }
    func record(_ name: String, _ pass: Bool) { checks.append(["name": name, "pass": pass]) }
    func run() {
        guard !isRunning else { return }
        isRunning = true
        previewRequest.set(nil)
        window.contentView?.subviews.filter { $0 is NSPopUpButton }.forEach { $0.removeFromSuperview() }
        checks.removeAll()
        request.set((context.engine.data.get(TelegramEngine.EngineData.Item.Messages.PeerReadCounters(id: context.peerId)) |> deliverOnMainQueue).start(next: { [weak self] state in
            guard let self else { return }
            guard state.count == 0 else { self.isRunning = false; self.status.stringValue = "Skipped: Saved Messages has unread incoming messages"; return }
            self.original = state.markedUnread
            self.phase(unread: !self.original, completion: { self.phase(unread: self.original, completion: { self.finish() }) })
        }))
    }
    func phase(unread: Bool, completion: @escaping () -> Void) {
        let expected = unread ? strings().chatListContextMaskAsUnread : strings().chatListContextMaskAsRead
        let signal = combineLatest(menu(top: false), menu(top: true)) |> deliverOnMainQueue
        request.set(signal.start(next: { [weak self] list, top in
            guard let self else { return }
            let action = list.first(where: { $0.title == expected })
            self.record("result menu offers \(expected)", action != nil)
            self.record("top-peer menu offers \(expected)", top.contains(where: { $0.title == expected }))
            action?.handler?()
            DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                self.request.set((self.context.engine.data.get(TelegramEngine.EngineData.Item.Messages.PeerReadCounters(id: self.context.peerId)) |> deliverOnMainQueue).start(next: { state in
                    self.record("Saved Messages unread flag is \(unread)", state.markedUnread == unread)
                    completion()
                }))
            }
        }))
    }
    func finish() {
        isRunning = false
        let passed = checks.filter { $0["pass"] as? Bool == true }.count
        status.stringValue = "\(passed)/\(checks.count) checks passed" + (passed == checks.count ? " · Original unread flag restored" : " · Verification failed; inspect unread flag")
        let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("search-unread.json")
        if let data = try? JSONSerialization.data(withJSONObject: checks, options: [.prettyPrinted, .sortedKeys]) { try? data.write(to: file, options: .atomic) }
    }
}
func codexInstallSearchReadEvidence(context: any AccountContextProtocol, parent: NSView) {
    let button = SearchReadButton(frame: NSMakeRect(20, 210, 260, 30))
    button.title = "Search unread validation"
    button.bezelStyle = .rounded
    button.target = button
    button.action = #selector(SearchReadButton.run)
    button.invoke = {
        if let evidence = searchReadEvidence {
            evidence.window.makeKeyAndOrderFront(nil)
        } else {
            searchReadEvidence = SearchReadEvidence(context: context)
        }
    }
    parent.addSubview(button)
}
