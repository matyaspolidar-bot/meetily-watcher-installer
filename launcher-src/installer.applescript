-- Zdroj pro "Nainstalovat Meetily Watcher.app" (viz build.sh, ktery to kompiluje
-- pres osacompile a dolepi vedle sebe src/ se skutecnym instalatorem).
-- Zadny Terminal se uzivateli nikdy neukaze - "do shell script" bezi na pozadi,
-- veskera komunikace jde pres nativni dialogy volane primo z install.sh.
on run
    set appPath to POSIX path of (path to me)
    set installScript to appPath & "Contents/Resources/src/install.sh"
    -- install.sh uz sam ukazuje vlastni hezky dialog na uspech/neuspech (viz gui.sh) -
    -- kdyby skoncil s chybovym kodem, "do shell script" by jinak navic vyhodil svuj
    -- vlastni osklivy systemovy chybovy dialog s celym logem jako textem. Potlaceno.
    try
        do shell script "/bin/bash " & quoted form of installScript
    end try
end run
