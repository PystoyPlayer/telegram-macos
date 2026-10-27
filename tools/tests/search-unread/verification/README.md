# Read/unread actions in search

macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64.

The search action reads a fresh PeerReadCounters snapshot, including manual markedUnread, when each context menu is requested. It reuses the same localized strings, menu animations and ChatListRowItem.markAsRead/markAsUnread send paths as the ordinary chat list. Pin/folder/remove menu items remain intact.

A ChatListGroup snapshot prevents offering an ineffective action for public search results that are not in the account's chat list. Archived chats remain eligible. Secret results pass their actual secret-chat ID, rather than the visible user's cloud peer ID, so the unsupported action is omitted without affecting the normal cloud conversation with that person. The engine's whole-forum unread API clears topic read states even with setToValue=true; read forums/monoforums therefore do not offer Mark as Unread, while unread forums retain Mark as Read.

The source fixture extracts the actual production helper and top-peer menu body with controlled engine snapshots and action spies. It checks title/icon state, actual target ID and explicit true/false handlers, manual unread flags, archives, non-chat global results, missing peers, secret chats, forums, Saved Messages and preservation of top-peer removal. 30/30 pass; 8/30 pass before.

## Native state verification

The diagnostic window constructs the actual production result-menu and PopularPeerItem menu factories for the test account's Saved Messages. It verifies the offered action in both menus, invokes the real production result-menu handler, checks the actual engine unread flag, then repeats for the inverse action. Saved Messages had no unread incoming messages; the original manual flag was restored. No messages were sent or other chats changed.

Before, **1/6** checks pass. After, **6/6** pass. [Before state report](before-native-models.json), [after state report](after-native-models.json). [Before verification window](before-checks-window.png), [after verification window](after-checks-window.png).

## Visual menu comparison

The exact production ContextMenuItems are attached to a native AppKit popup in the isolated diagnostic window. This displays the real menu item objects and their labels rather than reproducing the menu in a mockup. It does not verify the custom menu renderer's glass appearance. No sidebar, account avatar, private chat list or message contents are included in published captures.

Reproduce the full-client comparison with `python3 tools/tests/search-unread/build-native.py --source-root /path/to/full/checkout --derived-data /path/to/derived-data`; add `--baseline <revision>` for old search/popular menu factories. Open the resulting client, click Search unread validation, then Show result menu or Show top-peer menu. Open the Production search actions popup. Check unread toggle invokes actual Saved Messages handlers only when no unread incoming messages are present. The report is written to NSTemporaryDirectory()/search-unread.json. Build prerequisites/account setup are the normal app requirements. The builder restores the source files in finally and removes the temporary helper; launchers and diagnostic visibility changes are not shipped.

Boundaries: the source tests use controlled engine snapshots and action spies; the native state test uses the real test account/engine. The native fixture calls menu factories and handlers directly rather than physically right-clicking each actual search row. Only this macOS version and Debug configuration were available. The integration checkout contains other pending changes and local SDK/profile overrides excluded from this PR.
