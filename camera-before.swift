import Foundation
struct OngoingCallVideoCapturer { let id: String; init(_ id: String) { self.id=id } }
struct Devices { var currentCameraId: String? }
struct Camera { let uniqueID: String }
struct Settings { var cameraInputDeviceId: String? }
struct Data { var voiceSettings: Settings }
final class Probe {
 var videoCapturer: OngoingCallVideoCapturer?
 func resolve(_ resolved: String?, _ saved: String?) -> String {
  let devicesContext=Devices(currentCameraId: resolved)
  let devices=[Camera(uniqueID: "chosen")]
  let data=Data(voiceSettings: Settings(cameraInputDeviceId: saved))
  self.videoCapturer = OngoingCallVideoCapturer(devicesContext.currentCameraId ?? "")
  return videoCapturer!.id
 }
}
let cases: [(String?,String?,String)] = [(nil,nil,""),(nil,"chosen","chosen"),(nil,"unavailable",""),("resolved",nil,"resolved"),("resolved","chosen","resolved")]
var passed=0
for (resolved,saved,wanted) in cases {
 let actual=Probe().resolve(resolved,saved)
 if actual == wanted { passed += 1 }
}
print("Camera selection: \(passed)/\(cases.count)")
if passed != cases.count { exit(1) }
