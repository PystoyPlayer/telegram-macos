# Native scrollbar review follow-up

These are cropped, unretouched captures of the actual Telegram Message Fixes client on macOS 27.0.1, Xcode 27.2, Debug arm64. Both use General Settings at scroller value 0.66 in the same window. The crop contains only generic controls and the vertical scrollbar; account and chat information is excluded.

Before: integration 6a4eedbe, custom ThemedScroller drawing. After: integration 663d1256, AppKit owns the scrollbar with no knob/color/width drawing overrides. The source PR is TelegramMessenger/telegram-macos#130, revision f3d8cc80.

The three standard TGUIKit ScrollerInsetsTests pass after the fix. At the preceding PR revision 934d56c2, the new native-implementation test fails while the two geometry/horizontal tests pass. The repeated-update test retains top clearance and checks the real scroller endpoint for 0, 20 and 56 point content insets.

This branch stores review media outside the production patch. These captures show the appearance follow-up, not a new demonstration of the original footer-offset bug. Other macOS versions and the physical Increase Contrast preference were not exercised.
