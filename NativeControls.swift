#if !SHARE
private var codexAudioStartupValidation: CodexAudioStartupValidation?

extension SharedAccountContext {
    fileprivate var codexDevicesInitialized: Bool {
        return devicesContextValue.with { $0 != nil }
    }
}

private final class CodexAudioProbeButton: NSButton {
    var invoke: (() -> Void)?
    @objc func run() { invoke?() }
}

private final class CodexAudioStartupValidation {
    let context: SharedAccountContext
    let window: Window
    let status: NSTextField
    let disposable = MetaDisposable()
    var events: [[String: Any]] = []
    init(context: SharedAccountContext) {
        self.context = context
        window = Window(contentRect: NSMakeRect(0, 0, 580, 260), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Audio startup validation — neutral controls"
        let content = View(frame: NSMakeRect(0, 0, 580, 260))
        window.contentView = content
        status = NSTextField(labelWithString: "")
        status.frame = NSMakeRect(24, 24, 532, 56)
        status.maximumNumberOfLines = 2
        content.addSubview(status)
        let button = CodexAudioProbeButton(frame: NSMakeRect(24, 110, 320, 32))
        button.title = "Access call devices concurrently"
        button.bezelStyle = .rounded
        button.target = button
        button.action = #selector(CodexAudioProbeButton.run)
        button.invoke = { [weak self] in self?.accessDevices() }
        content.addSubview(button)
        record("startup", values: ["devicesInitialized": context.codexDevicesInitialized])
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    func accessDevices() {
        let lock = NSLock()
        var instances = Set<ObjectIdentifier>()
        DispatchQueue.concurrentPerform(iterations: 64) { _ in
            let device = context.devicesContext
            lock.lock()
            instances.insert(ObjectIdentifier(device))
            lock.unlock()
        }
        record("concurrentAccess", values: ["uniqueInstances": instances.count, "devicesInitialized": context.codexDevicesInitialized])
        disposable.set((context.devicesContext.signal |> take(1) |> deliverOnMainQueue).start(next: { [weak self] devices in
            self?.record("devicesLoaded", values: ["cameras": devices.camera.count, "inputs": devices.audioInput.count, "outputs": devices.audioOutput.count, "loading": devices.loading])
        }))
    }
    func record(_ event: String, values: [String: Any]) {
        var record = values
        record["event"] = event
        events.append(record)
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "AudioStartup-native-events.json")
        if let data = try? JSONSerialization.data(withJSONObject: events, options: [.sortedKeys, .prettyPrinted]) { try? data.write(to: url) }
        status.stringValue = event + ": " + values.keys.sorted().map { "\($0)=\(values[$0]!)" }.joined(separator: ", ")
    }
}

func codexInstallAudioStartupValidation(context: SharedAccountContext) {
    guard codexAudioStartupValidation == nil, ProcessInfo.processInfo.environment["TELEGRAM_VALIDATION_ROOT"] != nil else { return }
    codexAudioStartupValidation = CodexAudioStartupValidation(context: context)
}

#endif
