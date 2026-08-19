#!/usr/bin/env bash
# Přepis + rozpoznání mluvčích na jednom audio souboru.
# Použití: ./transcribe_meeting.sh cesta/k/audio.wav [vystup.json]
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

echo "-> Přepisuji (mlx-whisper, large-v3)..."
source "$WORKDIR/mlx-env/bin/activate"
python3 - "$AUDIO" "$TMP/transcript.json" <<'PYEOF'
import sys, json, mlx_whisper
audio, out = sys.argv[1], sys.argv[2]
result = mlx_whisper.transcribe(audio, path_or_hf_repo='mlx-community/whisper-large-v3-mlx')
json.dump(result['segments'], open(out, 'w'), ensure_ascii=False)
PYEOF
deactivate

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
json.dump(records, open(out, 'w'), ensure_ascii=False)
PYEOF
deactivate

echo "-> Spojuji přepis a mluvčí..."
python3 - "$TMP/transcript.json" "$TMP/diarization.json" "$OUT" <<'PYEOF'
import sys, json

transcript = json.load(open(sys.argv[1]))
diar = json.load(open(sys.argv[2]))
out_path = sys.argv[3]

def find_speaker(seg):
    best, best_overlap = None, 0
    for d in diar:
        overlap = min(seg['end'], d['end']) - max(seg['start'], d['start'])
        if overlap > best_overlap:
            best_overlap, best = overlap, d['speaker']
    return best or 'SPEAKER_?'

merged = []
for seg in transcript:
    merged.append({
        'start': seg['start'],
        'end': seg['end'],
        'text': seg['text'].strip(),
        'speaker': find_speaker(seg),
    })

json.dump(merged, open(out_path, 'w'), ensure_ascii=False, indent=2)

lines = []
last_speaker = None
for seg in merged:
    ts = f"[{int(seg['start']//60):02d}:{int(seg['start']%60):02d}]"
    if seg['speaker'] != last_speaker:
        lines.append(f"\n{ts} {seg['speaker']}:")
        last_speaker = seg['speaker']
    lines.append(seg['text'])

print(' '.join(lines).strip())
PYEOF

echo ""
echo "Hotovo. Strukturovaný výstup (JSON) uložen do: $OUT"
