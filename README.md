# Retained star chip verification — 2026-11-01

Neutral native AppKit diagnostic views, manually clicked through macOS accessibility and exported by the view. These are controlled component captures, not screenshots of Telegram conversations or the Telegram glass renderer. There is no Telegram account, network transport, balance change or Stars transfer.

Before uses production chip callback bodies at 39139593; after uses 161190c7. A row is retired while its peer permits reactions and its message media is being replaced. The diagnostic sends through recording collaborators. Before, one tap reaches the transport counter; after, the same tap is blocked. Layout and conditions match. The public images contain no private account or chat content and have not been retouched.

The standalone source-extraction suite passes 113/113 after, versus 107/113 at 39139593 (six newly covered star-chip states fail before). Source fixtures and UI builder live in this evidence-only branch and are excluded from the production PR.

Reproduce on macOS with Xcode 27.2: check out codex/reaction-boost-permissions in a normal Telegram source checkout, then run:

```sh
python3 reaction-tests/run.py --source-root /path/to/telegram-macos
python3 reaction-tests/run.py --source-root /path/to/telegram-macos --revision 39139593
python3 build-star-evidence.py --source-root /path/to/telegram-macos
```

Open the resulting Before and After apps, click Tap retained star once, then Export native view. No server action occurs. The builder compiles extracted production callbacks with controlled message, interaction, pending-media and engine collaborators. The figures show their behavior and are not an end-to-end server delivery claim.
