from pathlib import Path
import argparse, subprocess
p = argparse.ArgumentParser()
p.add_argument("--source-root", type=Path, required=True)
p.add_argument("command", nargs=argparse.REMAINDER)
a = p.parse_args()
assert a.command and a.command[0] == "--", "Pass -- followed by your normal build command"
main = a.source_root / "Telegram-Mac/app/MainViewController.swift"
original = main.read_bytes()
try:
    source = main.read_text()
    marker = "        navigation.viewDidAppear(animated)"
    assert source.count(marker) == 1
    main.write_text(source.replace(marker, marker + "\n        codexInstallCornerControls(context: context)") + "\n" + (Path(__file__).parent / "NativeControls.swift").read_text())
    subprocess.run(a.command[1:], cwd=a.source_root, check=True)
finally:
    main.write_bytes(original)
