# Project Kanban — vernieuwing schoolwebsite

Een eenvoudige HTML-kanban die de 39 taken uit de oorspronkelijke Excel overneemt. Er hoeft niets geïnstalleerd of gebouwd te worden.

## Meteen gebruiken

1. Open `index.html` in een browser, of upload het bestand naar GitHub.
2. Wijzig een taak door op de kaart te klikken. Versleep kaarten tussen de drie kolommen om de status te veranderen.
3. Wijzigingen worden automatisch bewaard in de huidige browser.
4. Klik op **Back-up** om alle taken, statussen, toegewezen teamleden en het archief als JSON te downloaden. Bewaar die back-up geregeld.
5. Kies **Importeren** om een back-up in te lezen. Taken met hetzelfde nummer worden bijgewerkt; taken die niet in het bestand staan blijven behouden. Zo wordt onbedoeld gegevensverlies beperkt.
6. Klik op **CSV** om een CSV-bestand voor Excel te exporteren. De sneltoets `Ctrl+Shift+E` (Windows) of `Cmd+Shift+E` (Mac) werkt ook.

**Belangrijk:** zonder gedeelde database zijn wijzigingen alleen zichtbaar in de browser waarin ze zijn gemaakt. Om wijzigingen te delen, kan iemand een JSON-back-up exporteren en de anderen die laten importeren. Voor directe synchronisatie tussen teamleden volg je de optionele configuratie hieronder.

## Publiceren met GitHub Pages

1. Maak op GitHub een repository aan. Upload `index.html`, `initial_tasks.json`, `README.md` en `supabase_setup.sql` naar de hoofdmap.
2. Open **Settings → Pages** in de repository.
3. Kies bij **Build and deployment** de bron **Deploy from a branch**.
4. Kies de branch `main` en map `/(root)` en klik **Save**.
5. Wacht tot GitHub de website heeft gepubliceerd. De URL verschijnt op de Pages-pagina.

GitHub Pages-websites zijn publiek toegankelijk op het internet. Zet dus geen wachtwoorden, privégegevens of andere gevoelige informatie in de websitebestanden. Zie de officiële [GitHub Pages-documentatie](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

## Optioneel: gedeelde live-synchronisatie voor het team

Dit vraagt eenmalige configuratie van Supabase. Daarna zien ingelogde teamleden updates in elkaars browser.

1. Maak een project aan op [Supabase](https://supabase.com/).
2. Open **SQL Editor**, plak de volledige inhoud van `supabase_setup.sql` en voer uit. Dat maakt de tabel, toegangsregels en de 39 oorspronkelijke taken aan. Het seed-gedeelte overschrijft geen bestaande taaknummers.
3. Open Supabase **Authentication → Users** en maak een account voor ieder teamlid aan. Schakel openbare gebruikersregistratie uit; maak zelf de accounts aan of nodig alleen de bedoelde teamleden uit.
4. Ga in Supabase naar **Project Settings → API** en kopieer de **Project URL** en de **publishable key** (bij oudere projecten heet die mogelijk `anon` key).
5. Open `index.html` en zoek de regel `const SUPABASE_CONFIG = { url: "", anonKey: "" };`. Vul de URL en publiceerbare/anon key in. Gebruik **nooit** de `service_role`- of een secret key in browsercode.
6. Upload de aangepaste `index.html` naar GitHub. Herlaad de Pages-website en log in met het teamaccount.
7. Als SQL een fout meldt bij `alter publication supabase_realtime add table`, controleer dan of `public.tasks` al voor Realtime is ingeschakeld. Als de tabel al is toegevoegd, hoef je die regel niet opnieuw uit te voeren.

De database gebruikt Row Level Security: alleen ingelogde accounts mogen taken lezen of aanpassen. Houd de accounts beperkt tot jullie team en deel geen inloggegevens. De Supabase publishable/anon key is bedoeld voor gebruik in de frontend wanneer de toegangsregels correct zijn ingesteld; de service-role/secret key mag nooit in frontendcode terechtkomen. Lees ook de officiële [Supabase-beveiligingsdocumentatie](https://supabase.com/docs/guides/database/secure-data) en [Realtime-documentatie](https://supabase.com/docs/guides/realtime/postgres-changes).

## Functies

- Drie kolommen: **Te doen**, **In behandeling**, **Afgerond**.
- Bovenaan: totaal actieve taken, lopend werk, afgeronde taken, taken zonder eigenaar en voortgangspercentage.
- Zoeken op nummer, requirement, taaklabel, omschrijving en eigenaar.
- Filters op requirement en toegewezen teamlid.
- Nieuwe taken toevoegen, bestaande taken aanpassen en taken archiveren/herstellen.
- JSON back-up/import (inclusief archief) en CSV-export.
- Optionele Supabase-login, database-opslag en live-updates.

## Beginstand

De webapp start met alle 39 oorspronkelijke taken: 38 op **To-Do**, 0 **In behandeling**, 1 **Afgerond**. Er zijn in de oorspronkelijke Excel geen eigenaars ingevuld; de app vult die niet zelf in.
