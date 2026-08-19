# meetily-watcher-installer

Konsolidovaný instalátor Whisper/Meetily watcher pipeline pro Addvery konzultanty.
Interní vývojové repo - koncový uživatel dostává jen ZIP z `dist/` (viz `build.sh`).

## Stav

**Fáze 0 (hotovo):** jeden `install.sh`, idempotentní stages, admin-rights preflight,
všech 5 watcher skriptů se kopíruje atomicky (opravuje dřívější mezeru, kdy
`export_transcript.py`/`apply_speaker_names.py` chyběly v instalátoru), jediná
kanonická plist šablona vždy s `EnvironmentVariables`/PATH fixem (opravuje
produkční bug s nenalezeným ffmpeg v launchd).

**Fáze 1 (další):** `.app` wrapper (Automator/`osacompile`) kolem `install.sh`,
`osascript` dialogy místo `read -p`, ZIP jako jediný soubor ke stažení - žádný
Terminal pro koncového uživatele.

Viz plán: `~/.claude/plans/hele-m-l-jsem-call-elegant-whisper.md`

## Struktura

```
src/install.sh              # entrypoint (Fáze 0: spouští se v Terminálu)
src/lib/stages.sh           # idempotentní instalační kroky
src/lib/gui.sh              # zprávy uživateli (Fáze 1 nahradí za osascript dialogy)
src/lib/hf_onboarding.sh    # HuggingFace účet/licence/token flow
src/payload/                # skripty a plist šablona, co se kopírují na cílový stroj
build.sh                    # sbalí src/ do dist/*.zip
```

## Zdroj pravdy / archiv

Původní instalace byla bash skript vložený v `whisper-kombo-doporuceni.html` a
`mlx-whisper-whisperx-zjisteni.html` (viz `/Users/matypoli/Desktop/claude-workspace/`).
Tyhle dokumenty se archivují jako rozhodovací záznam (proč `pyannote/speaker-diarization-3.1`
místo community-1, proč dva oddělené venvy, historie ffmpeg-PATH bugu) - už nejsou
spustitelným zdrojem, tím je tohle repo.
