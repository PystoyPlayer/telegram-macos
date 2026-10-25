# Native permission model verification

Tested on macOS 27.0.1 (26A434), Xcode 27.1 (27A9275), Telegram 13.1.0 (283357), arm64 Debug.

A local validation hook inside the authenticated full client constructed actual TelegramGroup and TelegramChannel peers, Postbox Message objects, ChatInteraction state and production ChatRowItem instances. It evaluated the real canReact getter and TelegramCore permission helper. These 13 checks do not replace those types or the permission helper with fixture collaborators. They make no server writes and do not render a synthetic chat.

Baseline: deffa9c1 production row code, 7/13 pass (`before.json`). Patched: integration at 6bb2e154, 13/13 pass (`after.json`). Local SDK, profile-isolation and validation-hook changes are excluded from the feature PRs.

The six reproduced failures concern group default bans, supergroup default and individual bans, a live restriction while the message retains an older peer snapshot, and restricted-message fallback when the current presentation peer is missing or unrelated. Allowed members and administrator/creator exemptions continue to work.

The separate 21/21 Swift regression checks compile the production getter, existing-chip callback and paid-reaction chooser guard with fixture collaborators. They additionally cover Saved Messages tag filtering, paid-reaction entry points and existing chips after live permission changes. Saved-peer tag updates retain their existing behavior even where the picker itself is disabled. The chip now uses the same live permission peer as the picker. Before this follow-up, four added live-chip checks fail (17/21): a stale message peer can incorrectly allow a newly banned reaction or reject one after permission restoration. The recorded 13 native model checks above cover the unchanged eligibility getter; they predate this callback follow-up.

No suitable restricted live chat was available. These results verify native model-level eligibility and callback guards, not rendered picker behavior or server rejection in a real restricted chat. Before/after UI captures are therefore unavailable; the PR remains a draft with this limitation disclosed.
