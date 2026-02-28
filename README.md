# Lunar Style JobCreator (FiveM)

Resource FiveM con interfaccia NUI moderna per creare e gestire job in modo rapido.

## Funzionalità

- UI glassmorphism con sidebar e anteprima live.
- Sezioni: dati base, gradi/stipendi, zone operative, opzioni avanzate.
- Gestione dinamica di gradi e zone.
- Export JSON, import JSON e copy clipboard.
- Salvataggio locale automatico (`localStorage`).
- Apertura con comando `/jobcreator` (keybind `F7`).

## Installazione

1. Copia la cartella nella tua `resources`.
2. Aggiungi in `server.cfg`:
   ```cfg
   ensure lunar-style-jobcreator
   ```
3. Avvia il server e usa `/jobcreator`.

## Note

Questo pacchetto è una base estetica e funzionale in stile creator avanzato.
Per persistenza server-side (DB) aggiungi una `server.lua` che salvi il JSON su file o tabella SQL.
