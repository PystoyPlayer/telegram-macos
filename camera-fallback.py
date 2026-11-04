from pathlib import Path
import subprocess,sys
root=Path(sys.argv[1]).resolve()
path='packages/TelegramCallsCore/Sources/TelegramCallsCore/PCallSession.swift'
for name in ['before','after']:
 s=subprocess.check_output(['git','show','561169337e838c3281f7cfe24652757a5b522df9:'+path],cwd=root,text=True) if name=='before' else (root/path).read_text()
 line = '\n'.join(l.strip() for l in s.splitlines() if 'let cameraId = devicesContext.currentCameraId' in l or ('self.videoCapturer = OngoingCallVideoCapturer(' in l and ('devicesContext.currentCameraId' in l or '(cameraId)' in l)))
 code='''import Foundation
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
  SOURCE
  return videoCapturer!.id
 }
}
let cases: [(String?,String?,String)] = [(nil,nil,""),(nil,"chosen","chosen"),(nil,"unavailable",""),("resolved",nil,"resolved"),("resolved","chosen","resolved")]
var passed=0
for (resolved,saved,wanted) in cases {
 let actual=Probe().resolve(resolved,saved)
 if actual == wanted { passed += 1 }
}
print("Camera selection: \\(passed)/\\(cases.count)")
if passed != cases.count { exit(1) }
'''.replace('SOURCE',line)
 p=Path('camera-'+name+'.swift');p.write_text(code)
 r=subprocess.run(['xcrun','swift',str(p)],text=True,capture_output=True)
 Path('camera-'+name+'.txt').write_text(r.stdout+r.stderr)
 print(name,r.returncode,r.stdout.strip())
