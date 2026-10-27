# Muted interface sounds

`python3 tools/tests/muted-sounds/run.py` compiles the shipping SoundEffects.swift with recording NSSound/Bundle collaborators and a controlled Core Audio property reader. Thirteen cases cover system mute, master/channel volume, partially audible channels, unavailable controls, missing devices/UIDs and resolving the selected output anew on each call. No real audio plays. The same cases against origin/master (`--baseline`, e1883098) give 2/13 and exit 1, reproducing allocation/playback while muted.

`python3 tools/tests/muted-sounds/run.py --native` uses the real Core Audio reader and recording sound factory. It requires an already muted/zero-volume current output and reports allocation/play counts for ten calls. It never changes the system volume, audio routing or a Bluetooth setting. On the validation Mac it reported a suppressed output, zero allocations and zero play calls.

This changes only the four short ChatUI sound effects, including the message-delivered sound. Call media, notification MediaPlayer playback and user-initiated media are outside this helper.

Environment: macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. The complete integration workspace built successfully, including this helper. No cross-device iPhone/AirPods handoff was exercised; no claim is made that macOS itself cannot switch devices for another application.

There is no visible interface change to photograph. The attached output verifies the relevant difference: the muted path exits before NSSound construction, rather than starting inaudible playback. Test-only collaborators and integration build/profile overrides are not part of production code.
