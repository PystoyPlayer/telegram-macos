import argparse
import json
import plistlib
import shutil
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--dependency-root', type=Path, default=root)
parser.add_argument('--scratch-path', type=Path, required=True)
parser.add_argument('--revision')
parser.add_argument('--prepare-app', action='store_true')
args = parser.parse_args()
deps = args.dependency_root.resolve()
fixtures = Path(__file__).resolve().parent

def source(path):
    return subprocess.check_output(['git', 'show', args.revision + ':' + path], cwd=root, text=True) if args.revision else (root / path).read_text()

peers = source('packages/ChatListUI/Sources/ChatListUI/PeersListController.swift')
search = source('packages/ChatListUI/Sources/ChatListUI/SearchController.swift')
chat_insets = next(line.strip() for line in peers.splitlines() if 'tableView.scrollerInsets = .init(' in line)
search_insets = '\n'.join(line.strip() for line in search.splitlines() if 'genericView.contentInsets.bottom = ' in line or 'genericView.scrollerInsets.bottom = ' in line)
assert chat_insets and search_insets
try:
    sidebar = source('packages/ChatListUI/Sources/ChatListUI/SidebarTableView.swift')
except (subprocess.CalledProcessError, FileNotFoundError):
    sidebar = 'import TGUIKit\ntypealias SidebarTableView = TableView\n'
with tempfile.TemporaryDirectory(prefix='telegram-sidebar-scroll-') as tmp:
    tmp = Path(tmp)
    sources = tmp / 'Sources'
    sources.mkdir()
    dependencies = ', '.join('.package(path: ' + json.dumps(str(deps / 'packages' / name)) + ')' for name in ['TGUIKit', 'ColorPalette'])
    (tmp / 'Package.swift').write_text('''// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "SidebarScrollValidation", platforms: [.macOS(.v12)], dependencies: [DEPENDENCIES], targets: [.executableTarget(name: "SidebarScrollValidation", dependencies: ["TGUIKit", "ColorPalette"], path: "Sources")])
'''.replace('DEPENDENCIES', dependencies))
    (sources / 'SidebarTableView.swift').write_text(sidebar)
    main = (fixtures / 'main.swift').read_text().replace('__CHAT_INSETS__', chat_insets).replace('__SEARCH_INSETS__', search_insets)
    (sources / 'main.swift').write_text(main)
    images = {}
    for name in ['Icon_SearchField', 'Icon_SearchClear', 'Icon_Quote', 'Icon_Quote_Collapse', 'Icon_Quote_Expand']:
        folder = deps / 'Telegram-Mac/Assets.xcassets' / (name + '.imageset')
        variants = json.loads((folder / 'Contents.json').read_text())['images']
        filename = next(v['filename'] for v in variants if v.get('filename') and v.get('scale') == '1x')
        images[name] = str(folder / filename)
    (sources / 'Assets.swift').write_text('let imagePaths: [String: String] = [' + ', '.join(json.dumps(n) + ': ' + json.dumps(p) for n, p in images.items()) + ']')
    options = ['--package-path', str(tmp), '--scratch-path', str(args.scratch_path.resolve()), '--disable-sandbox', '--jobs', '2']
    if args.prepare_app:
        subprocess.run(['swift', 'build'] + options + ['--product', 'SidebarScrollValidation'], check=True)
        binary = subprocess.check_output(['swift', 'build'] + options + ['--show-bin-path'], text=True).strip()
        app = args.scratch_path.resolve() / 'SidebarScrollValidation.app'
        (app / 'Contents/MacOS').mkdir(parents=True, exist_ok=True)
        shutil.copy2(Path(binary) / 'SidebarScrollValidation', app / 'Contents/MacOS/SidebarScrollValidation')
        (app / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'local.codex.telegram.SidebarScrollValidation', 'CFBundleExecutable': 'SidebarScrollValidation', 'CFBundleName': 'Sidebar Scroll Validation', 'CFBundlePackageType': 'APPL', 'CFBundleVersion': '1'}))
        print(app)
    else:
        raise SystemExit(subprocess.run(['swift', 'run'] + options + ['SidebarScrollValidation']).returncode)
