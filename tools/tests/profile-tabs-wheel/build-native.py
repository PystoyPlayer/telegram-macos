from pathlib import Path
import argparse
import os
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[3])
parser.add_argument('--log', type=Path, required=True)
parser.add_argument('--baseline', default='05b79f3a')
parser.add_argument('command', nargs=argparse.REMAINDER)
args = parser.parse_args()
relative = 'packages/PeerInfoUI/Sources/PeerInfoUI/PeerMediaTabsView.swift'
target = args.repo / relative
original = target.read_bytes()
text = original.decode()
baseline = subprocess.check_output(['git', 'show', args.baseline + ':' + relative], cwd=args.repo, text=True)
marker = '    override func scrollWheel(with event: NSEvent) {\n'
def observe(source, expression):
    assert source.count(marker) == 1
    return source.replace(marker, '    var codexScrollObserved: ((CGFloat) -> Void)?\n    var codexScrollOffset: CGFloat { ' + expression + ' }\n' + marker + '        defer { codexScrollObserved?(codexScrollOffset) }\n')
text = observe(text, 'scrollView.clipView.bounds.minX')
baseline = observe(baseline, 'scrollOffset').replace('PeerMediaTabsView', 'LegacyPeerMediaTabsView')
marker = '        self.account = account\n'
assert text.count(marker) == 1
text = text.replace(marker, marker + '        DispatchQueue.main.async { codexInstallProfileWheelEvidence(account: account) }\n')
text += '\n' + baseline + (Path(__file__).parent / 'NativeHarness.swift').read_text()
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
