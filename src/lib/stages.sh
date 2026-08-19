#!/usr/bin/env bash
# Idempotentní instalační kroky. Každá stage_* funkce nejdřív zkontroluje,
# jestli už je splněná, a pokud ano, vrátí se hned - bezpečné znovuspuštění
# celého install.sh po jakékoliv chybě.

WHISPER_SETUP_DIR="$HOME/whisper-setup"
MLX_VENV="$WHISPER_SETUP_DIR/mlx-env"
WHISPERX_VENV="$WHISPER_SETUP_DIR/whisperx-env"
PLIST_TARGET="$HOME/Library/LaunchAgents/com.addvery.meetily-watcher.plist"
LAUNCHD_LABEL="com.addvery.meetily-watcher"
PROMPT_PLIST_TARGET="$HOME/Library/LaunchAgents/com.addvery.meetily-launch-prompt.plist"
PROMPT_LAUNCHD_LABEL="com.addvery.meetily-launch-prompt"

check_admin_rights() {
    # Homebrew/Xcode CLT instalace vyžadují admin práva. Ověřit HNED na začátku,
    # ať uživatel bez adminu neztratí 20 minut stahováním, které stejně selže.
    if dscl . -read /Groups/admin GroupMembership 2>/dev/null | grep -qw "$USER"; then
        info "Admin práva: OK"
        return 0
    fi
    fail_dialog "Tenhle účet nemá na Macu admin práva. Instalace vyžaduje možnost zadat heslo pro Homebrew/Xcode. Kontaktuj IT nebo Matyáše, ať ti admin práva přidělí, a pak zkus instalaci znovu."
}

check_disk_space() {
    local min_gb="${1:-10}"
    local available_gb
    available_gb=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [ "$available_gb" -lt "$min_gb" ]; then
        fail_dialog "Na disku je jen ${available_gb}GB volného místa, instalace potřebuje aspoň ${min_gb}GB (modely pro rozpoznávání řeči). Uvolni místo a zkus to znovu."
    fi
    info "Volné místo na disku: ${available_gb}GB - OK"
}

stage_check_meetily_app() {
    if [ -d "/Applications/meetily.app" ]; then
        info "Meetily.app: už nainstalováno"
        return 0
    fi
    # Nekopírujeme .dmg appky Meetily do našeho ZIPu (cizí distribuční práva) -
    # místo toho nasměrujeme na oficiální stránku a počkáme, až si ji uživatel
    # sám nainstaluje (drag-and-drop do /Applications, jak appka sama vyžaduje).
    osascript -e 'display dialog "Ještě předtím potřebujeme appku Meetily samotnou - tenhle instalátor řeší jen automatické zpracování nahrávek, ne appku na nahrávání.

Za chvíli se otevře oficiální stránka ke stažení. Stáhni verzi pro Mac (.dmg), otevři ji a přetáhni Meetily do složky Aplikace. Pak se sem vrať a klikni Pokračovat." buttons {"Otevřít stránku"} default button "Otevřít stránku" with title "Meetily Watcher"' > /dev/null
    open "https://github.com/Zackriya-Solutions/meetily/releases"

    while [ ! -d "/Applications/meetily.app" ]; do
        local answer
        answer=$(osascript -e 'display dialog "Až budeš mít Meetily nainstalované v Aplikacích, klikni Pokračovat." buttons {"Pokračovat"} default button "Pokračovat" with title "Meetily Watcher"' 2>/dev/null || true)
        if [ ! -d "/Applications/meetily.app" ]; then
            osascript -e 'display dialog "Meetily.app jsem v Aplikacích ještě nenašel - zkontroluj, že je přetažené přesně do složky Aplikace, a zkus to znovu." buttons {"OK"} default button "OK" with title "Meetily Watcher"' > /dev/null
        fi
    done
    info "Meetily.app: nainstalováno"
}

stage_xcode_clt() {
    if xcode-select -p &>/dev/null; then
        info "Xcode Command Line Tools: už nainstalováno"
        return 0
    fi
    info "Instaluji Xcode Command Line Tools (objeví se systémové okno, potvrď instalaci)..."
    xcode-select --install
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    info "Xcode Command Line Tools: hotovo"
}

stage_homebrew() {
    if command -v brew &>/dev/null; then
        info "Homebrew: už nainstalováno"
        return 0
    fi
    info "Instaluji Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || fail_dialog "Instalace Homebrew selhala."
    info "Homebrew: hotovo"
}

stage_pyenv_ffmpeg() {
    brew list pyenv &>/dev/null || brew install pyenv || fail_dialog "Instalace pyenv selhala."
    brew list ffmpeg &>/dev/null || brew install ffmpeg || fail_dialog "Instalace ffmpeg selhala."
    info "pyenv + ffmpeg: OK"
}

stage_python_3_13_2() {
    if pyenv versions --bare 2>/dev/null | grep -qx "3.13.2"; then
        info "Python 3.13.2 (pyenv): už nainstalováno"
        return 0
    fi
    pyenv install -s 3.13.2 || fail_dialog "Instalace Python 3.13.2 přes pyenv selhala."
    info "Python 3.13.2 (pyenv): hotovo"
}

stage_venv_mlx() {
    if [ -x "$MLX_VENV/bin/python3" ] && "$MLX_VENV/bin/python3" -c "import mlx_whisper" &>/dev/null; then
        info "mlx-env: už existuje a funguje"
        return 0
    fi
    mkdir -p "$WHISPER_SETUP_DIR"
    python3 -m venv "$MLX_VENV"
    "$MLX_VENV/bin/pip" install --quiet --upgrade pip mlx-whisper \
        || fail_dialog "Instalace mlx-whisper selhala."
    info "mlx-env: hotovo"
}

stage_venv_whisperx() {
    if [ -x "$WHISPERX_VENV/bin/python3" ] && "$WHISPERX_VENV/bin/python3" -c "import whisperx" &>/dev/null; then
        info "whisperx-env: už existuje a funguje"
        return 0
    fi
    mkdir -p "$WHISPER_SETUP_DIR"
    "$(pyenv root)/versions/3.13.2/bin/python3" -m venv "$WHISPERX_VENV"
    "$WHISPERX_VENV/bin/pip" install --quiet --upgrade pip whisperx pyannote-audio \
        || fail_dialog "Instalace whisperx/pyannote-audio selhala."
    info "whisperx-env: hotovo"
}

stage_copy_payload_scripts() {
    # KLÍČOVÁ OPRAVA: všechny soubory se kopírují najednou, ne postupně ručně.
    local payload_dir
    payload_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../payload" && pwd)"
    mkdir -p "$WHISPER_SETUP_DIR"
    cp "$payload_dir/meetily_watcher.py" \
       "$payload_dir/meetily_autowatch.py" \
       "$payload_dir/export_transcript.py" \
       "$payload_dir/apply_speaker_names.py" \
       "$payload_dir/transcribe_meeting.sh" \
       "$payload_dir/click_meetily_record.applescript" \
       "$payload_dir/meetily_launch_prompt.py" \
       "$WHISPER_SETUP_DIR/" \
        || fail_dialog "Kopírování skriptů selhalo."
    chmod +x "$WHISPER_SETUP_DIR/transcribe_meeting.sh"
    info "Watcher skripty: zkopírováno"
}

stage_write_plist() {
    local payload_dir
    payload_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../payload" && pwd)"
    sed "s|__HOME__|$HOME|g" "$payload_dir/com.addvery.meetily-watcher.plist.template" > "$PLIST_TARGET" \
        || fail_dialog "Zápis plistu selhal."
    launchctl unload "$PLIST_TARGET" &>/dev/null || true
    launchctl load "$PLIST_TARGET" || fail_dialog "Načtení launchd úlohy selhalo."
    info "launchd watcher: nainstalováno a spuštěno"
}

stage_write_launch_prompt_plist() {
    local payload_dir
    payload_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../payload" && pwd)"
    sed "s|__HOME__|$HOME|g" "$payload_dir/com.addvery.meetily-launch-prompt.plist.template" > "$PROMPT_PLIST_TARGET" \
        || fail_dialog "Zápis plistu pro dialog při zapnutí Meetily selhal."
    launchctl unload "$PROMPT_PLIST_TARGET" &>/dev/null || true
    launchctl load "$PROMPT_PLIST_TARGET" || fail_dialog "Načtení launchd úlohy pro dialog při zapnutí selhalo."
    info "Dialog 'Chcete začít nahrávat?': nainstalováno a spuštěno"
    warn "Potřebuje jednorázově povolit Přístupnost (Accessibility) pro System Events/osascript v Nastavení > Soukromí a zabezpečení."
}

wait_for_process() {
    # pgrep místo `launchctl list` - když install.sh běží přes "do shell script"
    # (appka na dvojklik), je ve zvláštním bootstrap kontextu, kde launchctl list
    # nemusí vidět GUI LaunchAgenty, i když reálně běží. pgrep hledá napříč celým
    # systémem a na tom kontextu nezávisí.
    local pattern="$1"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -f "$pattern" &>/dev/null && return 0
        sleep 1
    done
    return 1
}

stage_verify() {
    local ok=1
    "$MLX_VENV/bin/python3" -c "import mlx_whisper" &>/dev/null || { warn "mlx_whisper se nedá importovat"; ok=0; }
    "$WHISPERX_VENV/bin/python3" -c "import whisperx" &>/dev/null || { warn "whisperx se nedá importovat"; ok=0; }
    # meetily-watcher běží jen jednou za 120s (StartInterval, ne KeepAlive) - pgrep by ho
    # mohl chytit i minout podle náhody. Kontrolujeme radši, že je plist na místě a validní.
    plutil -lint "$PLIST_TARGET" &>/dev/null || { warn "plist watcheru není validní"; ok=0; }
    # meetily-launch-prompt běží nepřetržitě (KeepAlive) - pgrep ho spolehlivě najde.
    wait_for_process "meetily_launch_prompt.py" || { warn "hlídač dialogu při zapnutí neběží"; ok=0; }
    [ "$ok" -eq 1 ]
}
