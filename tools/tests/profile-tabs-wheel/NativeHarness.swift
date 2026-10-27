
private var codexWheelWindow: Window?
func codexInstallProfileWheelEvidence(account: Account) {
    guard codexWheelWindow == nil else { return }
    let window = Window(contentRect: NSMakeRect(0, 0, 420, 310), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    codexWheelWindow = window
    window.title = "Profile tabs — shared folder scroller"
    let host = View(frame: NSMakeRect(0, 0, 420, 310))
    host.backgroundColor = theme.colors.background
    window.contentView = host
    let values = ["Members", "Media", "Files", "Links", "Music", "Voice Messages", "GIFs", "Polls"]
    let beforeLabel = NSTextField(labelWithString: "Before: offset 0")
    let afterLabel = NSTextField(labelWithString: "After: offset 0")
    for (i, label) in [beforeLabel, afterLabel].enumerated() {
        label.textColor = theme.colors.text
        label.frame = NSMakeRect(20, CGFloat(20 + i * 125), 380, 24)
        host.addSubview(label)
    }
    let before = LegacyPeerMediaTabsView(frame: NSMakeRect(20, 55, 380, 40))
    let after = PeerMediaTabsView(frame: NSMakeRect(20, 180, 380, 40))
    host.addSubview(before)
    host.addSubview(after)
    before.update(tabs: values.enumerated().map { LegacyPeerMediaTabsView.Tab(id: Int64($0.offset), title: $0.element, gifts: []) }, selected: 0, account: account, animated: false)
    after.update(tabs: values.enumerated().map { PeerMediaTabsView.Tab(id: Int64($0.offset), title: $0.element, gifts: []) }, selected: 0, account: account, animated: false)
    before.apply(frame: before.frame, transition: .immediate)
    after.apply(frame: after.frame, transition: .immediate)
    before.codexScrollObserved = { offset in beforeLabel.stringValue = "Before: offset \(Int(offset))" }
    after.codexScrollObserved = { offset in afterLabel.stringValue = "After: offset \(Int(offset))" }
    let result = NSTextField(labelWithString: "Reverse immediately after reaching both ends.")
    result.textColor = theme.colors.text
    result.frame = NSMakeRect(20, 275, 380, 24)
    host.addSubview(result)
    let apply = CodexWheelButton(frame: NSMakeRect(20, 235, 380, 30))
    apply.title = "Check edges and immediate reversal"
    apply.bezelStyle = .rounded
    apply.target = apply
    apply.action = #selector(CodexWheelButton.run)
    apply.invoke = {
        func event(_ dy: Int32) -> NSEvent {
            let cg = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: dy, wheel2: 0, wheel3: 0)!
            cg.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
            return NSEvent(cgEvent: cg)!
        }
        for view in [before as NSView, after as NSView] { view.scrollWheel(with: event(-10000)) }
        let end = after.codexScrollOffset
        for view in [before as NSView, after as NSView] { view.scrollWheel(with: event(12)) }
        let reversed = after.codexScrollOffset
        after.layout()
        let retained = after.codexScrollOffset == reversed
        for view in [before as NSView, after as NSView] { view.scrollWheel(with: event(10000)); view.scrollWheel(with: event(-12)) }
        let startReversed = after.codexScrollOffset
        for view in [before as NSView, after as NSView] { view.scrollWheel(with: event(-10000)); view.scrollWheel(with: event(12)) }
        let passed = end > 12 && reversed == end - 12 && retained && startReversed == 12 && after.selectedId == 0
        result.stringValue = passed ? "PASS: both ends reverse immediately; layout retains offset" : "FAIL: edge reversal or selection"
    }
    host.addSubview(apply)
    window.center()
    window.makeKeyAndOrderFront(nil)
}
private final class CodexWheelButton: NSButton {
    var invoke: (() -> Void)?
    @objc func run() { invoke?() }
}
