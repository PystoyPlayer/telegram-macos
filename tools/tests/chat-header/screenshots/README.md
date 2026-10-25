# Actual Telegram client captures

Captured on macOS 27.0.1 using Telegram 13.1.0 (283357), unsigned Debug arm64, with an authenticated isolated test account.

Current review captures:

- `review-before-search.png`: upstream `df90450c` search/header source, public Telegram Tips, query `stories`, counter 1 of 32.
- `review-after-search.png`: integration `712be74a` with resolved search source `8e01deed`, same query/result/counter and window width.
- `review-after-narrow.png`: same query/result after system Left tiling, separate-row fallback.
- `review-after-pinned.png`: restored pinned header after closing search.

The baseline app shares the real dependencies and local SDK/profile adjustments with the integrated app; only its search/header and photo menu source is restored to upstream. Both complete builds succeeded.

Historical captures from the earlier validation pass:

- `client-before-search.png`: upstream `ab4e31a4`, public Telegram Tips, query `stories`, search on its own row.
- `client-after-search.png`: production source `48b9ee49`, same channel/query, inline field and full-chat-width results.
- `client-after-empty.png`: disabled navigation and no clear-input button for an empty query.
- `client-after-pinned.png`: the tested inline pinned-message layout.
- `client-after-no-pin.png`: title after locally hiding the pinned banner; no channel description.
- `client-after-narrow.png`: the same query and first selected result after a system Left-half resize; the field falls back to its own row.
- `client-after-saved-tags.png`: only the empty left side of Saved Messages search and the actual non-Premium Unlock tag.

All images are crops of the running client. The private sidebar, account identity, Saved Messages contents and their blurred backdrop are excluded. No controls or messages are reconstructed. The original illustrative component comparisons were deleted.

These still images establish final geometry and visible control states, not animation frame timing. The exact production glass-removal block is exercised with real GlassContainerView/LiquidGlassView objects by the search integration tests.

## Reopen Topic captures

- `review-before-topic.png`: complete client with exact `5c36bbd3` header source; closed Release Notes topic, 3 Messages, action below the title.
- `review-after-topic.png`: utility header source `5794d4e8` in native integration `d159d0b2`; same topic, state, count, width and crop, action beside the title.
- `review-after-topic-narrow.png`: real system Left-half window; action falls back to its own row.
- `review-topic-reopened.png`: actual history service messages after one UI click on Reopen Topic.

Both comparison builds use the real authenticated account and dependencies. An excluded local setup helper created/closed the private test topic with real engine calls and opened its actual controller. The actual Reopen Topic button was clicked through accessibility; the helper did not invoke that action or replace UI state. The captures are direct crops with no compositing or reconstructed controls. See `../utility-validation.json` and the search validation record for the source hashes, dimensions and observed state transition.
