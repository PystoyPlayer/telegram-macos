# Muted interface sounds

`python3 tools/tests/muted-sounds/run.py` compiles the shipping SoundEffects.swift with recording NSSound/Bundle collaborators and a controlled Core Audio property reader. Thirteen cases cover system mute, master/channel volume, partially audible channels, unavailable controls, missing devices/UIDs and resolving the selected output anew on each call. No real audio plays. The same cases against immutable e18830989542a063dd66c5bdc4dbe6a70cbbd175 (`--baseline`) give 2/13 and exit 1, reproducing allocation/playback while muted.

`python3 tools/tests/muted-sounds/run.py --native` uses the real Core Audio reader and recording sound factory. It requires an already muted/zero-volume current output and reports allocation/play counts for ten calls. It never changes the system volume, audio routing or a Bluetooth setting. On the validation Mac it reported a suppressed output, zero allocations and zero play calls.

This changes the shared ChatUI sound-effect helper (currently used by sent and confetti actions) and now also gates the incorrect-quiz-answer system beep. The enum contains quiz sound names, but the poll UI does not invoke those named files. Call media, notification MediaPlayer playback and user-initiated media are outside this helper.

Environment: macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. The complete integration workspace built successfully, including this helper. No cross-device iPhone/AirPods handoff was exercised; no claim is made that macOS itself cannot switch devices for another application.

There is no visible interface change to photograph. The attached output verifies the relevant difference: the muted path exits before NSSound construction, instead of starting inaudible playback. Test-only collaborators and integration build/profile overrides are not part of production code.

Review follow-up: 15 controlled checks include the actual incorrect-answer beep wrapper. Failure to read a default device or UID deliberately drops this optional UI sound. Binding playbackDeviceIdentifier to the default UID is explicit routing, not proof of an additional AirPods fix: NSSound normally uses the default output already. The supported behavioral fix is avoiding audio activation when the selected output is muted or zero-volume. Unmuted iPhone/AirPods switching has not been reproduced or fixed by this change.
