#!/usr/bin/env bash
# Maximálně přesné, podrobné dialogy - přesné URL adresy vypsané v textu (appka
# je i tak sama otevře), přesný název každého tlačítka, na které se má kliknout.
# Cíl: uživatel to najde na první dobrou, nikde nemusí sám hledat/googlit.

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

    ok_dialog "Teď potřebujeme přístup k Hugging Face - bezplatné službě, která hostuje AI model pro rozpoznávání mluvčích. Bude to trvat cca 5 minut, 4 kroky.

Za chvíli se otevře stránka:
huggingface.co/join

Pokud tam ještě nemáš účet: vyplň e-mail, uživatelské jméno a heslo, klikni na zelené tlačítko 'Create Account', a potvrď účet klikem na odkaz, který ti přijde e-mailem.

Pokud účet už máš, jen se přihlas (tlačítko 'Log In' vpravo nahoře) a klikni Pokračovat."
    open "https://huggingface.co/join"
    ok_dialog "Pokračuj, až budeš mít účet založený/přihlášený (potvrzený e-mail, pokud jsi ho zakládal/a teď poprvé)."

    local model_num=1
    local model_count="${#HF_GATED_MODELS[@]}"
    for model in "${HF_GATED_MODELS[@]}"; do
        open "https://huggingface.co/$model"
        ok_dialog "Krok ${model_num} ze ${model_count}: otevřela se stránka modelu

huggingface.co/${model}

Sjeď na téhle stránce dolů, uvidíš formulář 'You need to agree to share your contact information'. Vyplň ho (stačí zaškrtnout souhlas, pokud tam je) a klikni na zelené tlačítko s textem 'Agree and access repository'.

Až se ti pod tím tlačítkem objeví zelená fajfka / potvrzení přístupu, klikni tady na Pokračovat."
        model_num=$((model_num + 1))
    done

    open "https://huggingface.co/settings/tokens/new"
    ok_dialog "Poslední krok - vytvoření tokenu (hesla pro appku k Hugging Face). Otevřela se stránka:

huggingface.co/settings/tokens/new

Udělej přesně tohle:
1. Do pole 'Name' napiš cokoliv, třeba 'meetily'.
2. U 'Token type' vyber možnost 'Read' (ne 'Write' ani 'Fine-grained').
3. Klikni na modré tlačítko 'Create token' dole.
4. Objeví se okno s tokenem (dlouhý text začínající 'hf_...'). Klikni na ikonku kopírování vedle něj (nebo ho označ a Cmd+C).

Token si NIKAM neukládej ani nikomu neposílej - hned po zkopírování klikni Pokračovat a vlož ho v dalším okně."

    local token
    token=$(osascript -e 'display dialog "Vlož zkopírovaný token (Cmd+V) - musí začínat hf_:" default answer "" with title "Meetily Watcher"' -e 'text returned of result' 2>/dev/null || true)

    if [[ ! "$token" =~ ^hf_ ]]; then
        fail_dialog "Token nevypadá platně - měl by začínat 'hf_' a nic víc. Zkontroluj, že jsi zkopíroval/a celý token (huggingface.co/settings/tokens), a spusť appku znovu."
    fi

    "$WHISPERX_VENV/bin/huggingface-cli" login --token "$token" || fail_dialog "Přihlášení k Hugging Face selhalo - zkontroluj internetové připojení a spusť appku znovu."
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
