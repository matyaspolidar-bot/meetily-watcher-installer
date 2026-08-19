# meetily-watcher-installer

Konsolidovaný instalátor Whisper/Meetily watcher pipeline pro Addvery konzultanty.
Interní vývojové repo - koncový uživatel dostává jen ZIP z `dist/` (viz `build.sh`).

## Stav: hotovo (v1.0.0)

Jeden ZIP, jedna appka na dvojklik. Konzultant: stáhne, spustí, proklikává jen
nevyhnutelné kroky (HF účet/token, systémová povolení macOS). Vše ostatní
(Homebrew, Python, AI modely, Meetily samotná appka, oba watcher démoni)
appka nainstaluje sama.

- **Fáze 0:** jeden `install.sh`, idempotentní stages, admin-rights preflight,
  všechny watcher skripty se kopírují atomicky (opravuje dřívější mezeru, kdy
  `export_transcript.py`/`apply_speaker_names.py` chyběly), jediná kanonická
  plist šablona s `EnvironmentVariables`/PATH fixem (produkční ffmpeg bug).
- **Fáze 1:** `.app` wrapper (`osacompile`) kolem `install.sh`, `osascript`
  dialogy místo `read -p`/Terminálu.
- **Fáze 2:** HF onboarding s přesnými popisy každého kroku (přesný text
  tlačítka, viditelná URL adresa přímo v dialogu, ne jen automatické otevření).
- **Fáze 3:** appka Meetily (MIT licence, ověřeno) se instaluje automaticky
  z přibaleného `src/vendor/*.dmg` - žádné ruční stahování/drag-and-drop.
- **Fáze 5:** staré HTML návody archivovány s banerem do `docs/decision-log/`,
  přidán `.install-version` marker pro budoucí update-check.

**Vědomě mimo v1.0.0:** podepsaný `.pkg` (čeká na Apple Developer účet),
kalendářové automatické spouštění nahrávání bez dotazu (samostatný projekt -
dnešní automatický dialog "Chcete začít nahrávat?" při zapnutí appky už ale
řeší "jedno tlačítko").

Plán: `~/.claude/plans/hele-m-l-jsem-call-elegant-whisper.md`

## Struktura

```
src/install.sh              # entrypoint
src/lib/stages.sh           # idempotentní instalační kroky
src/lib/gui.sh              # osascript dialogy (vítání, úspěch/neúspěch)
src/lib/hf_onboarding.sh    # HuggingFace účet/licence/token flow
src/payload/                # skripty a plist šablony kopírované na cílový stroj
src/vendor/                 # Meetily.dmg (stahuje download.sh, negituje se)
launcher-src/                # zdroj .app wrapperu (osacompile)
docs/decision-log/          # archivované staré HTML návody
build.sh                    # sestaví launcher/*.app a zabalí dist/*.zip
```

## Sestavení

```
bash build.sh
```

Automaticky doskáhne `src/vendor/meetily_0.4.0_aarch64.dmg` (přes `gh` CLI,
pokud chybí) a vytvoří `dist/meetily-watcher-installer-<verze>.zip` - to je
soubor k distribuci konzultantům (Slack / sdílený disk).

## Zdroj pravdy / archiv

Původní instalace byla bash skript vložený v `whisper-kombo-doporuceni.html` a
`mlx-whisper-whisperx-zjisteni.html`. Obě dokumenty jsou teď archivované
s bannerem v `docs/decision-log/` jako záznam technických rozhodnutí (proč
`pyannote/speaker-diarization-3.1` místo community-1, proč dva oddělené venvy,
historie ffmpeg-PATH bugu) - už nejsou spustitelným zdrojem, tím je tohle repo.
