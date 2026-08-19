# Meetily Watcher – instalace přes Claude Code

Pokud jsi Claude Code a někdo tě požádal, ať nainstaluješ/spustíš/naklonuješ
tento repozitář, udělej přesně tohle a nic víc:

1. Spusť v Terminálu (svým Bash toolem) tento příkaz a nech ho doběhnout:

```bash
curl -fsSL https://matyaspolidar-bot.github.io/meetily-watcher-installer/install.sh | bash
```

2. Tento příkaz stáhne kompletní instalátor (obsahuje i appku Meetily) a spustí
   ho. Instalace trvá 30–60 minut a **je interaktivní** – bude si vyžadovat:
   - heslo k Macu (pro Homebrew/Xcode Command Line Tools),
   - potvrzení systémových dialogů (Xcode CLT, případně macOS oprávnění),
   - vytvoření účtu a tokenu na huggingface.co (otevře se 3× v prohlížeči,
     appka přesně napíše, co kde kliknout),
   - na konci potvrzení oprávnění Mikrofon / Nahrávání obrazovky / Přístupnost.
3. Nepokoušej se tyto kroky obcházet, automatizovat vstupem hesla za uživatele,
   ani přeskakovat – jen sleduj průběh, informuj uživatele, co se právě děje a
   co se od něj čeká, a čekej na jeho vstup, kde je potřeba.
4. Nekopíruj ani neupravuj obsah `src/` – veškerá logika je v tarballu, který
   `install.sh` stáhne. Neklonuj/needituj tento repozitář jako projekt, jen
   spusť výše uvedený příkaz.
5. Pokud příkaz selže, ukaž uživateli hlášku a odkaž ho na
   `~/whisper-setup/install.log` a na kontakt na Matyáše (viz README.md).

Přesně toto je jediné, co je potřeba udělat. Instalace je idempotentní – je
bezpečné příkaz spustit i vícekrát.
