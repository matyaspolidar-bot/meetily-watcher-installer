#!/usr/bin/env bash
# Meetily Watcher - konsolidovaný instalátor.
# Spouští se z docs/install.sh (curl | bash) přímo v Terminálu - GUI dialogy
# (lib/gui.sh, lib/hf_onboarding.sh) doplňují, ale samotný progress text teď
# konzultant vidí live přímo v Terminálu.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHISPER_SETUP_DIR="$HOME/whisper-setup"
INSTALL_LOG="$WHISPER_SETUP_DIR/install.log"

mkdir -p "$WHISPER_SETUP_DIR"
exec > >(tee -a "$INSTALL_LOG") 2>&1
echo "=== Meetily Watcher instalace: $(date) ==="
echo "(Vidíš tady běžet text - to je normální průběh instalace, nech to běžet.)"

# Zámek proti souběžnému spuštění (mkdir je atomický i na síťových FS).
# Zabraňuje dvěma instalacím najednou, které by si mohly šlápnout na
# vytváření venvs / mountění DMG.
LOCK_DIR="$WHISPER_SETUP_DIR/.install.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    other_pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
    if [ -n "$other_pid" ] && kill -0 "$other_pid" 2>/dev/null; then
        echo "Instalace už běží v jiném okně (PID $other_pid) - počkej, až doběhne, a zkus to pak znovu."
        exit 1
    fi
    echo "Nalezen zámek po předchozím nedokončeném běhu (proces už neběží) - přebírám ho."
    rm -rf "$LOCK_DIR"
    mkdir "$LOCK_DIR"
fi
echo $$ > "$LOCK_DIR/pid"
trap 'rm -rf "$LOCK_DIR"' EXIT

# shellcheck source=lib/gui.sh
source "$SCRIPT_DIR/lib/gui.sh"
# shellcheck source=lib/stages.sh
source "$SCRIPT_DIR/lib/stages.sh"
# shellcheck source=lib/hf_onboarding.sh
source "$SCRIPT_DIR/lib/hf_onboarding.sh"

trap 'fail_dialog "Instalace selhala na řádku $LINENO."' ERR

show_welcome_dialog

check_admin_rights
check_disk_space 10

stage_check_meetily_app

stage_xcode_clt
stage_homebrew
stage_pyenv_ffmpeg
stage_python_3_13_2
stage_venv_mlx
stage_venv_whisperx

stage_hf_onboarding
stage_download_models

stage_copy_payload_scripts
stage_write_plist
stage_write_launch_prompt_plist

if stage_verify; then
    cat "$SCRIPT_DIR/VERSION" 2>/dev/null > "$WHISPER_SETUP_DIR/.install-version" || echo "unknown" > "$WHISPER_SETUP_DIR/.install-version"
    success_dialog "Hotovo! Meetily Watcher je nainstalovaný a běží na pozadí."
    osascript -e 'display dialog "Poslední krok, nedá se odklikat automaticky - macOS se tě sám postupně zeptá na pár povolení:

• Mikrofon
• Nahrávání obrazovky (potřeba pro zvuk hovoru)
• Přístupnost (potřeba pro automatické spuštění nahrávání)

Klikni vždy Povolit/OK, jinak appka nebude fungovat. Otevři teď Meetily a zkus to." buttons {"Otevřít Meetily"} default button "Otevřít Meetily" with title "Meetily Watcher - poslední krok"' > /dev/null
    open -a meetily
else
    fail_dialog "Instalace doběhla, ale kontrola na konci našla problém - podívej se výš do logu."
fi
