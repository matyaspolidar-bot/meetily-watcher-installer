#!/usr/bin/env bash
# Fáze 1: dialogy místo read -p - appka na dvojklik nemá Terminal, kam by se dalo psát.

HF_GATED_MODELS=(
    "pyannote/speaker-diarization-3.1"
    "pyannote/segmentation-3.0"
    "pyannote/speaker-diarization-community-1"
)

ok_dialog() {
    osascript -e "display dialog \"$1\" buttons {\"Pokračovat\"} default button \"Pokračovat\" with title \"Meetily Watcher\"" > /dev/null
}

stage_hf_onboarding() {
    if [ -s "$HOME/.cache/huggingface/token" ]; then
        info "HuggingFace token: už nastaveno"
        return 0
    fi

    ok_dialog "Za chvíli se otevřou stránky v prohlížeči. Jde o bezplatnou službu Hugging Face, která hostuje AI model potřebný pro rozpoznávání mluvčích.

Pokud ještě nemáš účet, založ si ho (zdarma) - odkaz se otevře taky."
    open "https://huggingface.co/join"
    ok_dialog "Pokračuj, až budeš mít účet a budeš přihlášený."

    for model in "${HF_GATED_MODELS[@]}"; do
        open "https://huggingface.co/$model"
        ok_dialog "Otevřela se stránka modelu:
$model

Klikni na ní na zelené tlačítko 'Agree and access repository', pak klikni Pokračovat."
    done

    open "https://huggingface.co/settings/tokens/new"
    ok_dialog "Otevřela se stránka pro vytvoření tokenu.

Vytvoř token s oprávněním 'Read', pak ho zkopíruj (Cmd+C). Klikni Pokračovat a v dalším okně ho vlož."

    local token
    token=$(osascript -e 'display dialog "Vlož token (začíná hf_):" default answer "" with title "Meetily Watcher"' -e 'text returned of result' 2>/dev/null || true)

    if [[ ! "$token" =~ ^hf_ ]]; then
        fail_dialog "Token nevypadá platně (měl by začínat 'hf_'). Spusť instalaci znovu."
    fi

    huggingface-cli login --token "$token" || fail_dialog "Přihlášení k Hugging Face selhalo."
    info "HuggingFace token: nastaveno"
}

stage_download_models() {
    "$MLX_VENV/bin/python3" - <<'PYEOF'
from huggingface_hub import snapshot_download
snapshot_download("mlx-community/whisper-large-v3-mlx")
PYEOF
    "$WHISPERX_VENV/bin/python3" - <<'PYEOF'
from pyannote.audio import Pipeline
Pipeline.from_pretrained("pyannote/speaker-diarization-3.1")
PYEOF
    info "Modely: staženo (nebo už byly v cache)"
}
