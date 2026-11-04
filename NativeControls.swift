private var codexCornerControls: CodexCornerControls?
private final class CodexCornerButton: NSButton {
    var invoke: (() -> Void)?
    @objc func run() { invoke?() }
}
private final class CodexCornerControls {
    let context: AccountContext
    let status: NSTextField
    var originalFilters: [ChatListFilter]?
    var originalSettings: ChatListFoldersSettings?
    var folderMode = "none"
    var referenceOpened = false
    init(context: AccountContext) {
        self.context = context
        let parent = context.window.contentView!
        status = NSTextField(labelWithString: "Corner validation controls")
        status.frame = NSMakeRect(12, parent.isFlipped ? parent.bounds.height - 108 : 82, 530, 24)
        status.autoresizingMask = parent.isFlipped ? [.minYMargin] : [.maxYMargin]
        status.textColor = .systemBlue
        parent.addSubview(status)
        let controls: [(String, () -> Void)] = [
            ("No folders", { [weak self] in self?.folders(nil) }),
            ("Horizontal", { [weak self] in self?.folders(false) }),
            ("Vertical", { [weak self] in self?.folders(true) }),
            ("Restore", { [weak self] in self?.restore() }),
            ("Wide", { [weak self] in self?.resize(NSMakeSize(1100, 800)) }),
            ("Compact", { [weak self] in self?.resize(NSMakeSize(560, 700)) }),
            ("Inspect", { [weak self] in self?.inspect() }),
            ("Public reference", { [weak self] in self?.openReference() })
        ]
        for (index, control) in controls.enumerated() {
            let y = parent.isFlipped ? parent.bounds.height - 72 + CGFloat(index / 4) * 30 : 10 + CGFloat(index / 4) * 30
            let button = CodexCornerButton(frame: NSMakeRect(12 + CGFloat(index % 4) * 125, y, 120, 28))
            button.autoresizingMask = parent.isFlipped ? [.minYMargin] : [.maxYMargin]
            button.title = control.0
            button.bezelStyle = .rounded
            button.target = button
            button.action = #selector(CodexCornerButton.run)
            button.invoke = control.1
            parent.addSubview(button)
        }
        context.window.title = "Telegram corner validation"
    }
    func resize(_ size: NSSize) {
        var frame = context.window.frame
        frame.origin.y += frame.height - size.height
        frame.size = size
        context.window.setFrame(frame, display: true)
    }
    func folders(_ vertical: Bool?) {
        _ = (combineLatest(context.engine.peers.updatedChatListFilters() |> take(1), chatListFolderSettings(context.account.postbox) |> take(1)) |> deliverOnMainQueue).startStandalone(next: { [weak self] filters, settings in
            guard let self else { return }
            if self.originalFilters == nil {
                guard filters.count <= 1 else { self.status.stringValue = "Skipped: account already has folders"; return }
                self.originalFilters = filters
                self.originalSettings = settings
            }
            let data = ChatListFilterData(isShared: false, hasSharedLinks: false, categories: [.groups], excludeMuted: false, excludeRead: false, excludeArchived: false, includePeers: .init(), excludePeers: [], color: nil)
            let test = ChatListFilter.filter(id: 99, title: .init(text: "Test", entities: [], enableAnimations: false), emoticon: nil, data: data)
            self.folderMode = vertical == nil ? "none" : (vertical! ? "vertical" : "horizontal")
            _ = self.context.engine.peers.updateChatListFiltersInteractively { _ in vertical == nil ? [.allChats] : [.allChats, test] }.startStandalone()
            _ = updateChatListFolderSettings(self.context.account.postbox) { $0.withUpdatedSidebar(vertical ?? false).withUpdatedSidebarInteracted(true) }.startStandalone()
            self.status.stringValue = "Folder mode: \(self.folderMode)"
        })
    }
    func restore() {
        guard let filters = originalFilters, let settings = originalSettings else { return }
        _ = context.engine.peers.updateChatListFiltersInteractively { _ in filters }.startStandalone()
        _ = updateChatListFolderSettings(context.account.postbox) { _ in settings }.startStandalone()
        status.stringValue = "Original folder preferences restored"
    }
    func openReference() {
        guard !referenceOpened else { return }
        referenceOpened = true
        _ = (context.engine.peers.resolvePeerByName(name: "durov", referrer: nil) |> deliverOnMainQueue).startStandalone(next: { [weak self] result in
            guard let self else { return }
            if case let .result(peer) = result, let peer {
                self.context.bindings.rootNavigation().push(ChatController(context: self.context, chatLocation: .peer(peer.id), mode: .history), false)
            }
        })
    }
    func inspect() {
        context.window.title = "Telegram corner validation"
        var values: [[String: Any]] = []
        func visit(_ view: NSView) {
            guard !view.isHidden else { return }
            let name = String(describing: type(of: view))
            if ["MainController_View", "LeftSidebarView", "EntertainmentSidebarView", "ChatTitleBarView", "ChatHeaderBubblesView"].contains(name) {
                var record: [String: Any] = ["class": name, "frame": NSStringFromRect(view.frame)]
                if #available(macOS 27, *), let radii = view.effectiveCornerRadii {
                    record["effectiveTopLeft"] = radii.topLeft
                    record["effectiveTopRight"] = radii.topRight
                }
                record["childRadii"] = view.subviews.map { ($0 as? LiquidGlassView)?.cornerRadius ?? $0.layer?.cornerRadius ?? -1 }
                if let glass = view as? LiquidGlassView { record["appliedRadius"] = glass.cornerRadius }
                values.append(record)
            }
            for child in view.subviews { visit(child) }
        }
        if let root = context.window.contentView { visit(root) }
        let compact = context.window.frame.width < 650
        let result: [String: Any] = ["styleMask": context.window.styleMask.rawValue, "contentFrame": NSStringFromRect(context.window.contentView!.frame), "contentLayoutRect": NSStringFromRect(context.window.contentLayoutRect), "folderMode": folderMode, "compactWidth": compact, "windowWidth": context.window.frame.width, "windowHeight": context.window.frame.height, "views": values, "os": ProcessInfo.processInfo.operatingSystemVersionString]
        let name = "\(folderMode)-\(compact ? "compact" : "wide").json"
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + name)
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) { try? data.write(to: url) }
        status.stringValue = "Inspected \(folderMode) / \(compact ? "compact" : "wide")"
    }
}
func codexInstallCornerControls(context: AccountContext) {
    guard codexCornerControls == nil, ProcessInfo.processInfo.environment["TELEGRAM_VALIDATION_ROOT"] != nil else { return }
    codexCornerControls = CodexCornerControls(context: context)
}
