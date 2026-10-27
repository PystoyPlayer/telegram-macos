# Native search-flow regression checks

This harness was added after PR #40 was closed for search regressions. The previous header checks used a plain SearchView and an empty result-controller double; they did not establish that the complete chat-search interaction worked.

Run on macOS with Xcode and the pinned SSignalKit checkout:

```sh
python3 tools/tests/chat-search-integration/run.py --scratch-path /private/tmp/telegram-search-build
python3 tools/tests/chat-search-integration/run.py --revision a190a124 --expect-regression --scratch-path /private/tmp/telegram-search-build
```

The patched run checks the real query/input state machine, request delivery, response display, six successive width changes (including 742 pt from the maintainer's example), short windows, input focus/query preservation, result navigation, refocusing, sender filtering, the peer/query request parameters, cancellation and result removal. Search results use the full chat width with 12 pt side insets, independently of the inline field's width. Composer suggestions retain their own anchor width. The popup is also tested above/below its anchor with a requested height larger than available space.

The baseline must reproduce the cramped text viewport and stale/detached result geometry. It reports 57 expected viewport, popup, initial-placement, empty-control, closing-glass and saved-tag-inset failures; any unrelated failure fails the baseline run as well. The current patched run passes 217 checks. The 57-failure baseline count above records the original pass; the newer closing regressions are documented below.

## What runs

The complete production ChatSearchHeader class, CSearchContextState/CSearchInteraction, and ChatSearchView are compiled from source without changing their bodies. The production InputContextView runs against real TGUIKit TableView/rows. Popup layout, attachment, resizing and removal are extracted from InputContextHelper, as is the ChatController inline/fallback decision. Extraction fails when a required source section is missing. No layout calculation is replaced with an expected answer.

The test backend and domain models are controlled: requests return three known messages, sender suggestions contain two known peers, and navigation records the chosen message. The result rows are simple native fixture rows. Chat/account state, localized strings, saved-tag rendering, the calendar factory and Premium flows are test doubles. The saved-tag row's production placement is checked, but its rendering and Premium actions are not. A native lifecycle fixture runs the production slot fields/layout and initial-root-placement block to check creation and pin/search replacement without an unintended frame animation, while retaining resize animation. Empty-search checks exercise the initial arrow state, focus/theme/loading changes, query clearing and sender/tag filters. The real generic SearchView also verifies its explicit clear-visibility contract. A removal fixture uses actual GlassContainerView/LiquidGlassView instances and the production removal block: the glass effect must remain attached while the title expands, disappear afterward, and preserve a rapidly reopened search. No network requests, account data or messages are sent. The fixture does not test server pagination or the calendar screen.

This validates integration of the native search classes with a controlled backend. It does **not** build ChatUI as a whole or Telegram.app, and it does **not** validate search against a Telegram account. Do not use it alone to mark the PR ready for review.

## Native UI smoke check

```sh
python3 tools/tests/chat-search-integration/run.py --scratch-path /private/tmp/telegram-search-build --prepare-app
```

The runner builds `/private/tmp/telegram-search-build/SearchIntegration.app` for UI inspection. Its data is explicitly generic. Type a query, use Previous/Next, choose a sender, then cancel. The footer reports the dispatched request/filter or selected message. It is a test fixture, not a runnable Telegram client. Live resizing is covered by the automated checks; this small inspection window does not host the entire ChatController.

Validated on macOS 27.0.1 / Xcode 27.1. App version/build: N/A, native test executable. The separate complete Debug arm64 Telegram build succeeds after building the pinned native dependencies. See VALIDATION.md for the full-client verification status.

## Saved Messages search input background (2026-10-27)

The current suite passes **217 checks**. The native glass host remains tall enough for the outgoing row and releases that height after closing; reopening cancels a pending shrink. Search content, including the input background, now uses the full 0.2-second exit rather than the earlier 0.12-second fade. The inline merge keeps its existing behavior.

A regression with the old header and corrected host fails the input-background timing check. The fixture includes a real ChatSearchView with a nontransparent background. `search-input-background/` records the passing/current and failing/old-header scopes, native before/after captures and authenticated-client endpoint checks.

The reproducible scene uses actual ChatSearchHeader / ChatSearchView controls, the production removal block and real glass views. Its Unlock label is controlled text, not the Premium renderer. Direct native crops record the input-background transition; verification.json records fresh process IDs, frame times, hashes and limits. The earlier `saved-search-fade/` text-only scene is historical and does not establish the input-background behavior.

Run the usual harness command with `--prepare-app --fade-preview` and open the printed application path. Press **Close after 1.5 seconds** once and use **Quit Preview** before rebuilding. `--revision` selects ChatUI source only; reproducing the old host also requires dependencies checked out before that fix. No preview code is included in the Telegram target.

## Stories reply suggestions (2026-10-27)

The chat-search anchor-height cap now applies only to full-width search results. Ordinary input suggestions retain the caller-supplied height policy. Stories supplies 150 points while its list host initially has a height of 1 point, then expands that host from the size callback; using the host as the initial cap prevents the list from ever growing.

`StorySuggestions.swift` adds 40 checks using the production helper layout/attachment and native views with controlled rows. Hosts initially 0 or 1 point tall expand for one or five mention rows, respect the 150-point request and existing 120-point emoji cap, retain their anchor width/gap, clear and reopen. The previous source fails 28 checks. The corrected suite passes 217 checks, also when combined with the recorded current master. This is a dynamic-container regression test, not an authenticated Stories reply or bot-command-resolution test. See `stories-suggestions/verification.json` and its output summaries.
