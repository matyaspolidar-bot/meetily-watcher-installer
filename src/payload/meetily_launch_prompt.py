#!/usr/bin/env python3
"""Běží pořád na pozadí. Jakmile detekuje, že se Meetily právě spustilo
(přechod ze 'neběží' na 'běží'), zeptá se uživatele dialogem, jestli chce
začít nahrávat, a pokud ano, klikne na tlačítko nahrávání za něj."""

import subprocess
import time
from pathlib import Path

POLL_INTERVAL_SECONDS = 2
WINDOW_READY_DELAY_SECONDS = 2
CLICK_SCRIPT = Path(__file__).parent / "click_meetily_record.applescript"

ASK_DIALOG_SCRIPT = (
    'display dialog "Chcete začít nahrávat schůzku?" '
    'buttons {"Ne", "Ano"} default button "Ano" with title "Meetily"'
)


def is_meetily_running() -> bool:
    return subprocess.run(["pgrep", "-x", "meetily"], capture_output=True).returncode == 0


def ask_and_maybe_record() -> None:
    result = subprocess.run(
        ["osascript", "-e", ASK_DIALOG_SCRIPT], capture_output=True, text=True
    )
    if "button returned:Ano" in result.stdout:
        subprocess.run(["osascript", str(CLICK_SCRIPT)])


def main() -> None:
    was_running = is_meetily_running()
    while True:
        time.sleep(POLL_INTERVAL_SECONDS)
        now_running = is_meetily_running()
        if now_running and not was_running:
            time.sleep(WINDOW_READY_DELAY_SECONDS)
            ask_and_maybe_record()
        was_running = now_running


if __name__ == "__main__":
    main()
