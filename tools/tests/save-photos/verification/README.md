# Native integration verification

Tested on macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), Telegram 13.1.0 (283357), arm64 Debug.

The patched client integrated the production changes from PRs #83, #84 and #85 at `6bb2e154`. Local SDK, isolated-profile and validation-hook changes are excluded from the feature PRs. The baseline used `deffa9c1` versions of ChatRowItem, ChatReactionsView and ChatMessageMenuItems.

## Method

Two harmless 640x480 JPEG photos were uploaded as one album to the test account's Saved Messages. A local validation hook requested the loaded album row's production `menuItems(in: .zero)`, recorded the generated titles and invoked the matching ContextMenuItem handler. The native folder picker was completed through the UI. The selected-photos case first selected both real message IDs through ChatInteraction.

This exercises production menu generation, actual Postbox messages, MediaBox resources, folder selection and filesystem writes. It bypasses physical right-click dispatch: the computer-use tool returned AXError.failure for coordinate clicks on the drawn message. No screenshot was taken for this verification at the contributor's request.

## Results

- Baseline: two-photo album; Save As exists, Save All Photos is absent (`before-menu.json`).
- Patched album: Save All Photos exists even at an individual tile point (`after-album-menu.json`). One folder picker; native UI reported Saved; two distinct, decodable 640x480 JPEG files were written (`saved-album.json`).
- Patched selection: Save Selected Photos exists with two messages selected (`after-selection-menu.json`). Saving to the same directory created two files suffixed (1). The original files retained their SHA-256 hashes, and each new copy matched its corresponding original (`saved-selection.json`).
- Targeted Swift checks: 35/35 pass, including delayed remote resources, cancellation, failed downloads, protections, ordering, duplicates and filename collisions. The individual-album-tile regression failed before the follow-up fix (34/35).

The native photos were local by the time saving ran. Delayed downloads and their failures are covered by the targeted production-saver tests with resource collaborators, not by a forced network failure in this native run.
