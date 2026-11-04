# Recent Actions compact header and inline search

The captures use the actual ChannelEventLogController inside a full native Debug arm64 client, a generic Example Channel peer and a controlled empty event-log source. No personal chat data or live admin-log requests are used.

- Before: upstream 6540581e, second search row and duplicate controls.
- After: compact channel avatar/title/status remain visible beside search; title pill has the same width open and closed. Source a08f845e, merged with upstream 3a82ed7d at 8a9819f5.
- macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Telegram 13.1.0 (283357), Debug arm64. 920 × 600 point before/after windows; extra compact capture at 400 points.

The native pass verified open/close by keyboard and button, query callbacks, Clear without closing, restored title/context, repeated toggles, and both window widths. Both text lines fit; narrow widths truncate text without overlapping the input or buttons. Motion shares the existing chat field duration 0.22 seconds and easeOut; native GlassContainerView owns the title/search surfaces. Reduce Motion has immediate geometry and a short fade (system preference not toggled in this pass). The generation guard against stale close completions was added after the native pass and is included in the final shipping build. Screenshots document endpoints, not a video of intermediate frames. Live server result filtering and older macOS runtimes were not exercised by this scene.

## Reproduce

Use a separately configured Debug checkout with an isolated test account/profile. Run `python3 run-native.py --source-root /path/to/telegram-macos --variant before -- YOUR_NORMAL_BUILD_COMMAND`, then launch your isolated build with TELEGRAM_VALIDATION_ROOT set to enable the diagnostic window. Repeat with `--variant after`. The scene does not configure profile isolation itself: retain your own isolated build/profile setup. The script restores both source files after the build, including on failure. Select “Recent Actions header — neutral controller fixture” from Window. Use Wide fixture and Compact fixture for the two widths. Query callbacks are written to the process temporary directory as TelegramEventLogHeaderQueries.json.

The evidence and substitutions are on this separate branch and are not part of the production patch.
