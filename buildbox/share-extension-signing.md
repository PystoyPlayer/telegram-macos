# Verify the distributed Share Extension

Issue [#48](https://github.com/TelegramMessenger/telegram-macos/issues/48) reports a Developer ID build whose final `TelegramShare.appex` signature contains `keychain-access-groups` without an embedded provisioning profile. The checked-in `TelegramShare/TelegramShare.entitlements` does not request that entitlement.

For the Developer ID re-sign, use that extension-specific entitlement file. Do not reuse `Telegram-Mac/Telegram-Sandbox.entitlements` or apply the main app's entitlements to nested code with `codesign --deep`. If keychain groups are deliberately required, embed a distribution profile that authorizes them. Sign the extension before signing its containing app.

`verify-build.sh` checks the archived app, but `buildbox/internal.sh` subsequently calls a private `../deploy/deploy-$tag.sh`. That script can change the signature. The archive check therefore cannot validate the final distributed signature.

Inside the private deployment script, run the following **after all re-signing and before notarization, packaging or upload**, using the path to the actual re-signed app rather than the unchanged archive:

```sh
python3 "$SOURCE_DIR/buildbox/verify-share-extension.py" "$SIGNED_APP"
```

The command exits nonzero for a missing extension, invalid code signature, unprovisioned keychain access groups, an undecodable/expired profile, or keychain groups that its entitlement allowlist does not authorize. It inspects each executable architecture. It accepts the current Developer ID entitlement set without a profile and accepts profile-authorized keychain groups, including profile wildcards.

The verifier is read-only. It never re-signs or modifies an installed app, launches the extension, changes a keychain, or sends a message. It is a focused guard for this regression, not a replacement for Xcode export, Apple's profile/certificate trust validation, notarization or testing Finder → Share → Telegram on the signed distributable.

Run focused checks without building Telegram:

```sh
python3 -m unittest discover -s buildbox -p test_verify_share_extension.py -v
python3 buildbox/verify-share-extension.py /Applications/Telegram.app
```

The tests compile tiny local Mach-O fixtures and use ad-hoc signatures to exercise the real `codesign` extraction and verification paths. Fixture binaries are never launched. The profile policy is checked separately with controlled dictionaries; the tests do not create a trusted Apple provisioning profile or validate a Developer ID signing identity.
