# PR 111 runtime corner-policy checks

This evidence-only branch runs exact production corner-policy snippets on real GitHub-hosted macOS 15, 26 and 27 virtual machines. It does not build or run the complete Telegram client. View, LiquidGlassView and theme collaborators are controlled AppKit stand-ins, so it does not establish the full liquid-glass appearance or account navigation on those systems.

policy_probe.py extracts the complete MainController_View and EntertainmentSidebarView implementations and the folder-rail corner policy from the pinned before/after source files. It compiles them against the actual runner's AppKit SDK, creates native windows and exercises dark/light appearance, no/horizontal/vertical folder geometry, compact width and wide-to-compact-to-wide transitions. Reports record the actual OS/compiler and both effective/applied radii. A changed folder geometry is not described as a real account preference change.

The 66 assertions compare the applied background/glass/content masks with AppKit's resolved radii on macOS 27, and with the unchanged 8-point (pre-26) or 20-point (26) fallback on older systems. The old policy intentionally does not satisfy the new concentric checks on macOS 27. No private account data, client binary, credentials or chat content is uploaded.

Run locally: python3 policy_probe.py --source after --output results/after
