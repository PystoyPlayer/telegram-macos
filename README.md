# Recent Actions spoiler-media verification

Production fix: `aa9c27fa` on `codex/recent-actions-media-spoilers`. Only ChannelEventLogController.swift changes in the production patch. This separate branch contains review evidence, not shipping target members.

## Callback and row-state checks

Run `python3 run.py --source /path/to/ChannelEventLogController.swift`. It extracts and compiles the production State, revealMedia callback and all four MessageEntryAdditionalData constructions. Message/context/alert collaborators are controlled Swift models. After: 21/21. At baseline 3fb26e9a: 10/21, including failures for all four row types remaining concealed after the missing callback.

Checks cover state emission, other-message/peer isolation, deletion-group expansion, repeated reveal, fresh-controller reset, confirmation/cancellation, enabled sensitive content and the age-verification gate. This does not exercise a live server admin log.

## Native captures

Same window, generated local checkerboard photo, one activation in each mode. The native scene uses actual ChatMediaItem / ChatMediaView / ChatInteractiveContentView and a log-mode ChatInteraction in the full client. The button calls the production content node's open() method. Before uses the previous no-op reveal behavior. Fixed installs the extracted production callback, then rebuilds the row with the updated reveal flag.

The scene uses a local synthetic message, not a real deletion event. It does not invoke the full ChannelEventLogController engine subscription or exercise a physical mouse hit on an admin-log photo. Those limits are explicit; this is native renderer/callback evidence, not a live-account deletion test.

The bitmap is generated in NativeScene.swift. No private photos, account information, chats, downloads or server events appear in the captures. Both 1240x1284 PNGs were captured through native UI automation and visually inspected without editing.

To inspect/reproduce the native scene, run `python3 prepare-native-scene.py --source-root /path/to/fixed/checkout --output-dir /path/to/temporary/output`. This emits diagnostic-only copies of the controller and MainViewController, without modifying the checkout. In a disposable, working full-client build, substitute these two files temporarily and launch with an isolated profile using TELEGRAM_VALIDATION_ROOT. Revert the substitutions before building the shipping client. A functioning AccountContext is needed for its local MediaBox; no test messages are sent. The build used macOS 27.0.1, Xcode 27.2, Telegram 13.1.0 Debug arm64, with real native dependencies and local SDK/profile overrides.
