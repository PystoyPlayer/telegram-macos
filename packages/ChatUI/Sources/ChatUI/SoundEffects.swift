import Cocoa
import CoreAudio
#if SHARE
import TelegramThemeShare
#else
import TelegramTheme
#endif

public enum SoundEffect {
    case quizCorrect
    case quizIncorrect
    case confetti
    case sent
    public var name: String {
        switch self {
        case .quizCorrect:
            return "quiz-correct"
        case .quizIncorrect:
            return "quiz-incorrect"
        case .confetti:
            return "confetti"
        case .sent:
            return "sent"
        }
    }
    public var ext: String {
        switch self {
        case .quizCorrect, .quizIncorrect, .confetti, .sent:
            return "mp3"
        }
    }
}


private func soundEffectOutputIdentifier() -> String? {
    func property<Value>(_ device: AudioObjectID, _ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope, _ element: AudioObjectPropertyElement, _ initial: Value) -> Value? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
        var value = initial
        var size = UInt32(MemoryLayout<Value>.size)
        let status = withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(device, &address, 0, nil, &size, pointer)
        }
        guard status == noErr, size == MemoryLayout<Value>.size else { return nil }
        return value
    }

    guard let device = property(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain, AudioDeviceID(0)), device != kAudioObjectUnknown else { return nil }
    let scope = kAudioDevicePropertyScopeOutput
    let main = kAudioObjectPropertyElementMain
    if property(device, kAudioDevicePropertyMute, scope, main, UInt32(0)) == 1 { return nil }
    if property(device, kAudioDevicePropertyVolumeScalar, scope, main, Float32(1)) == 0 { return nil }

    var channels: [UInt32] = [0, 0]
    var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyPreferredChannelsForStereo, mScope: scope, mElement: main)
    var size = UInt32(MemoryLayout<UInt32>.size * channels.count)
    let status = channels.withUnsafeMutableBytes { buffer in
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, buffer.baseAddress!)
    }
    if status == noErr, channels.allSatisfy({ $0 != main }), channels.allSatisfy({ channel in
        property(device, kAudioDevicePropertyMute, scope, channel, UInt32(0)) == 1 || property(device, kAudioDevicePropertyVolumeScalar, scope, channel, Float32(1)) == 0
    }) { return nil }

    guard let identifier = property(device, kAudioDevicePropertyDeviceUID, kAudioObjectPropertyScopeGlobal, main, Optional<CFString>.none) ?? nil else { return nil }
    return identifier as String
}

public func playSoundEffect(_ sound: SoundEffect) {
    guard let outputIdentifier = soundEffectOutputIdentifier() else { return }
    let afterSentSound:NSSound? = {
        
        let p = Bundle.main.path(forResource: sound.name, ofType: sound.ext)
        var sound:NSSound?
        if let p = p {
            sound = NSSound(contentsOfFile: p, byReference: true)
            sound?.playbackDeviceIdentifier = outputIdentifier
            sound?.volume = 0.1
        }
        
        return sound
    }()
    afterSentSound?.play()
}

public func playSoundEffectBeep() {
    guard soundEffectOutputIdentifier() != nil else { return }
    NSSound.beep()
}
