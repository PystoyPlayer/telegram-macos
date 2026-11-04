from pathlib import Path
import argparse, subprocess
p = argparse.ArgumentParser()
p.add_argument("--source-root", type=Path, required=True)
p.add_argument("--variant", choices=["before", "after"], required=True)
p.add_argument("command", nargs=argparse.REMAINDER)
a = p.parse_args()
assert a.command and a.command[0] == "--", "Pass -- followed by your normal build command"
evidence = Path(__file__).resolve().parent
controller = a.source_root / "packages/ChannelAdminUI/Sources/ChannelAdminUI/ChannelEventLogController.swift"
main = a.source_root / "Telegram-Mac/app/MainViewController.swift"
original = {f: f.read_bytes() for f in [controller, main]}
try:
    source = (evidence / ("controller-" + a.variant + ".swift")).read_text()
    marker = "let eventLogContext = context.engine.peers.channelAdminEventLog(peerId: peerId)"
    assert source.count(marker) == 1
    controller.write_text(source.replace(marker, "let eventLogContext = CodexEventLogContext()") + "\n" + (evidence / "NativeScene.swift").read_text())
    source = main.read_text()
    marker = "        navigation.viewDidAppear(animated)"
    assert source.count(marker) == 1
    main.write_text("import ChannelAdminUI\n" + source.replace(marker, marker + "\n        ChannelAdminUI.codexInstallEventLogHeaderScene(context: context)"))
    subprocess.run(a.command[1:], cwd=a.source_root, check=True)
finally:
    for f, data in original.items():
        f.write_bytes(data)
