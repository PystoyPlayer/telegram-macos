# Revealed media must replace its blurred preview

macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64.

The spoiler photo transform produces an intentionally blurred DrawingContext whose default isHighQuality is true. ChatInteractiveContentView previously read and wrote that transform through the normal cacheMedia key (media, arguments, scale, position flags), with no concealment discriminator. After reveal, cachedMedia could return the blurred result as fully loaded. The alreadyRendered argument then let TransformImageRenderer skip the unblurred decode for unchanged geometry and complete resource data. Opening the gallery or changing geometry used another cache entry and appeared to fix the image.

Concealed spoiler/sensitive/secret media now bypass both reads and writes of the ordinary transformed-image cache. Concealed renders also cannot supply the alreadyRendered shortcut. After reveal the normal photo/video path and cache resume. This prevents a blurred spoiler placeholder from masquerading as the completed normal image, and prevents a cached normal frame from being selected for a concealed image. No full-size resource or disk cache is deleted.

Native comparison uses three local neutral checkerboard images, the real ChatInteractiveContentView, real chatSecretPhoto/chatMessagePhoto transforms, real mediaBox data and the production image cache/renderer. The diagnostic reads ink visibility and image pixel variance after revealing the images at unchanged geometry, without opening the gallery. It sends no media or messages and includes no chat/sidebar contents.

## Native comparison

Matching complete-client diagnostic windows use three generated black/white checkerboard images. No user-supplied photos, sidebar, messages or account avatars are included.

- Before: **3/6** checks pass. The ink overlay disappears from all three tiles, but all three image buffers remain blurred. [Image](before.png), [pixel checks](before-models.json).
- After: **6/6** pass. All three buffers become sharp at the same size without opening the gallery. [Image](after.png), [pixel checks](after-models.json).

The fixture puts full-size and thumbnail PNGs into the real mediaBox under fresh local resource IDs. It creates actual ChatInteractiveContentView instances, reveals them through production layout parameters, then checks the actual rendered image's pixel variance and ink visibility after one second. It does not redraw or simulate the image pipeline. The neutral local photo references do not require downloading private/server media. Baseline and candidate complete diagnostic workspace builds succeeded.

Reproduce with `python3 tools/tests/spoiler-media/build-native.py --source-root /path/to/full/checkout --derived-data /path/to/derived-data`; add `--baseline <revision>` for the comparison. Open a chat in the resulting app, click Media spoiler validation, wait for hidden images to load, then Reveal test album. The JSON report is written to NSTemporaryDirectory()/spoiler-media.json. The builder restores sources and removes the temporary helper in finally. Neither the launcher nor the image probe ships.

Boundaries: the reveal state is driven by a diagnostic button through real layout parameters, not a physical click on a server-backed message. The photo reveal pipeline is checked in the native client; video, sensitive and secret-media branches were reviewed but not separately exercised. Only this macOS version and Debug configuration were available. The integration checkout's other changes and SDK/profile overrides are excluded from this PR.

## Review follow-up

The cache policy is narrowed to concealed, non-sensitive spoiler photo previews with a real parent message. Parentless send/rich-editor previews, secret self-destructing media, videos and sensitive-content gating retain their original cache/decode paths; the unused video binding change is removed. Six compiled policy checks plus three wiring assertions pass. The historical rendered regression is an album-photo scenario; standalone photos did not reproduce the alreadyRendered shortcut, and videos/sensitive/secret rendering are not claimed as validated by those captures. The same photo cache policy prevents an album tile from reusing a blurred shared preview when revealed.

The diagnostic builder now injects into a disposable APFS clone of the supplied checkout. The launcher, probe injector and harness are committed test material under tools; they are excluded from shipping target membership, not from the PR.
