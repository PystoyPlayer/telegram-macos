# Boost exemptions for reaction permissions

Regression introduced by #83: `canSendReactionsToPeer` was called with the default `ignoreDefault: false`, including for members who have already boosted enough to bypass default group restrictions. The iOS `canSendReactionsToChat` explicitly passes that exemption.

The row now computes reaction permission from the matching current peer and CachedChannelData. Only a positive boost threshold reached by the applied boost count ignores defaults. TelegramCore still checks personal bans. The same live permission closure is shared by existing reaction chips, while full picker/message eligibility and Saved Messages tag handling remain distinct.

## Swift regression

The initial boost regression passed **53/53** checks; the preceding reaction source (`e1883098`) passed **44/53**. All nine new failures concerned boosted members' eligibility, quick/paid reactions, open picker callbacks and existing chips. The expanded current suite passes **63/63** and also covers row replacement; see [lifetime verification](../lifetime/README.md). Run `python3 tools/tests/reaction-permissions/run.py` on macOS. Additional cases preserve personal bans, missing/zero thresholds, insufficient boosts, unrelated peer caches, revoked/restored rights, protected messages and Saved Messages tags.

These tests extract the actual production getter, permission helper, existing-chip callback, quick-send method and ordinary/large/expanded picker callbacks, using fixture collaborators for controlled send counters. The current row view calls `reactAction` for the configurable Force Touch reaction action; its double-click handler replies. No gesture setting is changed, and no physical double-click-to-react result is claimed.

## Full native comparison

macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. The complete workspace builds pass with real dependencies. The integration checkout includes other pending UI PRs and local SDK/profile/keychain build overrides; they are excluded from this patch.

A temporary hook in ChatController.viewDidAppear installed the diagnostic launcher from `RenderedBoostHarness.swift`. The harness constructs **actual TelegramChannel, CachedChannelData, Postbox Message and production ChatRowItem** instances. It hosts the production picker returned by menuAdditionView; it does not recreate the picker UI. The app's real authenticated account supplies available reaction assets. No reactions/messages were sent, chats joined or server rights changed.

- Baseline: integration `2e2e0fb8`, original #83 permission paths; **6/9 native model checks pass**. Sufficient/excess/restored boosts incorrectly remain blocked. [Models](before-models.json), [picker observation](before-observations.json), [image](before.png).
- Candidate: integration `cd7a8c09`, **9/9 native model checks pass**. With 2/2 boosts the real picker appears; removing boosts or applying a personal ban prevents it; restoring boosts makes it available again. [Models](after-models.json), [observations](after-observations.json), [image](after.png).
- A further complete build without the diagnostic hook succeeded, and the isolated test app was repackaged from that clean build.

The matching 820×560 pt native windows are explicitly labeled as controlled models. This is rendered production-component verification, not a physical context-menu/gesture test against a live boosted/restricted server group. Only this macOS version and Debug configuration were available. The user's exact live group rights were not read. Temporary hooks and launcher buttons are not part of the shipped code.
