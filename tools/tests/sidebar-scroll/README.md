# Application scrollbar regression

`TGUIKit.ScrollView` now installs the shared native overlay scroller whenever vertical scrolling is enabled. TableView-based screens inherit it, including chats, search, settings, forms, contacts, calls, media lists and pickers. The rich-text draft preview and video-tool panel opt in through the same NSScrollView helper. Intentionally hidden scrollbars stay hidden; horizontal-only scroll views are unchanged. Self-contained editor components, web content and system dialogs retain their own scrolling implementation.

The thumb paints a rounded 3 pt line (5 pt while expanded/tracking or with increased contrast), colored from the current palette's `grayText`. Native hit geometry, dragging and auto-hide remain AppKit's responsibility. Theme updates invalidate the TableView scroller. Configuration is idempotent and preserves an existing themed instance.

## Inset audit

| Screen | Result |
| --- | --- |
| Chat list and sidebar search | Removed duplicate footer scroller inset; retained content clearance and separate header inset. |
| Account settings and recent calls | Removed the same duplicated footer inset. |
| InputData forms/settings subpages | Retained composed content padding; removed its duplicate from scroller insets. |
| Contacts | Already uses zero additional bottom scroller inset; unchanged. |
| Chat history | Preserved the top content inset and separate bottom scroller exclusion for the input panel. |
| Emoji, sticker and GIF pickers | Preserved their 46 pt top / 50 pt bottom scroller insets: these reserve overlay controls and do not duplicate contentInsets. |

AppKit combines contentInsets and scrollerInsets while tiling its native scroller. Applying the same footer height twice makes the thumb stop one footer height above the usable list's lower boundary, even at native progress 1.

## Run

```sh
python3 tools/tests/sidebar-scroll/run.py --scratch-path /tmp/telegram-scrollbars
```

Initialize dependencies first. A full checkout can supply dependencies through `--dependency-root /path/to/telegram-macos`. Reuse the scratch path. The runner snapshots affected TGUIKit sources from the selected revision without changing the dependency checkout; other dependencies come from that checkout.

```sh
python3 tools/tests/sidebar-scroll/run.py --revision e537320b28d79cecc1baf716bcbf822b02f93b7a --scratch-path /tmp/telegram-scrollbars
```

The baseline intentionally exits nonzero. The suite extracts real inset assignments from Chats, Search, Settings, Calls, InputData and ChatController. Controlled native TableView rows avoid a network/account dependency. It covers short/long lists, 400/800 pt heights, 0/56/80 pt footer heights, chat header insets, zero-size initialization followed by layout, native progress/endpoints/hit testing, and the unflipped chat-history input-panel exclusion. AppKit's 1 pt knob end padding is retained. Candidate-only checks cover common ScrollView installation, repeat configuration, hide/re-enable, horizontal-only views and the plain NSScrollView opt-in.

See [regression output](evidence/regression.txt).

## Native comparison

Add `--prepare-app` to build `SidebarScrollValidation.app` in the scratch path. Quit it before building another revision. Buttons select top/bottom endpoints and dark/light palettes.

The numbered-row images are native captures using production TGUIKit and a 72 pt footer overlay, **not screenshots of authenticated Telegram content**. Both revisions use identical 420×680 pt window geometry and native scroll progress 1. Captures are cropped to the rows/footer without changing pixels inside the crop.

| Palette | Before | After |
| --- | --- | --- |
| Dark | ![Before: duplicated lower gap](evidence/before-dark.png) | ![After: slimmer thumb reaches footer](evidence/after-dark.png) |
| Light | ![Before in light palette](evidence/before-light.png) | ![After in light palette](evidence/after-light.png) |

The actual Telegram settings sidebar was also captured at native progress 1, with the same window and content position. The account profile is outside both crops.

| Actual client | Before | After |
| --- | --- | --- |
| Settings sidebar | ![Settings before](evidence/client-before-settings.png) | ![Settings after](evidence/client-after-settings.png) |

[General Settings before](evidence/client-before-general.png) · [General Settings after](evidence/client-after-general.png)

The native fixture also verified an actual mouse drag from bottom to top (native value 1 → 0), theme changes and the top endpoint.

## Full client validation

See the [build and runtime record](evidence/native-build.txt). Only the available macOS version and a Debug integration build were tested. Other macOS versions, a distribution build and the system increased-contrast preference were not exercised. Private account captures remain local; public evidence excludes the account profile and chat sidebar.
