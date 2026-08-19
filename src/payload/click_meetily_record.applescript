-- Klikne na tlačítko nahrávání v Meetily. Tlačítko nemá text (jen ikonka mikrofonu),
-- takže se hledá podle toho, že je to jediné tlačítko v okně kolem velikosti 48x48 -
-- žádné jiné tlačítko v appce tuhle velikost nemá (ověřeno na verzi 0.4.0).
-- Rozsah místo přesné hodnoty: naměřeno 48x48 i 49x48 podle velikosti okna.
tell application "meetily" to reopen
delay 1

tell application "System Events"
    tell process "meetily"
        set frontmost to true
        try
            set allUI to entire contents of window 1
        on error
            display notification "Meetily se nepodařilo otevřít." with title "Meetily Watcher"
            return
        end try

        set targetBtn to missing value
        repeat with el in allUI
            try
                if role of el is "AXButton" then
                    set sz to size of el
                    set w to item 1 of sz
                    set h to item 2 of sz
                    if w > 44 and w < 54 and h > 44 and h < 54 then
                        set targetBtn to el
                        exit repeat
                    end if
                end if
            end try
        end repeat

        if targetBtn is missing value then
            display notification "Nenašel jsem tlačítko nahrávání - spusť ho prosím ručně." with title "Meetily Watcher"
        else
            click targetBtn
        end if
    end tell
end tell
