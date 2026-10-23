#!/bin/bash
set -euo pipefail
umask 077
for name in ASC_KEY_ID ASC_ISSUER_ID ASC_PRIVATE_KEY_BASE64; do
  if [ -z "${!name:-}" ]; then printf 'Missing GitHub Secret: %s\n' "$name" >&2; exit 1; fi
done
key_dir="$RUNNER_TEMP/sheep-crate-signing/private_keys"
mkdir -p "$key_dir"
export API_PRIVATE_KEYS_DIR="$key_dir"
python3 - <<'PY'
import os,base64,re
from pathlib import Path
key_id=os.environ['ASC_KEY_ID'];issuer=os.environ['ASC_ISSUER_ID']
if not re.fullmatch(r'[A-Z0-9]{10}',key_id):
    raise SystemExit('ASC_KEY_ID must be a 10-character key ID.')
if not re.fullmatch(r'[a-fA-F0-9-]{36}',issuer):
    raise SystemExit('Use an App Store Connect team API key with its Issuer ID.')
try:
    data=base64.b64decode(''.join(os.environ['ASC_PRIVATE_KEY_BASE64'].split()),validate=True)
except ValueError:
    raise SystemExit('ASC_PRIVATE_KEY_BASE64 is not valid Base64.')
if not data.startswith(b'-----BEGIN PRIVATE KEY-----'):
    raise SystemExit('Expected an Apple API private .p8 key.')
(Path(os.environ['API_PRIVATE_KEYS_DIR'])/('AuthKey_'+key_id+'.p8')).write_bytes(data)
PY
ipa_path=$(python3 - <<'PY'
from pathlib import Path
files=list(Path('build/export').glob('*.ipa'))
if len(files)!=1:raise SystemExit('Expected exactly one IPA.')
print(files[0].resolve())
PY
)
xcrun altool --upload-app --type ios --file "$ipa_path" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tee build/upload.log
printf 'Upload completed. Wait for Apple processing, then check App Store Connect > TestFlight.\n'
