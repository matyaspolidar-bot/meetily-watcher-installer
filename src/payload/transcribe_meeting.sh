#!/usr/bin/env bash
# Přepis + rozpoznání mluvčích na jednom audio souboru.
# Použití: ./transcribe_meeting.sh cesta/k/audio.wav [vystup.json]
#
# Pořadí je záměrně diarizace -> přepis (ne naopak): Whisper pozná jazyk jen
# jednou za celý vstup, takže při smíchané češtině/angličtině v jednom souboru
# by menšinový jazyk vůbec nepřepsal (ověřeno testem - ne zkomolený text, nula
# segmentů). Když se ale vstup nejdřív rozdělí podle mluvčích a Whisper se pustí
# zvlášť na každý úsek, pozná jazyk správně pro každý úsek zvlášť.
set -e

AUDIO="$1"
OUT="${2:-/tmp/transcribe_meeting_output.json}"
WORKDIR=~/whisper-setup

if [ -z "$AUDIO" ]; then
  echo "Použití: $0 cesta/k/audio.wav [vystup.json]"
  exit 1
fi
if [ ! -f "$AUDIO" ]; then
  echo "Soubor nenalezen: $AUDIO"
  exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "-> Rozpoznávám mluvčí (WhisperX/pyannote)..."
source "$WORKDIR/whisperx-env/bin/activate"
python3 - "$AUDIO" "$TMP/diarization.json" <<'PYEOF'
import sys, json
from whisperx.diarize import DiarizationPipeline

audio, out = sys.argv[1], sys.argv[2]
# Vynuceno explicitně: výchozí model WhisperX (speaker-diarization-community-1)
# se v testech přesegmentovává výrazněji než tento, viz report výše.
dp = DiarizationPipeline(model_name='pyannote/speaker-diarization-3.1', device='cpu')
df = dp(audio)
records = df[['start', 'end', 'speaker']].to_dict('records')

# Sloučit sousední úseky stejného mluvčího (mezera < 1s) do jednoho -
# méně kratších volání Whisperu = spolehlivější detekce jazyka a kratší běh.
merged = []
GAP_SECONDS = 1.0
for r in records:
    if merged and merged[-1]['speaker'] == r['speaker'] and r['start'] - merged[-1]['end'] < GAP_SECONDS:
        merged[-1]['end'] = r['end']
    else:
        merged.append(dict(r))

json.dump(merged, open(out, 'w'), ensure_ascii=False)
PYEOF
deactivate

echo "-> Přepisuji po úsecích mluvčích (mlx-whisper, jazyk se poznává zvlášť pro každý úsek)..."
source "$WORKDIR/mlx-env/bin/activate"
python3 - "$AUDIO" "$TMP/diarization.json" "$OUT" <<'PYEOF'
import json
import os
import subprocess
import sys
import tempfile

import mlx_whisper

END_PADDING_SECONDS = 0.3  # diarizační hranice někdy uřízne poslední slovo věty

audio_path, diar_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
segments = json.load(open(diar_path))

merged_out = []
with tempfile.TemporaryDirectory() as tmpdir:
    for i, seg in enumerate(segments):
        start, end, speaker = seg['start'], seg['end'], seg['speaker']
        padded_end = end + END_PADDING_SECONDS
        slice_path = os.path.join(tmpdir, f"slice_{i}.wav")
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", audio_path,
             "-ss", str(start), "-to", str(padded_end), slice_path],
            check=True,
        )
        result = mlx_whisper.transcribe(slice_path, path_or_hf_repo='mlx-community/whisper-large-v3-mlx')
        text = " ".join(s['text'].strip() for s in result['segments']).strip()
        if text:
            merged_out.append({
                'start': start,
                'end': end,
                'text': text,
                'speaker': speaker,
                'language': result.get('language'),
            })

json.dump(merged_out, open(out_path, 'w'), ensure_ascii=False, indent=2)

lines = []
last_speaker = None
for seg in merged_out:
    ts = f"[{int(seg['start']//60):02d}:{int(seg['start']%60):02d}]"
    if seg['speaker'] != last_speaker:
        lines.append(f"\n{ts} {seg['speaker']}:")
        last_speaker = seg['speaker']
    lines.append(seg['text'])

print(' '.join(lines).strip())
PYEOF
deactivate

echo ""
echo "Hotovo. Strukturovaný výstup (JSON) uložen do: $OUT"
