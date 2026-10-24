import datetime
import importlib.util
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest


spec = importlib.util.spec_from_file_location("verify_share_extension", Path(__file__).with_name("verify-share-extension.py"))
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
NOW = datetime.datetime(2026, 10, 24, tzinfo=datetime.timezone.utc)
GROUP = "6N38VWS5BX.ru.keepcoder.TelegramShare"


class ProfilePolicyTests(unittest.TestCase):
    def profile(self, groups):
        return {"ExpirationDate": NOW + datetime.timedelta(days=1), "Entitlements": {"keychain-access-groups": groups}}

    def test_no_keychain_entitlement_needs_no_profile(self):
        verifier.validate_keychain_groups({"com.apple.security.app-sandbox": True}, None, NOW)

    def test_empty_keychain_entitlement_needs_no_profile(self):
        verifier.validate_keychain_groups({"keychain-access-groups": []}, None, NOW)

    def test_issue_48_missing_profile(self):
        with self.assertRaisesRegex(verifier.VerificationError, "no embedded.provisionprofile"):
            verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, None, NOW)

    def test_exact_authorization(self):
        verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, self.profile([GROUP]), NOW)

    def test_profile_wildcard_authorization(self):
        verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, self.profile(["6N38VWS5BX.*"]), NOW)

    def test_every_group_must_be_authorized(self):
        with self.assertRaisesRegex(verifier.VerificationError, "does not authorize"):
            verifier.validate_keychain_groups({"keychain-access-groups": [GROUP, "OTHER.group"]}, self.profile([GROUP]), NOW)

    def test_profile_wildcard_must_match_prefix(self):
        with self.assertRaisesRegex(verifier.VerificationError, "does not authorize"):
            verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, self.profile(["OTHER.*"]), NOW)

    def test_only_star_is_a_wildcard(self):
        with self.assertRaisesRegex(verifier.VerificationError, "does not authorize"):
            verifier.validate_keychain_groups({"keychain-access-groups": ["TEAM.a"]}, self.profile(["TEAM.[ab]"]), NOW)

    def test_expired_profile(self):
        profile = self.profile([GROUP])
        profile["ExpirationDate"] = NOW - datetime.timedelta(seconds=1)
        with self.assertRaisesRegex(verifier.VerificationError, "expired"):
            verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, profile, NOW)

    def test_profile_without_expiration(self):
        with self.assertRaisesRegex(verifier.VerificationError, "ExpirationDate"):
            verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, {"Entitlements": {}}, NOW)

    def test_plist_naive_utc_expiration(self):
        profile = self.profile([GROUP])
        profile["ExpirationDate"] = profile["ExpirationDate"].replace(tzinfo=None)
        verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, profile, NOW)

    def test_invalid_group_types(self):
        for value in ["group", None, [1], [""]]:
            with self.subTest(value=value), self.assertRaises(verifier.VerificationError):
                verifier.validate_keychain_groups({"keychain-access-groups": value}, None, NOW)

    def test_malformed_profile_entitlements(self):
        for value in [None, [], "group"]:
            profile = self.profile([GROUP])
            profile["Entitlements"] = value
            with self.subTest(value=value), self.assertRaisesRegex(verifier.VerificationError, "invalid Entitlements"):
                verifier.validate_keychain_groups({"keychain-access-groups": [GROUP]}, profile, NOW)


@unittest.skipUnless(shutil.which("codesign") and shutil.which("xcrun"), "requires macOS developer tools")
class SignedBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="telegram-share-signing-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / "Telegram.app"
        self.extension = self.app / "Contents/PlugIns/TelegramShare.appex"
        contents = self.extension / "Contents"
        (contents / "MacOS").mkdir(parents=True)
        self.binary = contents / "MacOS/TelegramShare"
        self.info = contents / "Info.plist"
        self.info.write_bytes(plistlib.dumps({"CFBundleExecutable": "TelegramShare", "CFBundleIdentifier": "test.telegram.share", "CFBundlePackageType": "XPC!"}))
        source = self.root / "fixture.c"
        source.write_text("int main(void) { return 0; }\n")
        subprocess.run(["xcrun", "clang", str(source), "-o", str(self.binary)], check=True, capture_output=True)

    def sign(self, entitlements):
        path = self.root / "entitlements.plist"
        path.write_bytes(plistlib.dumps(entitlements))
        subprocess.run(["/usr/bin/codesign", "--force", "--sign", "-", "--entitlements", str(path), str(self.extension)], check=True, capture_output=True)

    def test_current_developer_id_entitlement_set(self):
        entitlements = plistlib.loads((Path(__file__).parents[1] / "TelegramShare/TelegramShare.entitlements").read_bytes())
        self.sign(entitlements)
        verifier.verify(self.app)

    def test_reproduced_issue_48_signature_is_rejected(self):
        self.sign({"keychain-access-groups": [GROUP]})
        with self.assertRaisesRegex(verifier.VerificationError, "no embedded.provisionprofile"):
            verifier.verify(self.app)

    def test_invalid_embedded_profile_is_rejected(self):
        (self.extension / "Contents/embedded.provisionprofile").write_bytes(b"invalid profile")
        self.sign({"keychain-access-groups": [GROUP]})
        with self.assertRaisesRegex(verifier.VerificationError, "security failed"):
            verifier.verify(self.app)

    def test_tampered_binary_is_rejected(self):
        self.sign({})
        with self.binary.open("ab") as binary:
            binary.write(b"changed")
        with self.assertRaisesRegex(verifier.VerificationError, "codesign failed"):
            verifier.verify(self.app)

    def test_missing_extension_is_rejected(self):
        shutil.rmtree(self.extension)
        with self.assertRaisesRegex(verifier.VerificationError, "missing share extension"):
            verifier.verify(self.app)

    def test_missing_executable_is_rejected(self):
        self.binary.unlink()
        with self.assertRaisesRegex(verifier.VerificationError, "missing share-extension executable"):
            verifier.verify(self.app)

    def test_path_traversal_executable_is_rejected(self):
        self.info.write_bytes(plistlib.dumps({"CFBundleExecutable": "../TelegramShare"}))
        with self.assertRaisesRegex(verifier.VerificationError, "CFBundleExecutable"):
            verifier.verify(self.app)

    def universal(self, second_entitlements):
        self.sign({})
        second = self.root / "Other.appex"
        shutil.copytree(self.extension, second)
        host = subprocess.check_output(["/usr/bin/lipo", "-archs", str(self.binary)], text=True).strip()
        other = "x86_64" if host == "arm64" else "arm64"
        second_binary = second / "Contents/MacOS/TelegramShare"
        subprocess.run(["xcrun", "clang", "-arch", other, str(self.root / "fixture.c"), "-o", str(second_binary)], check=True, capture_output=True)
        entitlements = self.root / "other-entitlements.plist"
        entitlements.write_bytes(plistlib.dumps(second_entitlements))
        subprocess.run(["/usr/bin/codesign", "--force", "--sign", "-", "--entitlements", str(entitlements), str(second)], check=True, capture_output=True)
        combined = self.root / "universal"
        subprocess.run(["/usr/bin/lipo", "-create", str(self.binary), str(second_binary), "-output", str(combined)], check=True, capture_output=True)
        combined.replace(self.binary)
        return other

    def test_universal_clean_signature(self):
        self.universal({})
        verifier.verify(self.app)

    def test_non_host_architecture_is_checked(self):
        architecture = self.universal({"keychain-access-groups": [GROUP]})
        with self.assertRaisesRegex(verifier.VerificationError, architecture + ": .*no embedded.provisionprofile"):
            verifier.verify(self.app)


if __name__ == "__main__":
    unittest.main()
