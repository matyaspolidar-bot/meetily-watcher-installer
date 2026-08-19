#!/usr/bin/env python3
"""Běží pořád na pozadí. Jakmile detekuje, že se Meetily právě spustilo
(přechod ze 'neběží' na 'běží'), zeptá se uživatele dialogem, jestli chce
začít nahrávat, a pokud ano, klikne na tlačítko nahrávání za něj."""

import subprocess
import time
from datetime import datetime
from pathlib import Path

POLL_INTERVAL_SECONDS = 2
WINDOW_READY_DELAY_SECONDS = 2
RECOVER_DIALOG_MAX_WAIT_SECONDS = 300
CLICK_SCRIPT = Path(__file__).parent / "click_meetily_record.applescript"

ASK_DIALOG_SCRIPT = (
    'display dialog "Chcete začít nahrávat schůzku?" '
    'buttons {"Ne", "Ano"} default button "Ano" with title "Meetily"'
)

# Meetily po startu občas nejdřív samo ukáže "Recover Interrupted Meetings"
# (když se minulá nahrávka pořádně nezastavila) - dokud tohle okno visí přes
# appku, hledání tlačítka nahrávání selže. Musíme počkat, až ho uživatel zavře.
RECOVER_DIALOG_CHECK_SCRIPT = """
tell application "System Events"
    tell process "meetily"
        try
            set allUI to entire contents of window 1
            repeat with el in allUI
                try
                    if role of el is "AXHeading" and name of el is "Recover Interrupted Meetings" then
                        return "yes"
                    end if
                end try
            end repeat
        end try
        return "no"
    end tell
end tell
"""


def log(message: str) -> None:
    print(f"[{datetime.now().isoformat(timespec='seconds')}] {message}", flush=True)


def is_meetily_running() -> bool:
    return subprocess.run(["pgrep", "-x", "meetily"], capture_output=True).returncode == 0


def is_recover_dialog_showing() -> bool:
    result = subprocess.run(
        ["osascript", "-e", RECOVER_DIALOG_CHECK_SCRIPT], capture_output=True, text=True
    )
    return result.stdout.strip() == "yes"


def wait_for_recover_dialog_to_close() -> None:
    waited = 0
    announced = False
    while is_recover_dialog_showing():
        if not announced:
            log("Appka ukazuje 'Recover Interrupted Meetings' - čekám, až to uživatel zavře.")
            announced = True
        if waited >= RECOVER_DIALOG_MAX_WAIT_SECONDS:
            log("Okno 'Recover Interrupted Meetings' visí moc dlouho, vzdávám to pro tentokrát.")
            return
        time.sleep(POLL_INTERVAL_SECONDS)
        waited += POLL_INTERVAL_SECONDS


def ask_and_maybe_record() -> None:
    log("Meetily se spustilo, zobrazuji dialog...")
    result = subprocess.run(
        ["osascript", "-e", ASK_DIALOG_SCRIPT], capture_output=True, text=True
    )
    log(f"Odpověď dialogu: stdout={result.stdout.strip()!r} stderr={result.stderr.strip()!r}")
    if "button returned:Ano" in result.stdout:
        log("Uživatel klikl Ano, spouštím click_meetily_record.applescript...")
        click_result = subprocess.run(
            ["osascript", str(CLICK_SCRIPT)], capture_output=True, text=True
        )
        log(
            f"Výsledek kliknutí: returncode={click_result.returncode} "
            f"stdout={click_result.stdout.strip()!r} stderr={click_result.stderr.strip()!r}"
        )
    else:
        log("Uživatel klikl Ne (nebo dialog selhal), nic neklikám.")


def main() -> None:
    log("Hlídač spuštěn, čekám na start Meetily...")
    was_running = is_meetily_running()
    while True:
        time.sleep(POLL_INTERVAL_SECONDS)
        now_running = is_meetily_running()
        if now_running and not was_running:
            log("Zaznamenán start Meetily.")
            time.sleep(WINDOW_READY_DELAY_SECONDS)
            wait_for_recover_dialog_to_close()
            ask_and_maybe_record()
        was_running = now_running


if __name__ == "__main__":
    main()
