import argparse
import datetime
import plistlib
from pathlib import Path
import re
import subprocess
import sys


class VerificationError(ValueError):
    pass


def command(arguments):
    result = subprocess.run(arguments, capture_output=True)
    if result.returncode:
        detail = result.stderr.decode(errors="replace").strip()
        raise VerificationError(f"{arguments[0]} failed: {detail}")
    return result.stdout


def parse_plist(data, description):
    try:
        value = plistlib.loads(data)
    except (ValueError, plistlib.InvalidFileException) as error:
        raise VerificationError(f"invalid {description}: {error}") from error
    if not isinstance(value, dict):
        raise VerificationError(f"{description} is not a dictionary")
    return value


def validate_keychain_groups(entitlements, profile, now=None):
    groups = entitlements.get("keychain-access-groups", [])
    if not isinstance(groups, list) or any(not isinstance(group, str) or not group for group in groups):
        raise VerificationError("keychain-access-groups must be an array of nonempty strings")
    if not groups:
        return
    if profile is None:
        raise VerificationError(
            "TelegramShare.appex claims keychain-access-groups but has no embedded.provisionprofile; "
            "AMFI can reject its launch with 'No matching profile found'. For Developer ID distribution, "
            "sign the extension with TelegramShare/TelegramShare.entitlements, or embed a matching "
            "Developer ID provisioning profile. Check the final re-signed app before uploading it."
        )
    expiration = profile.get("ExpirationDate")
    if not isinstance(expiration, datetime.datetime):
        raise VerificationError("embedded profile has no valid ExpirationDate")
    expiration = expiration.replace(tzinfo=datetime.timezone.utc) if expiration.tzinfo is None else expiration
    if expiration <= (now or datetime.datetime.now(datetime.timezone.utc)):
        raise VerificationError("embedded profile has expired")
    profile_entitlements = profile.get("Entitlements")
    if not isinstance(profile_entitlements, dict):
        raise VerificationError("embedded profile has invalid Entitlements")
    allowed = profile_entitlements.get("keychain-access-groups", [])
    if not isinstance(allowed, list) or any(not isinstance(value, str) for value in allowed):
        raise VerificationError("embedded profile has invalid keychain-access-groups")
    for group in groups:
        if not any(re.fullmatch(re.escape(value).replace(r"\*", ".*"), group) for value in allowed):
            raise VerificationError(f"embedded profile does not authorize keychain access group {group!r}")


def verify(app):
    app = Path(app)
    extension = app / "Contents/PlugIns/TelegramShare.appex"
    if not extension.is_dir():
        raise VerificationError(f"missing share extension: {extension}")
    info_path = extension / "Contents/Info.plist"
    if not info_path.is_file():
        raise VerificationError(f"missing extension Info.plist: {info_path}")
    info = parse_plist(info_path.read_bytes(), "extension Info.plist")
    executable = info.get("CFBundleExecutable")
    if not isinstance(executable, str) or not executable or Path(executable).name != executable:
        raise VerificationError("invalid share-extension CFBundleExecutable")
    binary = extension / "Contents/MacOS" / executable
    if not binary.is_file():
        raise VerificationError(f"missing share-extension executable: {binary}")
    command(["/usr/bin/codesign", "--verify", "--strict", "--all-architectures", str(extension)])
    architectures = command(["/usr/bin/lipo", "-archs", str(binary)]).decode().split()
    if not architectures:
        raise VerificationError("share extension has no executable architectures")
    profile_path = extension / "Contents/embedded.provisionprofile"
    profile = None
    profile_loaded = False
    for architecture in architectures:
        raw = command(["/usr/bin/codesign", "--display", "--architecture", architecture, "--entitlements", "-", "--xml", str(extension)])
        entitlements = parse_plist(raw, f"{architecture} entitlements") if raw.strip() else {}
        if entitlements.get("keychain-access-groups") and profile_path.is_file() and not profile_loaded:
            profile = parse_plist(command(["/usr/bin/security", "cms", "-D", "-i", str(profile_path)]), "embedded provisioning profile")
            profile_loaded = True
        try:
            validate_keychain_groups(entitlements, profile)
        except VerificationError as error:
            raise VerificationError(f"{architecture}: {error}") from error
        print(f"TelegramShare {architecture}: signature verified; keychain groups "
              f"{'authorized by embedded profile' if entitlements.get('keychain-access-groups') else 'not requested'}")


def main():
    parser = argparse.ArgumentParser(description="Check the signed share extension before publishing Telegram.app")
    parser.add_argument("app", type=Path)
    args = parser.parse_args()
    try:
        verify(args.app)
    except (OSError, VerificationError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
