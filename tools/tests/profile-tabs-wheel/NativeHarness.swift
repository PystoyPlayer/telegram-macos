
private var codexWheelWindow: Window?
func codexInstallProfileWheelEvidence(account: Account) {
    guard codexWheelWindow == nil else { return }
    let window = Window(contentRect: NSMakeRect(0, 0, 420, 280), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    codexWheelWindow = window
    window.title = "Profile tabs — mouse wheel comparison"
    let host = View(frame: NSMakeRect(0, 0, 420, 280))
    host.backgroundColor = theme.colors.background
    window.contentView = host
    let values = ["Members", "Media", "Files", "Links", "Music", "Voice Messages", "GIFs", "Polls"]
    var strips: [PeerMediaTabsView] = []
    for (index, title) in ["Before", "After"].enumerated() {
        let label = NSTextField(labelWithString: "\(title): offset 0")
        label.textColor = theme.colors.text
        label.frame = NSMakeRect(20, CGFloat(20 + index * 125), 380, 24)
        host.addSubview(label)
        let view = PeerMediaTabsView(frame: NSMakeRect(20, CGFloat(55 + index * 125), 380, 40))
        view.codexLegacyWheel = index == 0
        view.codexScrollObserved = { offset in label.stringValue = "\(title): offset \(Int(offset))" }
        host.addSubview(view)
        strips.append(view)
        let tabs = values.enumerated().map { PeerMediaTabsView.Tab(id: Int64($0.offset), title: $0.element, gifts: []) }
        view.update(tabs: tabs, selected: 0, account: account, animated: false)
        view.apply(frame: view.frame, transition: .immediate)
    }
    let apply = CodexWheelButton(frame: NSMakeRect(20, 245, 380, 30))
    apply.title = "Apply identical mouse-wheel event"
    apply.bezelStyle = .rounded
    apply.target = apply
    apply.action = #selector(CodexWheelButton.run)
    apply.invoke = {
        guard let cg = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: -30, wheel2: 0, wheel3: 0), let event = NSEvent(cgEvent: cg) else { return }
        for strip in strips { strip.scrollWheel(with: event) }
    }
    host.addSubview(apply)
    window.center()
    window.makeKeyAndOrderFront(nil)
}

private final class CodexWheelButton: NSButton {
    var invoke: (() -> Void)?
    @objc func run() { invoke?() }
}
