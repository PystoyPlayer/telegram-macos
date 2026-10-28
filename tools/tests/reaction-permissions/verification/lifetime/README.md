# Reaction handlers after a message row refresh

The reaction guard introduced in #83 captured ChatRowItem weakly. Reaction chip views reuse unchanged layouts across row replacements, so their action can outlive the original row. An already-open picker can also survive a row replacement. Both actions then silently failed their permission check even in an unrestricted chat.

The production permission closure now captures the message and a weak reference to the shared ChatInteraction, reads current peer rights and boost data when invoked, and does not depend on the row lifetime. It does not retain the old row. Revoked permissions still block the action; restored permissions make it usable again.

## Source callback regression

Run `python3 tools/tests/reaction-permissions/run.py` on macOS. The fixture extracts actual production permission, chip, quick-send and ordinary/large/expanded picker callback bodies. Collaborators use controlled send counters; no server requests are issued.

- Before this lifetime fix, source `55783c5a`: **56/63** checks pass. Existing chips and picker actions fail after the row is released. [Output](before-checks.txt).
- Candidate: **63/63** pass, including actual existing-chip callback invocation after row release, normal/large/expanded picker callbacks, live permission changes, boost exemptions, personal bans, protected messages and Saved Messages tags. [Output](after-checks.txt).
- Original merged reaction guard: [output](original-checks.txt).

## Native full-client probe

`PickerLifetimeHarness.swift` is a temporary diagnostic launcher for the full native client. It constructs real TelegramChannel, Message, ChatInteraction and ChatRowItem instances without boost restrictions, constructs the production picker, then releases the row. A temporary `codexReactionPermissionProbe()` method returns the exact `canSendReactions` expression passed by production code to ChatReactionsLayout. The probe and launcher are excluded from shipping code.

The baseline full client passes **4/6** checks: its chip permission closure becomes false after the row is released and remains false when permissions are restored. [Report](before-native-models.json).

The candidate full client passes **6/6** checks, including the same row release and live restriction/restoration sequence. [Report](after-native-models.json). Both complete diagnostic workspace builds succeeded.

The native probe tests picker creation, object lifetime and permission evaluation. It does not click reaction assets or invoke the engine sender; actual callback bodies are tested with controlled counters in the source regression. No messages or reactions are sent and no chat permissions are changed.

Environment: macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. The integration checkout contains other pending UI changes and local build/profile overrides excluded from this PR. Only this macOS version was available.

## Review follow-up

The current runner has 76 checks, including eligibility in all three picker callbacks and the paid picker for unsent, failed, ephemeral, secret, fake and Saved Messages rows. Permission callbacks do not retain the row or ChatInteraction. The lifetime harness now uses only shipping APIs and checks picker/row lifetime; chip permission is covered by the executable source fixture. The boost harness has distinct symbols, installer `codexInstallBoostReactionEvidence`, and writes below `TELEGRAM_BOOST_EVIDENCE` (or the temporary directory). These harness sources are committed diagnostic material under tools, not part of the shipping target. Previous JSON/images are historical component evidence, not a native rerun of this follow-up.
