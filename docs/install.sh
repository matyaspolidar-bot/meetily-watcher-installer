#!/usr/bin/env bash
# Meetily Watcher - bootstrap instalátor.
# Stažení přes curl (ne přes prohlížeč) nedostává com.apple.quarantine,
# takže Gatekeeper se vůbec nespustí - žádné "Open Anyway" klikání.
set -euo pipefail

RELEASE_URL="https://github.com/matyaspolidar-bot/meetily-watcher-installer/releases/latest/download/meetily-watcher-payload.tar.gz"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo ""
echo "== Meetily Watcher - instalace =="
echo ""
echo "Tohle je normální Terminal okno, ne chyba. Uvidíš tady postupně vypisovat"
echo "text - to je průběh instalace, nech to běžet."
echo ""
echo "-> Stahuji instalátor..."

if ! curl -fsSL -o "$TMPDIR/payload.tar.gz" "$RELEASE_URL"; then
  echo ""
  echo "Stažení se nepovedlo. Zkontroluj připojení k internetu a zkus to znovu."
  echo "Pokud problém přetrvá, napiš Matyášovi."
  exit 1
fi

echo "-> Rozbaluji..."
tar -xzf "$TMPDIR/payload.tar.gz" -C "$TMPDIR"

echo "-> Spouštím instalaci (trvá 30-60 minut, nezavírej tohle okno)..."
echo ""

# caffeinate zabrání usnutí Macu během dlouhého neobsluhovaného stahování modelů.
caffeinate -is bash "$TMPDIR/meetily-watcher/install.sh"
