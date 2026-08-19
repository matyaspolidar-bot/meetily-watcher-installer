#!/usr/bin/env bash
# Sbalí src/ do jednoho tarballu a nahraje ho jako asset GitHub Release.
# Distribuce jde přes docs/install.sh (curl | bash) - žádný ZIP, žádný .app,
# žádný Gatekeeper. Soubory stažené přes curl/tar nedostávají
# com.apple.quarantine, takže se Gatekeeper vůbec nespustí.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

VERSION="1.1.0"
STAGING="dist/meetily-watcher"
OUT="dist/meetily-watcher-payload.tar.gz"

rm -rf dist
mkdir -p "$STAGING"

echo "-> Ověřuji přibalenou Meetily.dmg..."
bash src/vendor/download.sh

echo "-> Kopíruji instalátor do stage..."
cp -R src/* "$STAGING/"
find "$STAGING" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$STAGING" -name "*.pyc" -delete

echo "-> Balím tarball (jméno souboru bez verze - 'latest' URL se nikdy nemění)..."
tar -czf "$OUT" -C dist meetily-watcher

echo "-> Vytvářím GitHub Release v${VERSION}..."
gh release create "v${VERSION}" "$OUT" --title "v${VERSION}" --generate-notes

echo "Hotovo: v${VERSION} nahráno, asset dostupný na stabilní URL:"
echo "https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/latest/download/$(basename "$OUT")"
