# Native window and pane corners

Continuation of TelegramMessenger/telegram-macos#80. The original proposal removes the private NSWindow radius override; the follow-up also updates the chat-list and vertical folder panels to the native container-concentric corner configuration on macOS 27, with an 8-point minimum. The traditional panel radii remain 20 points on macOS 26 and 8 on earlier systems. New SDK types are excluded on compilers older than Swift 6.4.

The macOS 27 standard window no longer installs the older empty toolbar. In the first native comparison, compact-to-wide changes could leave unused toolbar space; the final comparison removes that obsolete toolbar. macOS 26 keeps its existing toolbar route. No private outer-radius replacement is introduced.

## Actual native captures

Both complete arm64 Debug comparison clients build and run with actual dependencies. System: macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), Telegram 13.1.0 (283357).

`before.png` and `after.png` are direct 610x196 crops from the same wide vertical-folder scenario, with an identical 1190x832-point window frame (2380x1664 physical pixels). There is no compositing, resizing or reconstruction. The native sharing indicator is left visible. The private chat list and messages are outside the crop.

The additional twelve crops record no folders, horizontal folder tabs, and a vertical folder rail at wide and narrow content-size requests. Accepted native frame sizes are recorded separately: some outer heights differ because native chrome/titlebar behavior changes. These extra states are verification evidence, not a claim that their outer frames all match.

A temporary setup helper operates only on the isolated test account. It creates a single Test folder using the existing engine API, toggles the existing sidebar preference, requests 1100x800 or 560x700 content sizes, and observes actual MainController_View / LeftSidebarView effective corner radii. It does not substitute the production window, panel views or corner calculation. The final native observations show 8-point pane corners on macOS 27. The original folder preferences are restored. Diagnostic, SDK-compatibility and isolated-storage changes are excluded from the feature.

`validation.json` records exact crop coordinates, accepted frames, production source hashes, method and limitations. `corner-observations.json` records the final six native observations. The baseline window-corner code is the original private override; the candidate source is recorded in the validation JSON.

## Remaining review gate

The original review explicitly requests multiple macOS versions. Only macOS 27.0.1 is available and the user has no second Mac. No macOS 26/older runtime test is claimed. Those paths are preserved by availability/compiler guards, but source inspection does not replace that requested runtime evidence. The continuation remains a draft until another macOS version is checked. Fullscreen, secondary displays and appearance outside a window-capture session are also not established by this pass.
