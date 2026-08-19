#!/usr/bin/env bash
# Meetily Watcher - konsolidovaný instalátor.
# Spouští se z .app wrapperu (viz build.sh) - konzultant nikdy neotevírá Terminal sám,
# veškerá komunikace jde přes nativní macOS dialogy (lib/gui.sh, lib/hf_onboarding.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHISPER_SETUP_DIR="$HOME/whisper-setup"
INSTALL_LOG="$WHISPER_SETUP_DIR/install.log"

mkdir -p "$WHISPER_SETUP_DIR"
exec > >(tee -a "$INSTALL_LOG") 2>&1
echo "=== Meetily Watcher instalace: $(date) ==="

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
    echo "1.0.0" > "$WHISPER_SETUP_DIR/.install-version"
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
