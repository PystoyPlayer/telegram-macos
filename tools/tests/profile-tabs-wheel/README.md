# Profile tabs use the folder scroller

PeerMediaTabsView now hosts its content in the same TGUIKit HorizontalScrollView that ScrollableSegmentView uses for chat folders. It delegates complete wheel events, including precise vertical input, instead of maintaining its own axis filter, multiplier and content-origin offset. Existing glass, tab selection and focus-selected behavior remain. A fitting strip forwards to the parent without re-entering the embedded scroller.

## Checks

`python3 tools/tests/profile-tabs-wheel/run.py` compiles the shipping event handler with a recording scroll collaborator. **8/8** checks pass; the original e1883098 handler passes **1/8**. Cases check ordinary and precise input, immediate reversed input, horizontal/diagonal input, zero end events, ordering and fitting-strip forwarding. The fixture also verifies that the folder and profile components instantiate the same scroll class. This checks delegation; it does not substitute mocked scrolling physics for native behavior.

## Native comparison

The screenshot shows the prior custom handler and final candidate in an isolated native window inside the full client. Both use real tab views, identical neutral labels and real layout/glass rendering. The prior custom version is retained as a separately named class at build time; it is not included in shipping code.

The internal native probe passed immediate reversal at both bounds, preservation after layout and retention of the selected tab. The CUA scroll action now also moves the candidate: it reached offset 260, and a back-to-back reverse action returned to 226 in the same 0.615-second tool call, including observation. The previous handler stayed at zero for precise vertical input. These observed states are recorded in verification/native-reversal.txt.

`python3 tools/tests/profile-tabs-wheel/build-native.py --repo /path/to/full-checkout --log /path/to/build.log -- <your normal xcodebuild command>` temporarily instruments the class and appends NativeHarness.swift, then restores the original source in finally. The default baseline is the first attempted fix, 05b79f3a; supply --baseline for a different locally available ref. Open a profile in the resulting isolated app to display the comparison. The button directly calls the view handlers with native precise events; no event is posted to macOS. Ordinary CUA scrolling can also be used over either strip.

Environment: macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. The complete workspace built with the probe and again without diagnostic hooks (integration 43cf267b). No messages/server settings were changed. Another macOS version and a physical mouse were unavailable; ordinary mouse input is covered by the delegated-event fixture, while CUA and the native probe exercised precise scrolling. Production changes exclude diagnostic UI, account/build overrides and other pending fixes.
