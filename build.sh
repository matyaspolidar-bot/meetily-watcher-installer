#!/usr/bin/env bash
# Fáze 1 tenhle skript rozšíří o: vytvoření .app wrapperu (launcher/) přes osacompile,
# zabalení vendor/Meetily-<verze>.dmg a výsledný ZIP do dist/.
# Fáze 0: zatím jen zabalí src/ do zipu pro test na jiném stroji přes Terminal.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

VERSION="0.0.1-faze0"
OUT="dist/meetily-watcher-installer-${VERSION}.zip"

mkdir -p dist
rm -f "$OUT"
zip -r -q "$OUT" src -x "*.pyc" -x "__pycache__/*"
echo "Zabaleno: $OUT"
echo "Spuštění na cílovém stroji (Fáze 0, vyžaduje Terminal - Fáze 1 tohle odstraní):"
echo "  unzip $(basename "$OUT") && ./src/install.sh"
