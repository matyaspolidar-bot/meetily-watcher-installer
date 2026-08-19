#!/usr/bin/env bash
# Fáze 0: terminálová verze (read -p). Fáze 2 nahradí prompty za osascript dialogy
# a otevírání tabů udělá sekvenčně s blokujícím dialogem mezi nimi - rozhraní
# stage_hf_onboarding() se nemění, jen jeho vnitřek.

HF_GATED_MODELS=(
    "pyannote/speaker-diarization-3.1"
    "pyannote/segmentation-3.0"
    "pyannote/speaker-diarization-community-1"
)

stage_hf_onboarding() {
    if [ -s "$HOME/.cache/huggingface/token" ]; then
        info "HuggingFace token: už nastaveno"
        return 0
    fi

    info "Potřebujeme přístup k Hugging Face (bezplatná služba hostující AI model pro rozpoznávání mluvčích)."
    info "Pokud ještě nemáš účet, založ si ho zdarma zde:"
    open "https://huggingface.co/join"
    read -r -p "Stiskni Enter, až budeš mít účet a budeš přihlášený... "

    for model in "${HF_GATED_MODELS[@]}"; do
        info "Otevírám licenční stránku: $model - klikni na 'Agree and access repository'."
        open "https://huggingface.co/$model"
        read -r -p "Stiskni Enter, až klikneš na 'Agree and access repository'... "
    done

    info "Teď vytvoř token s oprávněním 'Read'."
    open "https://huggingface.co/settings/tokens/new"
    local token
    read -r -p "Vlož token (začíná hf_): " token

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
