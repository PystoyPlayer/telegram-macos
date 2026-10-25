import argparse
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
fixtures = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--dependencies-root', type=Path, default=root)
parser.add_argument('--scratch-path', type=Path, required=True)
parser.add_argument('--revision')
parser.add_argument('--expect-regression', action='store_true')
args = parser.parse_args()


def source(name):
    path = 'packages/EntertainmentUI/Sources/EntertainmentUI/' + name + '.swift'
    if args.revision:
        return subprocess.check_output(['git', 'show', args.revision + ':' + path], cwd=root, text=True)
    return (root / path).read_text()


with tempfile.TemporaryDirectory(prefix='telegram-panel-search-') as directory:
    directory = Path(directory)
    sources = directory / 'Sources'
    sources.mkdir()
    dependencies_root = args.dependencies_root.resolve()
    dependencies = ', '.join('.package(path: ' + json.dumps(str(dependencies_root / 'packages' / name)) + ')' for name in ['TGUIKit', 'ColorPalette'])
    (directory / 'Package.swift').write_text('''// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "PanelSearchChecks", platforms: [.macOS(.v12)], dependencies: [DEPENDENCIES], targets: [.executableTarget(name: "PanelSearchChecks", dependencies: ["TGUIKit", "ColorPalette"], path: "Sources")])
'''.replace('DEPENDENCIES', dependencies))
    (sources / 'Presentation.swift').write_text(source('PanelSearchPresentation'))
    view = source('PanelSearchStatusView')
    view += '''
extension PanelSearchStatusView {
    var testShimmer: CAGradientLayer { shimmer }
    var testMask: CAShapeLayer { shimmerMask }
}
'''
    (sources / 'StatusView.swift').write_text(view)
    animation = source('PanelSearchStatusAnimation')
    animation = animation[animation.index('extension PanelSearchStatusView'):]
    animation = animation[:animation.index('makeAnimation: {')] + 'makeAnimation: { nil })\n    }\n}\n'
    (sources / 'StatusUpdate.swift').write_text('import AppKit\nimport TGUIKit\n' + animation)
    layouts = []
    for name, file in [('emoji', 'EmojiesController'), ('stickers', 'StickersViewController'), ('gifs', 'GifKeyboardController')]:
        line = next(line.strip() for line in source(file).splitlines() if 'transition.updateFrame(view: searchStatusView, frame:' in line)
        layouts.append('func layout_' + name + '(size: NSSize, searchContainer: NSView, tableView: TableView, searchStatusView: PanelSearchStatusView, transition: ContainedViewLayoutTransition) {\n' + line + '\n}')
    (sources / 'Layouts.swift').write_text('import AppKit\nimport TGUIKit\n' + '\n'.join(layouts))
    images = {}
    for name in ['Icon_SearchField', 'Icon_SearchClear', 'Icon_Quote', 'Icon_Quote_Collapse', 'Icon_Quote_Expand']:
        image_set = dependencies_root / 'Telegram-Mac/Assets.xcassets' / (name + '.imageset')
        variants = json.loads((image_set / 'Contents.json').read_text())['images']
        filename = next(image['filename'] for image in variants if image.get('filename') and image.get('scale') == '1x')
        images[name] = str(image_set / filename)
    (sources / 'Assets.swift').write_text('let imagePaths: [String: String] = [' + ', '.join(json.dumps(name) + ': ' + json.dumps(path) for name, path in images.items()) + ']')
    (sources / 'main.swift').write_text((fixtures / 'main.swift').read_text())
    command = ['swift', 'run', '--package-path', str(directory), '--scratch-path', str(args.scratch_path.resolve()), '--disable-sandbox', '--jobs', '4', 'PanelSearchChecks']
    if args.expect_regression:
        command.append('--expect-regression')
    raise SystemExit(subprocess.run(command).returncode)
