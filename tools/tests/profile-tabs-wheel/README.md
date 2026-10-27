# Profile tabs and the mouse wheel

Ordinary vertical mouse-wheel events now move an overflowing profile tab strip horizontally. Horizontal mouse/trackpad movement is retained. Precise vertical trackpad gestures and events over a strip that fits continue to the profile's vertical scroll chain. Scrolling does not select a different tab.

## Checks

`python3 tools/tests/profile-tabs-wheel/run.py` extracts the shipping scroll handler and offset clamp into an executable fixture. **10/10** checks pass; the unmodified e1883098 handler passes **5/10**. The optional argument is a path to a baseline PeerMediaTabsView.swift. Tests cover both directions, horizontal input, precise vertical forwarding, both ends and a fitting strip.

## Native comparison

The native screenshot shows two instances of the real PeerMediaTabsView in a diagnostic window hosted by the full client, using identical neutral tab titles and real layout/glass rendering. The upper instance temporarily uses the old handler; the lower uses the shipping candidate handler. A button directly passes the same non-precise line-wheel NSEvent (delta Y -30) to both instances. No event is posted to macOS.

Before: offset **0**, hidden tabs remain unreachable by that wheel event. After: offset **260**, clamped to the end, revealing Voice Messages, GIFs and Polls. Selection remains Members. This is an internal native input probe, not a claim that the automation tool generated a physical mouse-wheel event: its ordinary scroll action produced a precise gesture instead.

To reproduce, `python3 tools/tests/profile-tabs-wheel/build-native.py --repo /path/to/full-checkout --log /path/to/build.log -- <your normal xcodebuild command>`. It temporarily appends NativeHarness.swift and the baseline handler to the real class, then restores the original source in finally. Run the resulting isolated test app, open a profile and click Apply identical mouse-wheel event. Use a normal configured full checkout; this does not package, sign or launch an app automatically.

macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. Full integration build and a further full build without diagnostic hooks succeeded. No server settings or messages were changed. Production code contains only the wheel handling change; diagnostic UI, account/build overrides and other pending fixes are excluded.
