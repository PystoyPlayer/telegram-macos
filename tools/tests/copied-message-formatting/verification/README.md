# Native clipboard formatting comparison

Environment: macOS 27.0.1 (26A434), Xcode 27.1, Telegram 13.1.0 (283357), Debug arm64. Both complete workspace builds succeeded using real dependencies in the integration checkout. That checkout contains other pending UI work and local SDK/profile overrides excluded from this PR.

The temporary `RenderedCopyHarness.swift` creates production ChatMessageItem rows with controlled entities, invokes the actual application Copy callback through LinkHooks, reads the system pasteboard, decodes its real .kInApp data, and renders the resulting attributed text in a native ChatInputTextView. It also checks send preparation without sending anything. The matching screenshots use the same message and public channel context. The diagnostic window is explicitly labeled and does not recreate message or input rendering.

- Before: **32/60** checks pass. Inline and block code and quote metadata are lost during the clipboard round trip. The displayed draft becomes plain text. [Image](before.png), [checks](before-models.json).
- After: **60/60** historical checks pass (56 clipboard-path checks and 4 direct normalization checks). Code, language metadata, quote boundaries and collapsed state survive. [Image](after.png), [checks](after-models.json).

Cases cover inline code; preformatted blocks with missing, ordinary and long language identifiers; adjacent quotes; collapsed quotes; UTF-16 partial selection containing code and bold text; plain text; adjacent code blocks with different languages; and adjacent collapsed/expanded quote boundaries. Expected entities are independently clipped to the selection and trimmed for send preparation; the expected path does not use the production normalization being tested.

Reproduce with `python3 tools/tests/copied-message-formatting/build.py --source-root /path/to/full/checkout --derived-data /path/to/derived-data`. Use `--baseline <revision>` for the comparison. Open a chat in the resulting app, click Clipboard formatting validation, then Copy message → Paste draft → Check. Set TELEGRAM_COPY_EVIDENCE to choose the output directory; the fixture writes to its telegram-copy-formatting subdirectory. Build prerequisites and account setup are the normal application's requirements. The script now clones the supplied source checkout into a disposable APFS copy before injecting diagnostics. Hard termination can leave only that temporary copy, not changes in the supplied checkout. The hook and diagnostic window are committed under tools and are not members of the shipping target.

Boundaries: this exercises the production clipboard writer and codec followed by native draft rendering and send preparation. It does not simulate a physical context-menu selection or invoke the app's keyboard paste command. No messages were sent. Only this macOS version and Debug configuration were available. Other-app rich-text paste and a second macOS version were not tested.

## Review follow-up

`review-tests.py` compiles the production legacy-code conversion and attribute-inheritance block: six checks pass for fenced edit representation without overlapping code attributes, structured code preservation, rich paste isolation and plain typing inheritance. The font refresh now handles code attributes as monospace and clears stale code runs. The shared application copy callback applies to all input fields; `.pre` round trips also affect draft restore, editing and fact-check inputs. The earlier 60-check native evidence predates this follow-up; it is not a claim that all checks invoked the copy callback.
