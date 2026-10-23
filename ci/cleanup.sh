#!/bin/bash
set -euo pipefail
: "${RUNNER_TEMP:?GitHub runner temporary directory is missing}"
signing_dir="$RUNNER_TEMP/sheep-crate-signing"
trap 'rm -rf "$signing_dir"' EXIT
keychain_path="$signing_dir/app-signing.keychain-db"
if [ -f "$keychain_path" ]; then security delete-keychain "$keychain_path" || true; fi
if [ -f "$signing_dir/profile.plist" ]; then
  uuid=$(python3 -c 'import plistlib,sys;print(plistlib.load(open(sys.argv[1],"rb"))["UUID"])' "$signing_dir/profile.plist" 2>/dev/null) || uuid=''
  if [[ "$uuid" =~ ^[A-Fa-f0-9-]{36}$ ]]; then
    rm -f "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/$uuid.mobileprovision" \
      "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"
  fi
fi
rm -rf "$signing_dir"
