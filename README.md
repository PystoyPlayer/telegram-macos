# Recent Actions navigation search — native comparison

The two header captures use the actual ChannelEventLogController inside a full Debug arm64 Telegram client. Only its event-log source is replaced with an empty, loaded controlled source; the generic peer is Example Channel. No personal chat data or live admin-log requests are used.

- Before: upstream controller at 6540581e, with a second search row and duplicate search/close controls.
- After: feature e988f480, with Back, search field and one close button in the title row.
- macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Telegram 13.1.0 (283357), identical 920 × 600 point windows.
- Both diagnostic full-client builds completed with BUILD SUCCEEDED. Local SDK/profile build overrides are present; this is integration coverage.

## Verified interactions

Cmd-F and the search button open the field, hide title/status and change the right icon to Cancel. An empty query has no Clear button. Typing reaches setFilter; Clear empties without closing. Escape, Cancel and repeated Cmd-F restore the title and reset the query. Back while searching completes the navigation pop. queries.json is the observed query callback record. Server filtering and older macOS runtimes were not exercised by this scene.

## Reproduce

Use a separately configured Debug checkout and an isolated test account/profile. Run `python3 run-native.py --source-root /path/to/telegram-macos --variant before -- YOUR_NORMAL_BUILD_COMMAND`, then launch that build with TELEGRAM_VALIDATION_ROOT set to enable the diagnostic scene. The scene does not implement profile isolation; retain the isolation configuration used by your own test build. Repeat with `--variant after`. The script restores the two temporarily substituted source files even if the build fails. The diagnostic window is named “Recent Actions header — neutral controller fixture”; select it from Window if the main window is active. Query callbacks are written to the process temporary directory as TelegramEventLogHeaderQueries.json.

The evidence and test substitutions are on this separate branch; none are in the production patch.
