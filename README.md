# BrigantiRP JobsCreator (FiveM)

Resource FiveM con interfaccia NUI moderna per creare e gestire job in modo rapido.

## Funzionalità

- UI glassmorphism con sidebar e anteprima live.
- Sezioni: dati base, gradi/stipendi, zone operative, opzioni avanzate.
- Gestione dinamica di gradi e zone.
- Export JSON, import JSON e copy clipboard.
- Salvataggio locale automatico (`localStorage`).
- Salvataggio server-side JSON in `data/jobs.json` (compatibile con setup Qbox).
- Registrazione automatica stash su `ox_inventory` quando una zona è di tipo `stash`.
- Apertura con comando `/jobcreator` (keybind `F7`).

## Installazione

1. Copia la cartella nella tua `resources`.
2. Aggiungi in `server.cfg`:
   ```cfg
   ensure brigantirp-jobscreator
   ```
3. Avvia il server e usa `/jobcreator`.

## Qbox / Persistenza

- Ogni salvataggio crea/aggiorna il job nel file `data/jobs.json` della resource.
- Nel JSON vengono salvati: job, grades, zones (garage, bossmenu, stash, armory, ecc.), opzioni e webhook.
- Se `ox_inventory` è avviato, le zone `stash` vengono registrate automaticamente come stash runtime.

## Note

Questo pacchetto salva ora lato server su file JSON.
Se vuoi sincronizzare direttamente su DB/framework (es. tabelle job di Qbox), puoi aggiungere un adapter SQL nel `server.lua`.
