#!/usr/bin/env bash
# Fáze 1: skutečné macOS dialogy místo terminálového textu - konzultant
# spouští appku na dvojklik, žádné okno Terminálu nikdy neuvidí.

info() {
    echo "[INFO] $*"
}

warn() {
    echo "[VAROVÁNÍ] $*" >&2
}

show_welcome_dialog() {
    osascript -e 'display dialog "Vítej! Instalace potrvá cca 30-60 minut (stahují se AI modely, ~5-6GB).

Občas se zeptá na heslo k Macu (Homebrew/Xcode) a 3x otevře prohlížeč (Hugging Face). Nech to celou dobu běžet, i když to bude chvíli vypadat, že se nic neděje." buttons {"Pokračovat"} default button "Pokračovat" with title "Meetily Watcher - instalace"' \
        > /dev/null
}

fail_dialog() {
    local message="$1"
    echo ""
    echo "❌ $message"
    echo "Log najdeš v: $INSTALL_LOG"
    local answer
    answer=$(osascript -e "display dialog \"❌ ${message//\"/\'}

Něco se nepovedlo. Pošli prosím tenhle soubor Matyášovi:
$INSTALL_LOG\" buttons {\"Otevřít log\", \"Zavřít\"} default button \"Zavřít\" with title \"Meetily Watcher - chyba\"" 2>/dev/null || true)
    if [[ "$answer" == *"Otevřít log"* ]]; then
        open -e "$INSTALL_LOG"
    fi
    exit 1
}

success_dialog() {
    echo ""
    echo "✅ $*"
    osascript -e "display dialog \"✅ $*\" buttons {\"OK\"} default button \"OK\" with title \"Meetily Watcher\"" \
        > /dev/null
}
