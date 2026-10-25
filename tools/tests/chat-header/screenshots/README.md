# Actual Telegram client captures

Captured on macOS 27.0.1 using Telegram 13.1.0 (283357), unsigned Debug arm64, with an authenticated isolated test account.

- `client-before-search.png`: upstream `ab4e31a4`, public Telegram Tips, query `stories`, search on its own row.
- `client-after-search.png`: production source `48b9ee49`, same channel/query, inline field and full-chat-width results.
- `client-after-empty.png`: disabled navigation and no clear-input button for an empty query.
- `client-after-pinned.png`: the tested inline pinned-message layout.
- `client-after-no-pin.png`: title after locally hiding the pinned banner; no channel description.
- `client-after-narrow.png`: the same query and first selected result after a system Left-half resize; the field falls back to its own row.
- `client-after-saved-tags.png`: only the empty left side of Saved Messages search and the actual non-Premium Unlock tag.

All images are crops of the running client. The private sidebar, account identity, Saved Messages contents and their blurred backdrop are excluded. No controls or messages are reconstructed. The original illustrative component comparisons were deleted.

These still images establish final geometry and visible control states, not animation frame timing. The exact production glass-removal block is exercised with real GlassContainerView/LiquidGlassView objects by the search integration tests.
