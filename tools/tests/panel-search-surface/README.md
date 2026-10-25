# Picker search loading surface

Run on macOS with Xcode and initialized dependencies:

```sh
python3 tools/tests/panel-search-surface/run.py --scratch-path /private/tmp/panel-search-build
python3 tools/tests/panel-search-surface/run.py --revision ab4e31a4 --expect-regression --scratch-path /private/tmp/panel-search-build
```

`--dependencies-root` can point to another initialized checkout when using a sparse worktree.

The full production `PanelSearchStatusView` and presentation model run with native TGUIKit views. The production update method keeps its actual background/color/accessibility arguments; its empty-state Lottie factory is replaced with `nil`. The three picker status-frame assignments are extracted unchanged and run with real `TableView.contentInsets` for standalone and embedded modes, two palettes, resizing, short heights, Reduce Motion, status changes and removal from the window.

These checks cover the loading surface and geometry. They do not launch Telegram, perform a network search or validate the empty-state duck animation.
