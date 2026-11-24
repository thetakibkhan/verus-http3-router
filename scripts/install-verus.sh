#!/usr/bin/env bash
set -euo pipefail

destination=${1:-.phase0-tools}
release=0.2026.11.22.1ce6a59
archive=verus-$release-x86-linux.zip
digest=c955d5958877f4f907cce80aa996d4239a481984829d82e325938c7bf242b0db

mkdir -p "$destination"
if [[ ! -f "$destination/$archive" ]]; then
    curl --fail --location --retry 3 --output "$destination/$archive.part" \
        "https://github.com/verus-lang/verus/releases/download/release/$release/$archive"
    mv "$destination/$archive.part" "$destination/$archive"
fi
printf '%s  %s\n' "$digest" "$destination/$archive" | sha256sum --check -
unzip -oq "$destination/$archive" -d "$destination"
