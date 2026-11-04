from pathlib import Path
import argparse, subprocess
p = argparse.ArgumentParser()
p.add_argument("--source-root", type=Path, required=True)
p.add_argument("command", nargs=argparse.REMAINDER)
a = p.parse_args()
assert a.command and a.command[0] == "--", "Pass -- followed by your normal build command"
main = a.source_root / "Telegram-Mac/app/MainViewController.swift"
shared = a.source_root / "Telegram-Mac/account/SharedAccountContext.swift"
original = {p: p.read_bytes() for p in [main, shared]}
try:
    source = main.read_text()
    marker = "        navigation.viewDidAppear(animated)"
    assert source.count(marker) == 1
    main.write_text(source.replace(marker, marker + "\n        codexInstallAudioStartupValidation(context: context.sharedContext)"))
    shared.write_text(shared.read_text() + "\n" + (Path(__file__).parent / "NativeControls.swift").read_text())
    subprocess.run(a.command[1:], cwd=a.source_root, check=True)
finally:
    for path, data in original.items():
        path.write_bytes(data)
