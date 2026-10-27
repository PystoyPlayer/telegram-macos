# Native clipboard formatting comparison

Environment: macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. Both complete workspace builds succeeded using real dependencies in the integration checkout. That checkout contains other pending UI work and local SDK/profile overrides excluded from this PR.

The temporary `RenderedCopyHarness.swift` creates production ChatMessageItem rows with controlled entities, invokes the actual application Copy callback through LinkHooks, reads the system pasteboard, decodes its real .kInApp data, and renders the resulting attributed text in a native ChatInputTextView. It also checks send preparation without sending anything. The matching screenshots use the same message and public channel context. The diagnostic window is explicitly labeled and does not recreate message or input rendering.

- Before: **32/60** checks pass. Inline and block code and quote metadata are lost during the clipboard round trip. The displayed draft becomes plain text. [Image](before.png), [checks](before-models.json).
- After: **60/60** pass. Code, language metadata, quote boundaries and collapsed state survive. [Image](after.png), [checks](after-models.json).

Cases cover inline code; preformatted blocks with missing, ordinary and long language identifiers; adjacent quotes; collapsed quotes; UTF-16 partial selection containing code and bold text; plain text; adjacent code blocks with different languages; and adjacent collapsed/expanded quote boundaries. Expected entities are independently clipped to the selection and trimmed for send preparation; the expected path does not use the production normalization being tested.

Reproduce with `python3 tools/tests/copied-message-formatting/build.py --source-root /path/to/full/checkout --derived-data /path/to/derived-data`. Use `--baseline <revision>` for the comparison. Open a chat in the resulting app, click Clipboard formatting validation, then Copy message → Paste draft → Check. Set TELEGRAM_COPY_EVIDENCE to choose the output directory; the fixture writes to its telegram-copy-formatting subdirectory. Build prerequisites and account setup are the normal application's requirements. The script restores the original sources in finally, and neither the hook nor the diagnostic window ships with the change.

Boundaries: this exercises the production clipboard writer and codec followed by native draft rendering and send preparation. It does not simulate a physical context-menu selection or invoke the app's keyboard paste command. No messages were sent. Only this macOS version and Debug configuration were available. Other-app rich-text paste and a second macOS version were not tested.
