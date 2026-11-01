from pathlib import Path
import argparse
from run import parts

parser = argparse.ArgumentParser()
parser.add_argument('--source-root', type=Path, required=True)
parser.add_argument('--output-dir', type=Path, required=True)
args = parser.parse_args()
controller = args.source_root/'packages/ChannelAdminUI/Sources/ChannelAdminUI/ChannelEventLogController.swift'
main = args.source_root/'Telegram-Mac/app/MainViewController.swift'
source = controller.read_text()
_, callback, _ = parts(source)
assert callback, 'Use the fixed source revision for the combined before/fixed scene.'
scene = Path(__file__).with_name('NativeScene.swift').read_text().replace('CALLBACK_SOURCE', callback)
args.output_dir.mkdir(parents=True, exist_ok=True)
(args.output_dir/'ChannelEventLogController.swift').write_text(source + '\n' + scene)
source = main.read_text()
marker = '        navigation.viewDidAppear(animated)'
assert source.count(marker) == 1
(args.output_dir/'MainViewController.swift').write_text('import ChannelAdminUI\n' + source.replace(marker, marker + '\n        ChannelAdminUI.codexInstallAdminLogEvidence(context: context)'))
print('Prepared diagnostic-only source copies; the checkout is unchanged.')
