#!/bin/bash
set -euo pipefail
: "${PROFILE_UUID:?Signing profile was not installed}"
: "${SIGNING_IDENTITY:?Signing identity was not installed}"
: "${APPLE_TEAM_ID:?Apple Team ID is missing}"
# Keep CFBundleVersion within Apple's 4/2/2 digit component limits.
: "${GITHUB_RUN_NUMBER:?GitHub run number is missing}"
: "${GITHUB_RUN_ATTEMPT:?GitHub run attempt is missing}"
if (( GITHUB_RUN_NUMBER > 9999 || GITHUB_RUN_ATTEMPT > 99 )); then
  printf 'Build-number range exceeded; update the versioning strategy before release.\n' >&2
  exit 1
fi
build_number="${GITHUB_RUN_NUMBER}.${GITHUB_RUN_ATTEMPT}.0"
mkdir -p build/export
xcodebuild -project SheepCrate.xcodeproj -scheme SheepCrate \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -archivePath "$PWD/build/SheepCrate.xcarchive" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" PROVISIONING_PROFILE_SPECIFIER="$PROFILE_UUID" \
  PRODUCT_BUNDLE_IDENTIFIER="$APP_BUNDLE_ID" CURRENT_PROJECT_VERSION="$build_number" \
  archive 2>&1 | tee build/archive.log
xcodebuild -exportArchive -archivePath "$PWD/build/SheepCrate.xcarchive" \
  -exportPath "$PWD/build/export" \
  -exportOptionsPlist "$RUNNER_TEMP/sheep-crate-signing/ExportOptions.plist" \
  2>&1 | tee build/export.log
python3 - <<'PY'
from pathlib import Path
files=list(Path('build/export').glob('*.ipa'))
if len(files)!=1:
    raise SystemExit('Expected exactly one exported IPA.')
print('Signed IPA exported. Upload is controlled by the workflow checkbox.')
PY
