# PR #76 review validation — 2026-10-25

Status: merged upstream `df90450c`, resolved the search conflict in `8e01deed`, and rebuilt the complete client at validation integration `712be74a`. Authenticated search was rechecked after the merge. Current Before/After captures show the same public channel, query and upstream result counter.

## Completed checks

- The baseline PR head `a190a124` reproduces 57 expected failures in the native search-flow harness: cramped input, stale or narrow result geometry, initial-placement animation, empty search controls, premature glass removal and saved-tag margins. Unrelated failures fail the baseline run.
- The patched source passes 157 native search-flow checks. Coverage includes input/request/response, six width changes, short windows, Previous/Next, refocusing, selecting a sender and dispatching the filtered query, cancellation, full-chat-width results, unchanged composer suggestion width, above/below popup placement, saved-tag row insets, initial/replacement slot layout, initial disabled arrows, clear-button visibility through focus/theme/loading/token changes, retention/removal of the native glass effect when closing and quickly reopening search, upstream total-result counters, automatic first-result selection and synchronization when selecting a result row. A cramped counter hides before it can reduce the input below 160 points, then returns when the pane widens.
- Six existing XCTest cases and 475 lower-level header/translation/action assertions pass. Their plain-SearchView checks are not end-to-end search tests.
- A complete Debug arm64 `Telegram.app` build succeeds with the actual native dependencies, including MTProtoEngineFFI, wallet_engineFFI, WebRTC and TDLib. No dependency implementation is replaced with a stub.
- In the actual authenticated client, the public Telegram Tips channel returns server results for `stories`. The first result is Hosting Live Stories (8 December 2025), shown as 1 of 32. Previous selects the older Live Stories result (1 December 2025), shown as 2 of 32, and Next returns to 1 of 32. Refocusing restores the full-width list with its selected row.
- A system Left-half resize reduces the window from about 1512 pt to 756 pt: the query, focus and selected result survive, search falls back below the title and results remain within the chat pane. Filling the window restores the inline layout. Continuous manual dragging and frame timing were not profiled.
- Empty search has disabled Previous/Next and no Clear button. Typing shows Clear; clearing removes it and disables both arrows again. Search replaces the inline pin and closing restores it. With the pin locally dismissed, opening/closing returns to the full title and leaves no description or orphaned panel.
- Saved Messages renders the actual non-Premium Unlock tag with visible side/bottom spacing. The published Saved Messages image contains only the empty left side of the search/tag row; messages and blurred private content are excluded.
- The current UI pass uses integration `712be74a`, including the search merge and independent reaction/photo fixes. Historical no-pin and Saved Messages checks/captures use production source `48b9ee49`. The native removal fixture checks the glass effect during the 0.2-second merge and after cleanup, including immediate removal and rapid reopening.

Environment: Apple Silicon, macOS 27.0.1, Xcode 27.1, Telegram 13.1.0 (283357).

## Full build

```sh
xcodebuild -workspace Telegram-Mac.xcworkspace -scheme Telegram \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /Users/pystoyplayer/dev/telegram-message-validation/client-build -jobs 1 \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES MACOSX_DEPLOYMENT_TARGET=12.0 \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO \
  INDEX_ENABLE_DATA_STORE=NO GCC_GENERATE_DEBUGGING_SYMBOLS=NO \
  SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO COMPILATION_CACHE_ENABLE_CACHING=NO \
  OTHER_SWIFT_FLAGS='$(inherited) -j1' build
```

The initial missing-binary-artifact blocker is resolved. Pinned native dependencies and their shared headers were built locally. Xcode 27 compatibility adjustments and a local account-storage-root override were used only for the validation environment and are not part of the feature patch. This is an unsigned native arm64 Debug build, not a universal release/archive or App Store validation.

The component harness uses controlled backend/domain models and result rows; see README.md for exact extraction boundaries. Calendar/Premium popovers could not be driven reliably through the native automation interface and are not claimed as verified. Real-server pagination, a live sender-filter scenario, server-backed translation, performance profiling and other macOS versions are not covered by this pass. Sender filtering and translation-menu actions are covered by the native fixtures.

## Capture provenance

The refreshed `review-before-search.png` uses search/header source from upstream `df90450c`, including its result counter. `review-after-search.png`, `review-after-narrow.png` and `review-after-pinned.png` use validation integration `712be74a`, whose search source is the resolved `8e01deed` merge. The separate baseline app was rebuilt with the same real dependencies, local SDK/profile adjustments and independent interaction fixes; its header/search source was replaced with the exact upstream versions. Both builds succeeded.

Before/After show Telegram Tips, `stories`, the same first server result and 1 of 32 at the same window width. Narrow shows the same query/result after system Left tiling. Crops remove only the private sidebar/account identity and unrelated lower content. No controls are reconstructed. The Before capture shows search open and does not assert pinned-header placement in a distributed Telegram build.

Historical `client-before-search.png` uses `ab4e31a4`; historical `client-after-*` images use `48b9ee49`. The Saved Messages image excludes messages and private blurred content. These dark-theme stills establish final geometry, not animation frame timing; native fixtures exercise control themes and glass lifecycle.

## Single-action header follow-up

Reopen Topic, Share Info, pending join requests, Request Chat and Set Bot Photo now use the existing inline accessory slot when it has at least 320 points. Their existing handlers are unchanged. The inline control fills the 40-point glass surface; a narrow pane restores the original 36-point row. Multi-action/report, sponsored and paid-message explanation banners remain separate, as do stacked call/translation/forum headers and Saved Messages tags. No channel description is added.

A fresh complete Debug arm64 build succeeds with the actual dependencies. The lower-level count includes 139 extracted production placement/inset/menu checks, 288 native search-control checks, seven typing-reflow checks and 41 checks of the actual extracted Reopen Topic control. The latter exercise English, Russian and a long German label at three widths and both heights, preserving the full accessibility label and calling the original restart handler exactly once. The search harness includes three additional real layout-slot height checks. The collaborators providing account state and strings remain controlled test values.

The complete search pass and published captures above predate this utility-only follow-up. A fresh authenticated smoke check of integration `d159d0b2` (utility source `5794d4e8`) confirms initially disabled navigation, the same `stories` server query returning 1 of 32 with full-width results, and restoration of the pinned header on cancellation. The Reopen Topic live pass below completes the previously missing server-backed utility validation.

## Live Reopen Topic verification

Created the private forum **Topic Header Test** with no invited members and its topic **Release Notes**. Preparation used a local diagnostic helper calling the real authenticated engine and navigating to the actual ChatController; it did not supply replacement UI state or invoke the reopen handler. The helper is excluded from the PR.

In the complete client, clicked the actual **Reopen Topic** accessibility button once. The observed thread state changed from `isClosed = true` to `false`; the button disappeared, the count changed from one to two messages, and native history displayed **You reopened the topic**. The engine changes its closed state after the successful `messages.editForumTopic` response. The topic was then closed again for the comparison captures.

Both `review-before-topic.png` and `review-after-topic.png` show that same closed topic and **3 Messages**, with the emoji sidebar closed, at 3024x1772 raw pixels. The identical 2400x220 crops remove the private chat sidebar and unrelated history. Before restores the exact header source from `5c36bbd3`; After uses utility source `5794d4e8` in integration `d159d0b2`. Both full arm64 Debug builds succeeded with the same real dependencies and local SDK/profile/updater adjustments. These are actual running-client captures, not fixture renders or distributed-release screenshots.

System Left tiling produced an accepted 1514x1772-pixel window; Reopen Topic returned to its separate row, remained readable and did not overlap the title. `review-after-topic-narrow.png` records the narrow state. `review-topic-reopened.png` is a separate crop of the actual service messages after clicking the button.

Source hashes, capture bounds and the before/after state observations are in `tools/tests/chat-header/utility-validation.json`. Live coverage is the forum creator path on macOS 27.0.1, Telegram 13.1.0 (283357); other utility actions retain controlled native-fixture coverage.

Manual reproduction: create a private forum and topic, close the topic from its menu, open it in a wide chat pane, click Reopen Topic, and verify that the button disappears and the topic is reopened. Close it again, narrow the window and restore its width to check the row fallback.


## Search glass corners, 26 October 2026

A reported rectangular search background after switching chats led to a native regression reproduction: `LiquidGlassView.setAnimatorFrame` caches the target size without updating the clamped corner radius. After a zero-height layout has set radius zero, an animated reveal retains the zero radius; its subsequent layout sees the cached size and skips the update. This affects both shared ghost surfaces and standalone glass.

The added native checks use real `GlassContainerView`, `LiquidGlassView` and `NSGlassEffectView` objects. They cover zero-height reveal, collapse/reopen and height changes in shared and standalone hosting. Five checks fail before the fix. Updating the radius before caching the target frame makes all **163/163 search-integration checks pass** (previously 157 checks). The exact user chat-switch sequence is additionally checked in the client; the deterministic reproduction establishes the stale-radius mechanism without relying on a timing-sensitive screenshot.

The latest complete native build includes this corner update. In the authenticated client, opened empty search in Telegram Tips, switched to Saved Messages, reopened search with non-Premium Unlock tags, narrowed to 560 points and closed it. The inline channel search and separate Saved Messages search remained rounded. `review-after-search-corners.png` is a direct crop of the Telegram Tips header; private sidebar content is excluded.

## Saved Messages closing — 2026-10-27

The dedicated search row can extend below the new glass-host height during closing. Retain the host bounds while an outgoing glass still overflows them, then release the retained height after the transition. Reopening cancels the deferred shrink. Standalone search content fades in 0.12 seconds; inline title/search merging retains 0.2 seconds. This prevents pale Search/Unlock text from remaining after the dim glass is already visually gone.

**175/175** native search-flow checks pass. The previous glass host fails four new bounds/lifetime checks. An old-header-only run against the corrected host fails the late-content check. Rendered before/after evidence and explicit coverage limits are in `saved-search-fade/verification.json`; the GIFs are a native lifecycle fixture with controlled labels, not a capture of an authenticated account. Full native client build and endpoint validation are recorded in the PR.
