# Spoiler preview cache verification

Real concealed message photo/video previews, including sensitive-content previews, bypass the shared sharp-image cache and do not satisfy its already-rendered shortcut. Parentless send/rich-editor previews and secret self-destructing media retain the original paths, avoiding repeated decode and empty recycled secret frames.

`python3 tools/tests/spoiler-media/review-tests.py` compiles the production cache policy with controlled parent/media values: six cases and three wiring assertions cover concealed/revealed, parentless, secret, video and sensitive previews. These establish cache routing, not video playback/reveal rendering.

The retained Before/After images use neutral checkerboard album photos in actual production rows. They reproduce grouped-photo blur after reveal. Standalone photos did not reproduce the album shortcut; sensitive/video/secret rendering has not been newly exercised in the client. The old full-client reports are historical integration evidence and are not credited to a new live run.

`build-native.py --source-root /path/to/full/checkout --derived-data /path/to/derived-data` clones the supplied source tree into a disposable APFS copy before installing SpoilerMediaHarness and its probe. Hard termination can leave that copy but cannot leave diagnostic writes in the supplied checkout. These diagnostic sources are committed under tools and excluded from shipping target membership. Never use private user media as public evidence.
