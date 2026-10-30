# Project Kanban — vernieuwing schoolwebsite

Een HTML-kanbanbord met de 39 bestaande taken uit de oorspronkelijke Excel.

## Meteen gebruiken

1. **Aanbevolen:** publiceer `index.html` via GitHub Pages en open de `https://...`-link. Open het HTML-bestand niet door erop te dubbelklikken als je wilt dat wijzigingen permanent worden bewaard; sommige browsers blokkeren opslag voor lokale `file://`-bestanden.
2. Klik op een taak om de omschrijving, status of teamleden te wijzigen. Meerdere teamleden kun je met komma's scheiden. Klik op **Opslaan**.
3. Klik op **Nieuwe taak** of ergens in het lege vak van een kolom om een taak toe te voegen. Vanuit een lege kolom krijgt de nieuwe taak meteen de status van die kolom. Een actief teamlid- of onderdeelfilter wordt ook automatisch ingevuld. Onderdeel- en taaknummers worden automatisch gecombineerd, bijvoorbeeld `1.1`; vul alleen de omschrijving in.
4. Gebruik de pijltjes op een taak om die één status vooruit of terug te zetten, of blijf de kaart naar een andere kolom slepen. De snelkoppelingen onder het overzicht springen meteen naar een status.
5. De taken scrollen binnen hun eigen kolom. Zodra je het einde van een takenlijst bereikt, kun je verder scrollen op de pagina. Onderaan elke kolom staat een subtiele knop om daar een taak toe te voegen.
6. De site controleert nu of opslag echt is gelukt. Als de browser opslag blokkeert, verschijnt een blijvende waarschuwing in plaats van een misleidende melding dat alles is opgeslagen.
7. Klik op **🗑 Prullenmand** om taken in de prullenmand te bekijken. Zet taken terug of verwijder ze permanent; permanent verwijderen kan niet ongedaan worden gemaakt. **Prullenmand leegmaken** verwijdert alle taken in de prullenmand.
8. Klik op het **K-logo** om het menu met back-up, importeren en CSV te openen. In datzelfde menu kun je, als je bent ingelogd, je weergavenaam aanpassen of uitloggen.
9. Kies **Back-up downloaden** om alle taken, statussen, toegewezen teamleden en de prullenmand als JSON te bewaren.
10. Kies **Back-up importeren** om een JSON-back-up te herstellen. Bestaande taken die niet in de back-up voorkomen worden niet automatisch verwijderd.
11. Kies **CSV downloaden** om een CSV-bestand voor Excel te exporteren.

**Belangrijk:** zonder Supabase-project zijn wijzigingen alleen zichtbaar in de browser waarin ze zijn gemaakt. Om het bord met het team te delen, moet je eerst de onderstaande Supabase-configuratie uitvoeren.

## Publiceren met GitHub Pages

1. Maak op GitHub een repository aan en upload `index.html`, `initial_tasks.json`, `README.md` en `supabase_setup.sql` naar de hoofdmap.
2. Open **Settings → Pages**.
3. Kies **Deploy from a branch**, de branch `main` en map `/(root)`, en klik **Save**.
4. Open de URL die GitHub Pages toont. Ga niet verder met de lokaal geopende HTML als opslag niet beschikbaar is.

GitHub Pages-websites zijn publiek toegankelijk op het internet. Zet dus geen wachtwoorden of andere gevoelige gegevens in de websitebestanden.

## Gedeelde live-synchronisatie instellen

1. Maak een project aan op [Supabase](https://supabase.com/) en wacht tot de database klaar is.
2. Voer de volledige inhoud van `supabase_setup.sql` uit in **SQL Editor**. Dit maakt de beveiligde tabellen aan, schakelt live-updates in en voegt de 39 oorspronkelijke taken toe zonder bestaande taken te overschrijven. Het script zet ook bestaande requirementnummers om naar de bijbehorende requirementnaam, werkt bestaande taaknummers bij naar de vorm `1.1` en koppelt bestaande taaktoewijzingen waar mogelijk aan teamaccounts. Oude handmatig ingevoerde namen die niet bij een account horen worden verwijderd. Als je de eerdere versie al hebt uitgevoerd, voer het bijgewerkte script opnieuw uit om teamprofielen, accounttoewijzingen, requirementnamen, taaknummering, permanent verwijderen en beveiligde online-aanwezigheid toe te voegen. Bestaande taken blijven behouden. De RLS op `realtime.messages` wordt door Supabase beheerd en staat al aan; het script maakt alleen policies aan en probeert die tabel niet te wijzigen.
3. Maak teamaccounts aan via **Authentication → Users**. Houd openbare registraties uitgeschakeld; alleen accounts die je aanmaakt of uitnodigt kunnen inloggen. Nieuwe accounts verschijnen automatisch in de teamledenlijst. Iedereen kan via **Mijn profiel** zelf een weergavenaam instellen; op taken wijs je teamleden toe door ze in de lijst aan te vinken.
4. Kopieer de **Project URL** en de **publishable key** (of legacy **anon key**) uit **Project Settings → API**.
5. Vul deze waarden in bij `SUPABASE_CONFIG` bovenaan het script in `index.html`. De huidige projectconfiguratie is al ingevuld.
6. Publiceer de aangepaste `index.html` opnieuw via GitHub Pages. Open daarna de gepubliceerde HTTPS-link en log in met een teamaccount. Teamleden gebruiken dezelfde link en hun eigen account.
7. Als je al taken in de lokale browser hebt aangepast, download daar eerst via **Back-up** een JSON-bestand. Log in op het gedeelde bord en gebruik **Importeren** om die taken toe te voegen of bij te werken. Taken die niet in de back-up staan blijven behouden.

Na deze configuratie worden wijzigingen in Supabase opgeslagen en via realtime-updates aan ingelogde teamleden getoond. De online-lijst toont teamleden met het bord open; per teamlid toont het overzicht hoeveel van alle actieve taken diegene heeft afgerond, als percentage en aantal. Een taak met meerdere teamleden telt voor ieder van hen mee. Taken in de prullenmand tellen niet mee. Toewijzingen zijn aan accounts gekoppeld, dus een wijziging van de weergavenaam verandert niet wie aan de taak is toegewezen.

Gebruik nooit een `service_role`- of secret key in de browsercode. De publishable/anon key is bedoeld voor gebruik in de browser; Row Level Security in de meegeleverde SQL zorgt ervoor dat alleen ingelogde teamaccounts taken kunnen lezen, aanpassen en permanent verwijderen.

## Inbegrepen functies

- Kolommen **Te doen**, **In behandeling** en **Afgerond**.
- Automatisch overzicht van actieve taken, lopende taken, afgeronde taken en taken zonder eigenaar.
- Genummerde onderdelen en taaknummers in de vorm `1.1`, met zoeken en filters op onderdeel en teamlid.
- Taken maken, bewerken, verslepen, met pijltjes tussen statussen verplaatsen, naar de prullenmand verplaatsen, terugzetten en permanent verwijderen.
- Meerdere teamleden aan één taak toewijzen en per teamlid het percentage van alle actieve taken volgen dat is afgerond.
- Supabase-teamaccounts automatisch als teamleden beschikbaar maken, met een eigen instelbare weergavenaam.
- Latte-, kampvuur- en nachtblauwthema met opgeslagen voorkeur, plus een realtime-lijst van ingelogde teamleden.
- JSON-back-up/import en CSV-export.
- Supabase-login, gedeelde database-opslag en live-updates (na configuratie).

## Beginstand

De app start met 39 taken: 38 op **To-Do**, 0 **In behandeling**, 1 **Afgerond**. Alle eigenaars starten zoals in het oorspronkelijke Excel-bestand; er wordt geen eigenaar verzonnen.
