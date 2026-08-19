#!/usr/bin/env bash
# Terminal-only messaging for Fáze 0. Fáze 1 nahradí tyhle funkce osascript dialogy,
# aniž by se měnilo volání ze stages.sh/install.sh (proto jsou oddělené od logiky).

info() {
    echo "[INFO] $*"
}

warn() {
    echo "[VAROVÁNÍ] $*" >&2
}

fail_dialog() {
    local message="$1"
    echo ""
    echo "❌ $message"
    echo "Log najdeš v: $INSTALL_LOG"
    exit 1
}

success_dialog() {
    echo ""
    echo "✅ $*"
}
