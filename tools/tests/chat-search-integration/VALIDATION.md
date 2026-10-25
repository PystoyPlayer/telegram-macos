# PR #40 follow-up validation — 2026-10-25

Status: the complete client build and authenticated search UI pass are complete for production source `48b9ee49`. Genuine client Before/After captures replace the illustrative component images.

## Completed checks

- The baseline PR head `a190a124` reproduces 57 expected failures in the native search-flow harness: cramped input, stale or narrow result geometry, initial-placement animation, empty search controls, premature glass removal and saved-tag margins. Unrelated failures fail the baseline run.
- The patched source passes 146 native search-flow checks. Coverage includes input/request/response, six width changes, short windows, Previous/Next, refocusing, selecting a sender and dispatching the filtered query, cancellation, full-chat-width results, unchanged composer suggestion width, above/below popup placement, saved-tag row insets, initial/replacement slot layout, initial disabled arrows, clear-button visibility through focus/theme/loading/token changes, and retention/removal of the native glass effect when closing and quickly reopening search.
- Six existing XCTest cases and 370 lower-level header/translation assertions pass. Their plain-SearchView checks are not end-to-end search tests.
- A complete Debug arm64 `Telegram.app` build succeeds with the actual native dependencies, including MTProtoEngineFFI, wallet_engineFFI, WebRTC and TDLib. No dependency implementation is replaced with a stub.
- In the actual authenticated client, the public Telegram Tips channel returns server results for `stories`. Previous selects Hosting Live Stories (8 December 2025), another Previous selects the older Live Stories result (1 December 2025), and Next returns to the first result. Refocusing restores the full-width list with its selected row.
- A system Left-half resize reduces the window from about 1512 pt to 756 pt: the query, focus and selected result survive, search falls back below the title and results remain within the chat pane. Filling the window restores the inline layout. Continuous manual dragging and frame timing were not profiled.
- Empty search has disabled Previous/Next and no Clear button. Typing shows Clear; clearing removes it and disables both arrows again. Search replaces the inline pin and closing restores it. With the pin locally dismissed, opening/closing returns to the full title and leaves no description or orphaned panel.
- Saved Messages renders the actual non-Premium Unlock tag with visible side/bottom spacing. The published Saved Messages image contains only the empty left side of the search/tag row; messages and blurred private content are excluded.
- The UI pass uses production source `48b9ee49`, without the unrelated reaction-loading patch. The native removal fixture checks the glass effect during the 0.2-second merge and after cleanup, including immediate removal and rapid reopening.

Environment: Apple Silicon, macOS 27.0.1, Xcode 27.1, Telegram 13.1.0 (283357).

## Full build

```sh
xcodebuild -workspace Telegram-Mac.xcworkspace -scheme Telegram \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/telegram-pr40-client-build -jobs 4 \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES MACOSX_DEPLOYMENT_TARGET=12.0 \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO \
  INDEX_ENABLE_DATA_STORE=NO GCC_GENERATE_DEBUGGING_SYMBOLS=NO \
  SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO COMPILATION_CACHE_ENABLE_CACHING=NO build
```

The initial missing-binary-artifact blocker is resolved. Pinned native dependencies and their shared headers were built locally. Xcode 27 compatibility adjustments and a local account-storage-root override were used only for the validation environment and are not part of the feature patch. This is an unsigned native arm64 Debug build, not a universal release/archive or App Store validation.

The component harness uses controlled backend/domain models and result rows; see README.md for exact extraction boundaries. Calendar/Premium popovers could not be driven reliably through the native automation interface and are not claimed as verified. Real-server pagination, a live sender-filter scenario, server-backed translation, performance profiling and other macOS versions are not covered by this pass. Sender filtering and translation-menu actions are covered by the native fixtures.

## Capture provenance

`tools/tests/chat-header/screenshots/client-before-search.png` is the actual unmodified upstream `ab4e31a4` client. `client-after-*` images use production source `48b9ee49`. Both primary captures show Telegram Tips and the same `stories` query. Crops exclude the private sidebar, account title and unrelated messages; no controls are reconstructed. Before shows search open, so it makes no claim about pinned-header placement in newer distributed binaries. The separate After pin capture shows the tested inline layout. These are dark-theme client captures; the native layout fixtures also exercise the existing control themes.
