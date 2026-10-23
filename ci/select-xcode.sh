#!/bin/bash
set -euo pipefail
# Avoid a runner's older default Xcode. No third-party setup action is needed.
developer_dir=$(python3 - <<'PY'
import glob,re,subprocess
choices=[]
for path in glob.glob('/Applications/Xcode*.app'):
    if re.search(r'beta|candidate|preview|_rc',path,re.I):
        continue
    tool=path+'/Contents/Developer/usr/bin/xcodebuild'
    try:
        version=subprocess.check_output([tool,'-version'],text=True,stderr=subprocess.DEVNULL)
    except (OSError,subprocess.CalledProcessError):
        continue
    match=re.search(r'Xcode (\d+(?:\.\d+)*)',version)
    if match:
        number=tuple(map(int,match[1].split('.')))
        if number[0]>=26:
            choices.append((number,path+'/Contents/Developer'))
if not choices:
    raise SystemExit('No stable Xcode 26+ installed. Choose a newer macOS runner image in both workflows.')
print(max(choices)[1])
PY
)
printf 'DEVELOPER_DIR=%s\n' "$developer_dir" >> "$GITHUB_ENV"
DEVELOPER_DIR="$developer_dir" xcodebuild -version
