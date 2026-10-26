# Native window and pane corners

Continuation of TelegramMessenger/telegram-macos#80. The original proposal removes the private NSWindow radius override; the follow-up also updates the chat-list and vertical folder panels to the native container-concentric corner configuration on macOS 27, with an 8-point minimum. The traditional panel radii remain 20 points on macOS 26 and 8 on earlier systems. New SDK types are excluded on compilers older than Swift 6.4.

The standard window retains the existing native toolbar on macOS 26 and later. AppKit uses that toolbar to position both the traffic-light controls and its window-sharing indicator. Removing it moved the indicator toward the top-left corner, so the earlier draft toolbar change has been reverted. No private outer-radius replacement or manual sharing-indicator offset is introduced.

## Actual native captures

Both complete arm64 Debug comparison clients build and run with actual dependencies. System: macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), Telegram 13.1.0 (283357).

`before.png` and `after.png` are direct 610x196 crops from the wide no-folders scenario, with an identical 1100x800-point window frame (2200x1600 physical pixels). There is no compositing, resizing or reconstruction. The native sharing indicator is left visible. The private chat list and messages are outside the crop.

The additional twelve crops record no folders, horizontal folder tabs, and a vertical folder rail in wide and compact windows. The final pass requests explicit outer frames; the original baseline pass requested content sizes. Accepted native frame sizes are recorded separately: some outer heights differ because native chrome/titlebar behavior changes. These extra states are verification evidence, not a claim that their outer frames all match.

A temporary setup helper operates only on the isolated test account. It creates a single Test folder using the existing engine API, toggles the existing sidebar preference, requests 1100x800 or 560x700 outer frames in the final pass, twice to settle the AppKit chrome transition, and observes actual MainController_View / LeftSidebarView effective corner radii and standard window-button frames. The matrix proves settled endpoints; physical live-resize dragging was unavailable through the computer-use API, so no animation-quality claim is made. It does not substitute the production window, panel views or corner calculation. The final native observations show 8-point pane corners on macOS 27. The original folder preferences are restored. Diagnostic, SDK-compatibility and isolated-storage changes are excluded from the feature.

`validation.json` records exact crop coordinates, accepted frames, production source hashes, method and limitations. `corner-observations.json` records the final six native observations. The baseline window-corner code is the original private override; the candidate source is recorded in the validation JSON.

## Compatibility and testing limits

The macOS 27.0.1 build and six folder/window scenarios are complete. The continuation is submitted for review with the limitations below.

The original review asks for results on multiple macOS versions. Only macOS 27.0.1 is available; no macOS 26/older runtime result is claimed. Source inspection confirms that the removed `applyCornerRadius(for:)` body was already guarded by `#available(macOS 27.0, *)`, so its removal does not change older-system execution. The new pane APIs are guarded by macOS 27 availability and Swift 6.4 compiler checks; the existing macOS 26 and earlier static radii and native toolbar are preserved. This compatibility inspection does not replace the requested additional runtime evidence.

Fullscreen, secondary displays, older compilers and appearance outside a window-capture session are also not established by this pass.

## Sharing-indicator regression

`sharing-indicator-before.png` shows the earlier draft without a native toolbar; `sharing-indicator-after.png` shows the corrected native toolbar route. Both are direct 610x196 crops from the same 1512x886-point test window on macOS 27.0.1. The actual purple indicator moves from (6,6) to (16,16) points relative to the window, matching the native toolbar control area. These are the real macOS indicators visible during computer-use window capture; they are not drawn by the test app. No additional capture helper, custom indicator, or UI replacement is included in the client.
