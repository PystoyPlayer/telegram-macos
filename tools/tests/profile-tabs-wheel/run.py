from pathlib import Path
import subprocess
import tempfile
import sys

root = Path(__file__).resolve().parents[3]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "packages/PeerInfoUI/Sources/PeerInfoUI/PeerMediaTabsView.swift"
text = source.read_text()

def method(signature):
    start = text.index(signature)
    opening = text.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (text[end] == "{") - (text[end] == "}")
        end += 1
    return text[start:end]

handler = method("    override func scrollWheel(with event: NSEvent)")
clamp = method("    private func clampedScrollOffset(")
fixture = (Path(__file__).parent / "ScrollTests.swift").read_text().replace("HANDLER", handler).replace("CLAMP", clamp)
with tempfile.TemporaryDirectory(prefix="profile-tabs-wheel-") as scratch:
    swift = Path(scratch) / "main.swift"
    executable = Path(scratch) / "tests"
    swift.write_text(fixture)
    subprocess.run(["swiftc", str(swift), "-o", str(executable)], check=True)
    raise SystemExit(subprocess.run([str(executable)]).returncode)
