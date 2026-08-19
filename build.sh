#!/usr/bin/env bash
# Fáze 1: sestaví "Nainstalovat Meetily Watcher.app" (osacompile + zkopírovaný src/
# dovnitř Contents/Resources) a zabalí ho do jednoho ZIPu - to je jediný soubor,
# který konzultant stahuje. Žádný Terminal, žádné git clone.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

VERSION="1.0.0"
APP_NAME="Nainstalovat Meetily Watcher"
APP_DIR="launcher/${APP_NAME}.app"
OUT="dist/meetily-watcher-installer-${VERSION}.zip"
STAGING="dist/staging"

rm -rf "$APP_DIR" "$STAGING"
mkdir -p launcher dist

echo "-> Kompiluji .app wrapper..."
osacompile -o "$APP_DIR" launcher-src/installer.applescript

echo "-> Kopíruji instalátor dovnitř appky..."
mkdir -p "$APP_DIR/Contents/Resources/src"
cp -R src/* "$APP_DIR/Contents/Resources/src/"
find "$APP_DIR/Contents/Resources/src" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$APP_DIR/Contents/Resources/src" -name "*.pyc" -delete

chmod +x "$APP_DIR/Contents/Resources/src/install.sh"
chmod +x "$APP_DIR/Contents/Resources/src/payload/transcribe_meeting.sh"

echo "-> Skládám ZIP pro distribuci..."
mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
cat > "$STAGING/PROSÍM SI PŘEČTI.txt" <<'EOF'
Meetily Watcher - instalace

1. Rozbal tenhle ZIP (pokud se nerozbalil sám).
2. Dvakrát klikni na "Nainstalovat Meetily Watcher".
3. macOS ti řekne, že appka je od "neznámého vývojáře" - to je v pořádku,
   je to appka od nás, ne cizí. Klikni pravým tlačítkem na appku -> Otevřít ->
   znovu Otevřít. Tohle musíš udělat jen napoprvé.
4. Dál už appka provede vším sama - jen odklikávej okýnka, která se objeví.
5. Instalace trvá 30-60 minut (stahují se AI modely). Nech to běžet na pozadí.

Pokud něco nepůjde, appka ti na konci ukáže, kam poslat log soubor.
EOF

rm -f "$OUT"
(cd "$STAGING" && zip -r -q "../$(basename "$OUT")" . -x "*.DS_Store")
rm -rf "$STAGING"

echo "Hotovo: $OUT"
echo "Tohle je ten JEDEN soubor ke stažení a spuštění."
