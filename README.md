# PR 111 — native verification, November 4

## Actual full-client check

macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Telegram 13.1.0 (283357), Debug arm64. Full client with real dependencies and isolated profile/keychain/SDK build overrides; corner behavior corresponds to d4ab9c88. The final integration without diagnostic substitutions built successfully at 3f5baed1.

The included JSON files are observations from actual view instances in the full client. No chat names, messages or account identifiers are recorded. Header crops show only generic controls and the public Pavel Durov channel; personal chat rows are excluded.

| Configuration | Actual resolved radii |
| --- | --- |
| No folders, 1100 × 800 | Chat list 8 |
| Horizontal folders, 1100 × 800 | Chat list 8 |
| Vertical rail, 1190 × 800 | Chat list 8, folder rail 8 |
| No folders / horizontal, compact 560 × 700 | Chat list 0 |
| Vertical rail, compact 560 × 700 | Chat list 16, rail 8, as resolved by native containment |
| Entertainment pane, wide | Chat list and entertainment pane 8; pane background and glass child radii also 8 |

The native container-concentric argument 8 is a minimum radius, not an inset. Actual geometry and native containment determine the effective radius. Header action capsules retain their existing 20-point half-height radius.

Repeated wide/compact transitions restore the correct corner mode. Switching native chrome now runs after the resize/layout callback and preserves the frame; the wide content view returns to 1100 × 800 rather than keeping the 66-point toolbar exclusion. Fullscreen and secondary displays were not checked in this pass.

## Reproduce the actual-client controls

Use a separately configured Debug checkout and an isolated test account with no existing folders. Do not use a personal/production account: the controls temporarily create a Test folder and switch that account’s folder placement. Run `python3 run-native.py --source-root /path/to/telegram-macos -- YOUR_NORMAL_BUILD_COMMAND`. Launch your isolated build with TELEGRAM_VALIDATION_ROOT set. The scene does not configure isolation itself. Use No folders, Horizontal, Vertical, Compact, Wide and Inspect; restore original folder preferences with Restore before quitting. Public reference resolves @durov without joining or sending. Inspect writes geometry JSON in the process temporary directory. The script restores the source file after the build.

## Controlled AppKit probe

`python3 policy_probe.py --source after --output /tmp/corner-policy` compiles extracted production corner policies against real AppKit. View/theme/glass collaborators are controlled stand-ins, so this is not full-client evidence. The local macOS 27 run passed 66/66 assertions across 18 scenarios. The before/after snapshots are pinned in source-pins.json; those corner-policy blocks are unchanged by the native chrome follow-up. Chrome probe sources and outputs separately show frame preservation across four standard/compact transitions.

## Older runtime blocker

No macOS 26-or-earlier client runtime is available locally. GitHub-hosted Mac jobs did not acquire runners: [Intel attempt](https://github.com/PystoyPlayer/telegram-macos/actions/runs/41856404742), [standard-pool retry](https://github.com/PystoyPlayer/telegram-macos/actions/runs/41861029745). Neither is a compatibility pass. The full cross-version review requirement remains outstanding. The remote policy workflow is separately available on codex/pr111-runtime-validation; it does not build the full client.

Evidence and diagnostic substitutions are outside the production PR.
