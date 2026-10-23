#!/bin/bash
set -euo pipefail
umask 077
command -v openssl > /dev/null || { printf 'OpenSSL is required. Run this from Git Bash with OpenSSL available.\n' >&2; exit 1; }
printf 'Choose a private folder OUTSIDE your repository for Apple signing files.\n'
read -r -p 'Private output directory: ' output_dir
mkdir -p "$output_dir"
if [ -e "$output_dir/distribution.key" ] || [ -e "$output_dir/distribution.certSigningRequest" ]; then
  printf 'Existing signing files found; choose another folder. No files were overwritten.\n' >&2
  exit 1
fi
openssl genrsa -out "$output_dir/distribution.key" 2048
# Interactive subject entry avoids passing personal details through shell interpolation.
openssl req -new -sha256 -key "$output_dir/distribution.key" -out "$output_dir/distribution.certSigningRequest"
printf 'Upload only distribution.certSigningRequest to Apple. Keep distribution.key private.\n'
