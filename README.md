# BrigantiRP JobsCreator (FiveM)

Resource FiveM con interfaccia NUI moderna per creare e gestire job in modo rapido.

## Funzionalità

- UI glassmorphism con sidebar e anteprima live.
- Sezioni: dati base, gradi/stipendi, zone operative, opzioni avanzate.
- Gestione dinamica di gradi e zone.
- Export JSON, import JSON e copy clipboard.
- Salvataggio locale automatico (`localStorage`).
- Salvataggio server-side JSON in `data/jobs.json`.
- Sync automatico su `qbx_core/shared/jobs.lua` ad ogni creazione/aggiornamento job.
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
- Ogni salvataggio crea/aggiorna anche il job in `qbx_core/shared/jobs.lua` (blocco marcato `JOBSCREATOR:BEGIN/END`).
- Nel JSON vengono salvati: job, grades, zones (garage, bossmenu, stash, armory, ecc.), opzioni e webhook.
- Se `ox_inventory` è avviato, le zone `stash` vengono registrate automaticamente come stash runtime.
- Se `qbx_core` non è in percorso standard, puoi forzare il path con convar:
  ```cfg
  set jobscreator_qbx_jobs_path "C:/path/to/resources/[qbx]/qbx_core/shared/jobs.lua"
  ```

## Note

Questo pacchetto salva lato server su JSON e sincronizza il file jobs di Qbox.
