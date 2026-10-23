#!/bin/bash
set -euo pipefail
umask 077
for name in APPLE_TEAM_ID BUILD_CERTIFICATE_BASE64 P12_PASSWORD BUILD_PROVISION_PROFILE_BASE64 KEYCHAIN_PASSWORD; do
  if [ -z "${!name:-}" ]; then
    printf 'Missing setting: %s. See GITHUB_SETUP_TR.md.\n' "$name" >&2
    exit 1
  fi
done
signing_dir="$RUNNER_TEMP/sheep-crate-signing"
mkdir -p "$signing_dir"
export SIGNING_DIR="$signing_dir"
python3 - <<'PY'
import base64,os
from pathlib import Path
directory=Path(os.environ['SIGNING_DIR'])
for name,file in [('BUILD_CERTIFICATE_BASE64','distribution.p12'),('BUILD_PROVISION_PROFILE_BASE64','profile.mobileprovision')]:
    try:
        data=base64.b64decode(''.join(os.environ[name].split()),validate=True)
    except ValueError:
        raise SystemExit(name+' is not valid Base64.')
    if not data:
        raise SystemExit(name+' decoded to an empty file.')
    (directory/file).write_bytes(data)
PY
security cms -D -i "$signing_dir/profile.mobileprovision" > "$signing_dir/profile.plist"
python3 ci/profile_info.py "$signing_dir"
keychain_path="$signing_dir/app-signing.keychain-db"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$keychain_path"
security set-keychain-settings -lut 21600 "$keychain_path"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$keychain_path"
security import "$signing_dir/distribution.p12" -P "$P12_PASSWORD" -t cert -f pkcs12 \
  -k "$keychain_path" -T /usr/bin/codesign -T /usr/bin/security > /dev/null
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$keychain_path" > /dev/null
export SIGNING_KEYCHAIN_PATH="$keychain_path"
python3 - <<'PY'
import os,shlex,subprocess
existing=shlex.split(subprocess.check_output(['security','list-keychains','-d','user'],text=True))
subprocess.run(['security','list-keychains','-d','user','-s',os.environ['SIGNING_KEYCHAIN_PATH'],*existing],check=True)
PY
fingerprint=$(python3 - <<'PY'
import os,plistlib,hashlib
from pathlib import Path
p=plistlib.loads((Path(os.environ['SIGNING_DIR'])/'profile.plist').read_bytes())
print(hashlib.sha1(p['DeveloperCertificates'][0]).hexdigest().upper())
PY
)
if ! security find-identity -v -p codesigning "$keychain_path" | grep -F "$fingerprint" > /dev/null; then
  printf 'No valid signing identity matching the profile. Check the P12, its private key and Apple certificate chain.\n' >&2
  exit 1
fi
uuid=$(python3 -c 'import os,plistlib,pathlib;print(plistlib.loads((pathlib.Path(os.environ["SIGNING_DIR"])/"profile.plist").read_bytes())["UUID"])')
# Current Xcode profile location; the legacy location supports other installed Xcodes.
for profile_dir in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" "$HOME/Library/MobileDevice/Provisioning Profiles"; do
  mkdir -p "$profile_dir"
  cp "$signing_dir/profile.mobileprovision" "$profile_dir/$uuid.mobileprovision"
done
