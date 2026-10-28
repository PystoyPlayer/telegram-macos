# Muted interface sounds

Run `python3 tools/tests/muted-sounds/run.py`: 17 controlled cases compile the shipping helper and beep wrapper with recording NSSound/Bundle and Core Audio readers. The final summary runs after every case. `--baseline` reads immutable e18830989542a063dd66c5bdc4dbe6a70cbbd175 and intentionally fails; review-before.txt and review-after.txt are the current outputs.

Sent/confetti effects read the default output device on each invocation, avoiding NSSound allocation when muted or zero-volume. Incorrect-answer NSSound.beep uses the separate default system sound-effects device (Play sound effects through) for its mute/volume decision. Tests include muted default output with an audible alert device and the inverse, so these routes cannot be conflated. Named quiz enum sounds are not active poll call sites.

Missing device/UID deliberately drops an optional effect. Explicit output-UID binding is not proof of an extra routing fix, since NSSound normally follows the default output already. The supported behavioral fix is avoiding muted audio activation; unmuted AirPods/iPhone handoff is not claimed as fixed or verified.

`--native` uses actual Core Audio reads and recording sound construction for ten sent effects; it never changes volume/routing or emits audio. native-muted-output.txt is historical evidence from a muted validation Mac, not a rerun of the new system-device case. Calls, notifications and user media retain their own paths. No visible screenshot applies. Only macOS 27.0.1 Debug arm64 was available for full-client integration builds.
