#!/usr/bin/env bash
# Meetily Watcher - konsolidovaný instalátor (Fáze 0: terminálový běh).
# Fáze 1 tohle zabalí do .app wrapperu, aby uživatel nikdy neotevíral Terminal sám.
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

info "Vítej! Instalace potrvá cca 30-60 minut (stahují se AI modely, ~5-6GB)."
info "Občas se zeptá na heslo k Macu (Homebrew/Xcode) a 3x otevře prohlížeč (Hugging Face)."

check_admin_rights
check_disk_space 10

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
    success_dialog "Hotovo! Meetily Watcher je nainstalovaný a běží na pozadí."
else
    fail_dialog "Instalace doběhla, ale kontrola na konci našla problém - podívej se výš do logu."
fi
