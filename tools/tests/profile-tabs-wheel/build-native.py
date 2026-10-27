from pathlib import Path
import argparse
import os
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[3])
parser.add_argument('--log', type=Path, required=True)
parser.add_argument('command', nargs=argparse.REMAINDER)
args = parser.parse_args()
target = args.repo / 'packages/PeerInfoUI/Sources/PeerInfoUI/PeerMediaTabsView.swift'
original = target.read_bytes()
text = original.decode()
marker = '    override func scrollWheel(with event: NSEvent) {\n'
assert text.count(marker) == 1
legacy = '        defer { codexScrollObserved?(scrollOffset) }\n        if codexLegacyWheel {\n            let visibleWidth = clipView.frame.width\n            if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY), contentWidth > visibleWidth {\n                let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : event.scrollingDeltaX * 10\n                scrollOffset = clampedScrollOffset(scrollOffset - delta, visibleWidth: visibleWidth)\n                contentView.setFrameOrigin(NSMakePoint(-scrollOffset, 0))\n            } else { super.scrollWheel(with: event) }\n            return\n        }\n'
text = text.replace(marker, '    var codexLegacyWheel = false\n    var codexScrollObserved: ((CGFloat) -> Void)?\n' + marker + legacy)
marker = '        self.account = account\n'
assert text.count(marker) == 1
text = text.replace(marker, marker + '        DispatchQueue.main.async { codexInstallProfileWheelEvidence(account: account) }\n')
text += (Path(__file__).parent / 'NativeHarness.swift').read_text()
command = args.command
if command and command[0] == '--': command = command[1:]
if not command:
    command = ['xcodebuild', '-workspace', 'Telegram-Mac.xcworkspace', '-scheme', 'Telegram', '-configuration', 'Debug', '-destination', 'platform=macOS,arch=arm64', 'CODE_SIGNING_ALLOWED=NO', 'build']
def atomic(data):
    temporary = target.with_suffix('.swift.restore')
    temporary.write_bytes(data)
    os.replace(temporary, target)
try:
    atomic(text.encode())
    with args.log.open('w') as log:
        result = subprocess.run(command, cwd=args.repo, stdout=log, stderr=subprocess.STDOUT)
    raise SystemExit(result.returncode)
finally:
    atomic(original)
