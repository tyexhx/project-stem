# Project Kanban — vernieuwing schoolwebsite

Een HTML-kanbanbord met de 39 bestaande taken uit de oorspronkelijke Excel.

## Meteen gebruiken

1. **Aanbevolen:** publiceer `index.html` via GitHub Pages en open de `https://...`-link. Open het HTML-bestand niet door erop te dubbelklikken als je wilt dat wijzigingen permanent worden bewaard; sommige browsers blokkeren opslag voor lokale `file://`-bestanden.
2. Klik op een taak om de omschrijving, status of teamleden te wijzigen. Meerdere teamleden kun je met komma's scheiden. Klik op **Opslaan**.
3. Klik op **Nieuwe taak** om een taak toe te voegen. Zowel het taaklabel als de omschrijving zijn verplicht.
4. De site controleert nu of opslag echt is gelukt. Als de browser opslag blokkeert, verschijnt een blijvende waarschuwing in plaats van een misleidende melding dat alles is opgeslagen.
5. Klik op **Back-up** om alle taken, statussen, toegewezen teamleden en het archief als JSON te downloaden. Bewaar geregeld een kopie.
6. Kies **Importeren** om een JSON-back-up te herstellen. Bestaande taken die niet in de back-up voorkomen worden niet automatisch verwijderd.
7. Klik op **CSV** om een CSV-bestand voor Excel te exporteren.

**Belangrijk:** zonder Supabase-project zijn wijzigingen alleen zichtbaar in de browser waarin ze zijn gemaakt. Om het bord met het team te delen, moet je eerst de onderstaande Supabase-configuratie uitvoeren.

## Publiceren met GitHub Pages

1. Maak op GitHub een repository aan en upload `index.html`, `initial_tasks.json`, `README.md` en `supabase_setup.sql` naar de hoofdmap.
2. Open **Settings → Pages**.
3. Kies **Deploy from a branch**, de branch `main` en map `/(root)`, en klik **Save**.
4. Open de URL die GitHub Pages toont. Ga niet verder met de lokaal geopende HTML als opslag niet beschikbaar is.

GitHub Pages-websites zijn publiek toegankelijk op het internet. Zet dus geen wachtwoorden of andere gevoelige gegevens in de websitebestanden.

## Gedeelde live-synchronisatie instellen

1. Maak een project aan op [Supabase](https://supabase.com/) en wacht tot de database klaar is.
2. Voer de volledige inhoud van `supabase_setup.sql` uit in **SQL Editor**. Dit maakt de beveiligde tabel aan, schakelt live-updates in en voegt de 39 oorspronkelijke taken toe zonder bestaande taken te overschrijven. Als je de eerdere versie al hebt uitgevoerd, voer het bijgewerkte script opnieuw uit om de kolom voor meerdere teamleden en beveiligde online-aanwezigheid toe te voegen. Bestaande taken blijven behouden.
3. Maak teamaccounts aan via **Authentication → Users**. Houd openbare registraties uitgeschakeld; alleen accounts die je aanmaakt of uitnodigt kunnen inloggen.
4. Kopieer de **Project URL** en de **publishable key** (of legacy **anon key**) uit **Project Settings → API**.
5. Vul deze waarden in bij `SUPABASE_CONFIG` bovenaan het script in `index.html`. De huidige projectconfiguratie is al ingevuld.
6. Publiceer de aangepaste `index.html` opnieuw via GitHub Pages. Open daarna de gepubliceerde HTTPS-link en log in met een teamaccount. Teamleden gebruiken dezelfde link en hun eigen account.
7. Als je al taken in de lokale browser hebt aangepast, download daar eerst via **Back-up** een JSON-bestand. Log in op het gedeelde bord en gebruik **Importeren** om die taken toe te voegen of bij te werken. Taken die niet in de back-up staan blijven behouden.

Na deze configuratie worden wijzigingen in Supabase opgeslagen en via realtime-updates aan ingelogde teamleden getoond. De online-lijst toont teamleden met het bord open; voortgang is het aantal afgeronde actieve taken gedeeld door alle actieve taken die aan dat teamlid zijn toegewezen. Een taak met meerdere teamleden telt voor ieder van hen mee. Archief-taken tellen niet mee.

Gebruik nooit een `service_role`- of secret key in de browsercode. De publishable/anon key is bedoeld voor gebruik in de browser; Row Level Security in de meegeleverde SQL zorgt ervoor dat alleen ingelogde teamaccounts taken kunnen lezen en aanpassen.

## Inbegrepen functies

- Kolommen **Te doen**, **In behandeling** en **Afgerond**.
- Automatisch overzicht van actieve taken, lopende taken, afgeronde taken en taken zonder eigenaar.
- Zoeken en filters op requirement en teamlid.
- Taken maken, bewerken, verslepen, archiveren en herstellen.
- Meerdere teamleden aan één taak toewijzen en voortgang per teamlid volgen.
- Donkere modus met opgeslagen voorkeur en een realtime-lijst van ingelogde teamleden.
- JSON-back-up/import en CSV-export.
- Supabase-login, gedeelde database-opslag en live-updates (na configuratie).

## Beginstand

De app start met 39 taken: 38 op **To-Do**, 0 **In behandeling**, 1 **Afgerond**. Alle eigenaars starten zoals in het oorspronkelijke Excel-bestand; er wordt geen eigenaar verzonnen.
