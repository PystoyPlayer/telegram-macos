import Foundation
import CoreAudio

func read<T>(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, _ initial: T) -> T? {
    var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var value = initial
    var size = UInt32(MemoryLayout<T>.size)
    let result = withUnsafeMutablePointer(to: &value) { AudioObjectGetPropertyData(object, &address, 0, nil, &size, $0) }
    return result == noErr ? value : nil
}

func list(_ selector: AudioObjectPropertySelector) -> [AudioObjectID] {
    var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }
    var values = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard values.withUnsafeMutableBytes({ AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, $0.baseAddress!) }) == noErr else { return [] }
    return values
}

func bundle(_ object: AudioObjectID) -> String {
    let value: Unmanaged<CFString>? = read(object, kAudioProcessPropertyBundleID, Optional<Unmanaged<CFString>>.none) ?? nil
    return value?.takeRetainedValue() as String? ?? ""
}

let started = Date()
var previous = ""
var events: [[String: Any]] = []
let destination = CommandLine.arguments[1]
let duration = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2])! : 45

func sample() {
    let processes: [[String: Any]] = list(kAudioHardwarePropertyProcessObjectList).compactMap { object in
        let id = bundle(object)
        guard id == "ru.keepcoder.Telegram" || id.hasPrefix("local.codex.Telegram") else { return nil }
        return ["bundle": id, "pid": read(object, kAudioProcessPropertyPID, Int32(0)) ?? -1, "input": read(object, kAudioProcessPropertyIsRunningInput, UInt32(0)) ?? 0, "output": read(object, kAudioProcessPropertyIsRunningOutput, UInt32(0)) ?? 0, "running": read(object, kAudioProcessPropertyIsRunning, UInt32(0)) ?? 0]
    }.sorted { ($0["pid"] as! Int32) < ($1["pid"] as! Int32) }
    let device = read(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, AudioObjectID(0)) ?? 0
    let state: [String: Any] = ["processes": processes, "outputDevice": device, "sampleRate": read(device, kAudioDevicePropertyNominalSampleRate, Double(0)) ?? 0, "transport": read(device, kAudioDevicePropertyTransportType, UInt32(0)) ?? 0]
    let data = try! JSONSerialization.data(withJSONObject: state, options: [.sortedKeys])
    let current = String(decoding: data, as: UTF8.self)
    if current != previous {
        previous = current
        var event = state
        event["time"] = Date().timeIntervalSince(started)
        events.append(event)
        try! JSONSerialization.data(withJSONObject: events, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: destination))
    }
}

sample()
let timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in sample() }
RunLoop.main.run(until: Date().addingTimeInterval(duration))
timer.invalidate()
print("Observed \(events.count) state changes")
