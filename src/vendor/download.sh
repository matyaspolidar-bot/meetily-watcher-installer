#!/usr/bin/env bash
# Stáhne pinned verzi Meetily.dmg (nekomitujeme 47MB binárku do gitu).
# Spustit před build.sh, pokud src/vendor/meetily_0.4.0_aarch64.dmg chybí.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

VERSION="v0.4.0"
FILE="meetily_0.4.0_aarch64.dmg"

if [ -f "$FILE" ]; then
    echo "Už staženo: $FILE"
    exit 0
fi

gh release download "$VERSION" --repo Zackriya-Solutions/meetily --pattern "$FILE" --clobber
echo "Staženo: $FILE"
