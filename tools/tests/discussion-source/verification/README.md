# Navigate from comments to the original channel

macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. Baseline/candidate native workspace builds succeeded, followed by a full build without diagnostic hooks (integration c5a43c3a).

## Public native scenario

Both runs start in the public Pavel Durov channel (@durov). A temporary launcher opens the real comments for [Telegram Info English post 2208](https://t.me/tginfoen/2208), calling the existing openReplyThread path with that actual channel message ID. It does not fabricate reply-thread data or alter the navigation stack. No comments were available on the inspected Durov posts, so Telegram Info English supplies the public source/comments pair.

1. Open the same external comments thread from Pavel Durov's channel.
2. Click the production glass Discussion title.
3. Before: Discussion remains open; Back returns to Pavel Durov. [Before, after clicking the title](before-public.png).
4. After: Telegram Info English opens at the original post. Back returns to Discussion; the next Back returns to Pavel Durov. [After, after clicking the title](after-public.png).

Both images retain the same public source post, so the destination change can be checked against the post thumbnail and heading. They are exact crops of native captures, not mockups. The same crop (1540x1000, x620/y0 in a 3024x1770 native capture) excludes the entire private sidebar, account controls, comment text and diagnostic launchers. The Discussion root post is centered while the channel history post is left-aligned; this is the actual client layout. No full-window capture is included in this branch. No messages/reactions were sent, channels joined or server settings changed.

## Source checks

Run `python3 tools/tests/discussion-source/run.py`. **23/23** checks pass versus **17/23** on origin/master; see before-checks.txt. Both actual legacy and modern glass header action bodies and the source selector are extracted. Cases cover resolved-source priority, fallback, source-post focus, unknown sources, ordinary profiles and forum topics. Navigation collaborators are stubs; the actual native Back stack is checked above.

Only the modern glass header was clicked in the full client. Legacy behavior is covered by source checks; another macOS version was unavailable. Integration-only build/profile overrides, other pending changes and temporary launchers are excluded from this PR.
