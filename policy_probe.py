from pathlib import Path
import argparse, subprocess, json

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, default=Path('sources'))
parser.add_argument('--output', type=Path, default=Path('results'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)

def balanced(text, marker):
    start = text.index(marker)
    first = text.index('{', start)
    level = 0
    for i in range(first, len(text)):
        level += (text[i] == '{') - (text[i] == '}')
        if level == 0:
            return text[start:i+1]
    raise ValueError(marker)

main = balanced((args.source/'MainViewController.swift').read_text(), 'final class MainController_View:')
ent = balanced((args.source/'EntertainmentSidebarController.swift').read_text(), 'public final class EntertainmentSidebarView:').replace('public ', '')
left = (args.source/'LeftSidebarController.swift').read_text()
policy = left[left.index('    private static var glassCornerRadius'):left.index('    public static let inset')].replace('public ', '').replace('LeftSidebarView.', 'LeftSidebarViewProbe.')
left = 'final class LeftSidebarViewProbe: LiquidGlassView {\n' + policy + '\nrequired init(frame: NSRect) { super.init(frame: frame, cornerRadius: Self.glassCornerRadius) }\nrequired init?(coder: NSCoder) { fatalError() }\n}'
source = Path(__file__).with_name('Probe.swift').read_text().replace('MAIN_SOURCE', main).replace('ENT_SOURCE', ent).replace('LEFT_SOURCE', left)
(args.output/'main.swift').write_text(source)
subprocess.run(['swiftc', '-swift-version', '5', str(args.output/'main.swift'), '-o', str(args.output/'probe')], check=True)
subprocess.run([str(args.output/'probe'), str(args.output)], check=True)
