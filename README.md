# Project Kanban — vernieuwing schoolwebsite

Een HTML-kanbanbord met de 39 bestaande taken uit de oorspronkelijke Excel.

## Meteen gebruiken

1. **Aanbevolen:** publiceer `index.html` via GitHub Pages en open de `https://...`-link. Open het HTML-bestand niet door erop te dubbelklikken als je wilt dat wijzigingen permanent worden bewaard; sommige browsers blokkeren opslag voor lokale `file://`-bestanden.
2. Klik op een taak om de omschrijving, status of eigenaar te wijzigen. Klik op **Opslaan**.
3. Klik op **Nieuwe taak** om een taak toe te voegen. Zowel het taaklabel als de omschrijving zijn verplicht.
4. De site controleert nu of opslag echt is gelukt. Als de browser opslag blokkeert, verschijnt een blijvende waarschuwing in plaats van een misleidende melding dat alles is opgeslagen.
5. Klik op **Back-up** om alle taken, statussen, toegewezen teamleden en het archief als JSON te downloaden. Bewaar geregeld een kopie.
6. Kies **Importeren** om een JSON-back-up te herstellen. Bestaande taken die niet in de back-up voorkomen worden niet automatisch verwijderd.
7. Klik op **CSV** om een CSV-bestand voor Excel te exporteren.

**Belangrijk:** zonder gedeelde database zijn wijzigingen alleen zichtbaar in de browser waarin ze zijn gemaakt. Voor directe synchronisatie tussen teamleden volg je de optionele Supabase-configuratie hieronder.

## Publiceren met GitHub Pages

1. Maak op GitHub een repository aan en upload `index.html`, `initial_tasks.json`, `README.md` en `supabase_setup.sql` naar de hoofdmap.
2. Open **Settings → Pages**.
3. Kies **Deploy from a branch**, de branch `main` en map `/(root)`, en klik **Save**.
4. Open de URL die GitHub Pages toont. Ga niet verder met de lokaal geopende HTML als opslag niet beschikbaar is.

GitHub Pages-websites zijn publiek toegankelijk op het internet. Zet dus geen wachtwoorden of andere gevoelige gegevens in de websitebestanden.

## Optioneel: gedeelde live-synchronisatie

1. Maak een project op [Supabase](https://supabase.com/).
2. Voer de volledige inhoud van `supabase_setup.sql` uit in **SQL Editor**.
3. Maak teamaccounts aan via Supabase Authentication; laat openbare registratie uitgeschakeld.
4. Kopieer de **Project URL** en de **publishable/anon key** uit Project Settings → API.
5. Open `index.html` en vul die in bij `const SUPABASE_CONFIG = { url: "", anonKey: "" };`.
6. Upload de aangepaste HTML opnieuw naar GitHub Pages en log in via de gepubliceerde site.

Gebruik nooit een `service_role`- of secret key in de browsercode. De meegeleverde SQL stelt Row Level Security in zodat alleen ingelogde teamaccounts taken kunnen lezen en aanpassen.

## Inbegrepen functies

- Kolommen **Te doen**, **In behandeling** en **Afgerond**.
- Automatisch overzicht van actieve taken, lopende taken, afgeronde taken en taken zonder eigenaar.
- Zoeken en filters op requirement en teamlid.
- Taken maken, bewerken, verslepen, archiveren en herstellen.
- JSON-back-up/import en CSV-export.
- Optionele Supabase-login, gedeelde database-opslag en live-updates.

## Beginstand

De app start met 39 taken: 38 op **To-Do**, 0 **In behandeling**, 1 **Afgerond**. Alle eigenaars starten zoals in het oorspronkelijke Excel-bestand; er wordt geen eigenaar verzonnen.
