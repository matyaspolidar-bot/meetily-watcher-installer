# meetily-watcher-installer

Konsolidovaný instalátor Whisper/Meetily watcher pipeline pro Addvery konzultanty.
Koncový uživatel primárně pošle repo Claude Code (nebo Claude chatu) zprávou
(viz `CLAUDE.md`) - vyžaduje to funkční Claude. Bez Claude dostane jeden
příkaz (`curl | bash`) z landing page `docs/index.html` (GitHub Pages) jako
záložení postup - žádný ZIP, žádné klikání přes Gatekeeper.

## Stav: hotovo (v1.1.4)

Jeden příkaz do Terminálu, žádné klikání přes Nastavení systému. Soubory
stažené přes `curl`/`tar` nedostávají `com.apple.quarantine` (na rozdíl od
stažení přes prohlížeč), takže se Gatekeeper vůbec nespustí - stejný princip
jako Homebrew/Rustup. Nevyžaduje Apple Developer účet ani notarizaci.
Primárně: konzultant pošle Claude Code (nebo Claude chatu) odkaz na repo -
`CLAUDE.md` v rootu instruuje Claude, aby spustil tentýž `curl | bash`
příkaz sám a instalaci hlídal. Vyžaduje to, aby konzultant už měl Claude
nastavený. Bez Claude: otevře Terminal, vloží příkaz, proklikává jen
nevyhnutelné kroky (HF účet/token, systémová povolení macOS). Vše ostatní
appka nainstaluje sama.

**Repo běží pod GitHub účtem `matyaspolidar-bot`** - přidání emailu
`matyas.polidar@addvery.com` k tomuto účtu (GitHub.com → Settings → Emails →
Add email, potvrdit klikem na verifikační email) je čistě účtová věc a
nevyžaduje žádnou změnu URL ani kódu, protože všechny odkazy používají
username, ne email.

- **v1.1.1-v1.1.4:** čtyři bugy odhalené reálným usability testem (konzultant
  bez zkušeností s AI, instalace spuštěná přes Path A - zprávou do Claude, ne
  ručně v Terminálu):
  - **v1.1.1:** `hf_onboarding.sh` volal `huggingface-cli` přes systémový
    PATH, kde binárka není - opraveno na volání přímo z `whisperx-env`.
  - **v1.1.2:** `stage_verify` hlásil falešnou chybu, když LaunchAgent
    naběhl pomaleji než v ručním Terminálu (typicky když `install.sh`
    spouští Claude Code) - přechod z `launchctl load` na
    `launchctl bootstrap`/`kickstart -k`, čekací okno 10s → 30s.
  - **v1.1.3:** zámek proti souběžnému spuštění `install.sh` (`mkdir`-based,
    s detekcí zastaralého zámku podle PID) - dvě souběžná spuštění (např. dvě
    poslané zprávy Claude) by si mohla šlápnout na vytváření venvs/mountění DMG.
  - **v1.1.4:** `.install-version` marker dřív natvrdo `1.0.0` - teď čte
    skutečnou verzi ze souboru `VERSION`, který do stage přibalí `build.sh`.

- **v1.1.0:** distribuce přepsána z `.app`/ZIP na `docs/install.sh` (bootstrap
  stažený přes curl) + `docs/index.html` (landing page) + GitHub Release
  tarball (`build.sh` teď dělá `tar` + `gh release create` místo
  `osacompile`/`codesign`/`zip`). Instalační pipeline (`src/`) je funkčně
  identická jako v1.0.0.

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

**Vědomě mimo v1.1.0:** kalendářové automatické spouštění nahrávání bez dotazu
(samostatný projekt - dnešní automatický dialog "Chcete začít nahrávat?" při
zapnutí appky už ale řeší "jedno tlačítko"). `.app`/AppleScript instalátor
(`launcher-src/installer.applescript`) zůstává v repu jako nepoužívaný
artefakt z v1.0.0, odpojený z aktivního `build.sh` pipeline.

Plán: `~/.claude/plans/hele-ten-error-ktery-melodic-volcano.md`

## Struktura

```
src/install.sh              # entrypoint (spouští se přímo v Terminálu)
src/lib/stages.sh           # idempotentní instalační kroky
src/lib/gui.sh              # osascript dialogy (vítání, úspěch/neúspěch)
src/lib/hf_onboarding.sh    # HuggingFace účet/licence/token flow
src/payload/                # skripty a plist šablony kopírované na cílový stroj
src/vendor/                 # Meetily.dmg (stahuje download.sh, negituje se)
docs/install.sh              # bootstrap - stáhne + rozbalí + spustí install.sh
docs/index.html              # landing page (GitHub Pages) s copy-paste příkazem
docs/decision-log/          # archivované staré HTML návody
launcher-src/                # (nepoužívané) zdroj .app wrapperu z v1.0.0
build.sh                    # sbalí src/ do tarballu a nahraje jako GitHub Release
```

## Sestavení a vydání nové verze

```
bash build.sh
```

Automaticky doskáhne `src/vendor/meetily_0.4.0_aarch64.dmg` (přes `gh` CLI,
pokud chybí), sbalí `src/*` do `dist/meetily-watcher-payload.tar.gz` a nahraje
ho jako asset GitHub Release (`gh release create`). Landing page odkazuje na
stabilní `.../releases/latest/download/...` URL, která se mezi verzemi nemění -
konzultantův příkaz se tak nikdy nemusí posílat znovu.

## Zdroj pravdy / archiv

Původní instalace byla bash skript vložený v `whisper-kombo-doporuceni.html` a
`mlx-whisper-whisperx-zjisteni.html`. Obě dokumenty jsou teď archivované
s bannerem v `docs/decision-log/` jako záznam technických rozhodnutí (proč
`pyannote/speaker-diarization-3.1` místo community-1, proč dva oddělené venvy,
historie ffmpeg-PATH bugu) - už nejsou spustitelným zdrojem, tím je tohle repo.
