-- Kanbanbord vernieuwing schoolwebsite — optionele gedeelde Supabase-opslag
-- Voer dit script uit in Supabase > SQL Editor; opnieuw uitvoeren is veilig voor bestaande taken.
-- RLS staat aan; alleen ingelogde accounts kunnen het bord lezen of wijzigen.
-- Maak teamaccounts aan via Supabase Auth en schakel openbare registraties uit.

create table if not exists public.tasks (
  id integer primary key,
  requirement text not null,
  task_code text not null,
  description text not null,
  status text not null check (status in ('To-Do', 'In behandeling', 'Afgerond')),
  assignee text not null default '',
  assignees text[] not null default '{}'::text[],
  sort_order integer not null default 0,
  archived boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.tasks
  add column if not exists assignees text[] not null default '{}'::text[];

update public.tasks
set assignees = array(
  select btrim(member)
  from unnest(string_to_array(regexp_replace(assignee, '\s*[,;]\s*', ',', 'g'), ',')) as names(member)
  where btrim(member) <> ''
)
where cardinality(assignees) = 0 and btrim(assignee) <> '';

alter table public.tasks enable row level security;
revoke all on table public.tasks from anon;
grant select, insert, update on table public.tasks to authenticated;

drop policy if exists "Signed-in team can read tasks" on public.tasks;
drop policy if exists "Signed-in team can add tasks" on public.tasks;
drop policy if exists "Signed-in team can update tasks" on public.tasks;
create policy "Signed-in team can read tasks" on public.tasks for select to authenticated using (true);
create policy "Signed-in team can add tasks" on public.tasks for insert to authenticated with check (true);
create policy "Signed-in team can update tasks" on public.tasks for update to authenticated using (true) with check (true);

-- Private Realtime access: only authenticated team accounts can see online presence.
-- Supabase manages realtime.messages and already enables RLS; do not alter that table.
drop policy if exists "Signed-in team can view kanban presence" on realtime.messages;
drop policy if exists "Signed-in team can publish kanban presence" on realtime.messages;
create policy "Signed-in team can view kanban presence" on realtime.messages
  for select to authenticated using (realtime.topic() = 'schoolwebsite-kanban-live');
create policy "Signed-in team can publish kanban presence" on realtime.messages
  for insert to authenticated with check (realtime.topic() = 'schoolwebsite-kanban-live');

-- Seed 39 oorspronkelijke taken. Bestaande taaknummers worden NIET overschreven,
-- dus dit script overschrijft geen later aangepaste status of eigenaar.
insert into public.tasks (id, requirement, task_code, description, status, assignee, sort_order, archived)
values
  (1, 'Projectuitvoering en oplevering', 'Taak 1', 'Analyse & Voorbereiding: Huidige site onderzoeken, knelpunten inventariseren en content verzamelen.', 'Afgerond', '', 1, false),
  (2, 'Beheer en Gebruiksvriendelijkheid', 'Taak 1', 'Onderzoeken van de huidige website om complexe beheerelementen te identificeren.', 'To-Do', '', 2, false),
  (3, 'Design, Layout en Schermresoluties', 'Taak 3', 'Opstellen van een stijlgids met schoolkleuren, lettertypes, iconen en huisstijl.', 'To-Do', '', 3, false),
  (4, 'Design, Layout en Schermresoluties', 'Taak 5', 'Inventariseren en stroomlijnen van de menustructuur (belangrijke info binnen 2 à 3 klikken).', 'To-Do', '', 4, false),
  (5, 'Schoolteam en Contact', 'Taak 3', 'Verzamelen, controleren en integreren van officiële links naar sociale-mediakanalen.', 'To-Do', '', 5, false),
  (6, 'Veiligheid, Juridisch en Formulieren', 'Taak 2', 'Controleren en vastleggen van beeldrechten, licenties en een procedure om foto''s eenvoudig te verwijderen.', 'To-Do', '', 6, false),
  (7, 'Visie, Sfeer en Content (Foto''s & Waarden)', 'Taak 1', 'Verzamelen van authentieke schoolfoto''s en korte teksten/video''s om het dagelijkse schoolleven te tonen.', 'To-Do', '', 7, false),
  (8, 'Beheer en Gebruiksvriendelijkheid', 'Taak 2', 'Selecteren en inrichten van een gebruiksvriendelijk CMS met een visuele pagebuilder (inclusief drag-and-dropfunctionaliteit).', 'To-Do', '', 8, false),
  (9, 'Beheer en Gebruiksvriendelijkheid', 'Taak 3', 'Instellen van herbruikbare sjablonen voor terugkerende onderdelen (nieuws, studierichtingen, evenementen).', 'To-Do', '', 9, false),
  (10, 'Beheer en Gebruiksvriendelijkheid', 'Taak 4', 'Configureren van gebruikersrollen en toegangsrechten (beheerder, leerkrachten, redacteurs) en deze testen.', 'To-Do', '', 10, false),
  (11, 'Beheer en Gebruiksvriendelijkheid', 'Taak 5', 'Instellen van een onderhoudsarm platform met een testomgeving, automatische back-ups en beveiligingsupdates.', 'To-Do', '', 11, false),
  (12, 'Veiligheid, Juridisch en Formulieren', 'Taak 3', 'Instellen van een beveiligde HTTPS-verbinding (TLS-certificaat) en sterke beveiliging voor de beheerdersomgeving (incl. 2FA).', 'To-Do', '', 12, false),
  (13, 'Visie, Sfeer en Content (Foto''s & Waarden)', 'Taak 3', 'Inrichten van een overzichtelijke mediabibliotheek in het CMS voor het eenvoudig beheren en vervangen van foto''s.', 'To-Do', '', 13, false),
  (14, 'Design, Layout en Schermresoluties', 'Taak 1', 'Realiseren van volledige responsiviteit (automatische schaalbaarheid voor smartphones, tablets en pc''s).', 'To-Do', '', 14, false),
  (15, 'Design, Layout en Schermresoluties', 'Taak 2', 'Ontwikkelen van een compact uitklapbaar mobiel menu en grote, touch-vriendelijke knoppen.', 'To-Do', '', 15, false),
  (16, 'Design, Layout en Schermresoluties', 'Taak 4', 'Ontwerpen van een heldere homepage met duidelijke introductie, snelkoppelingen en doelgroep-ingangen (leerlingen, ouders, personeel, sollicitanten).', 'To-Do', '', 16, false),
  (17, 'Design, Layout en Schermresoluties', 'Taak 6', 'Implementeren van WCAG-richtlijnen voor toegankelijkheid (kleurcontrast, leesbare lettergroottes, alt-teksten, focusmarkeringen).', 'To-Do', '', 17, false),
  (18, 'Design, Layout en Schermresoluties', 'Taak 7', 'Vormgeven en testen van de Google Maps-locatiekaart in de huisstijl.', 'To-Do', '', 18, false),
  (19, 'Visie, Sfeer en Content (Foto''s & Waarden)', 'Taak 2', 'Visueel uitwerken van de vier kernwaarden (Eigentijds leren, Zelfstandigheid, Samen, Betrokken) met iconen en beelden.', 'To-Do', '', 19, false),
  (20, 'Visie, Sfeer en Content (Foto''s & Waarden)', 'Taak 4', 'Toevoegen van interactieve elementen aan afbeeldingen (zoals aanklikbare zones of verhalen uit de praktijk).', 'To-Do', '', 20, false),
  (21, 'Studierichtingen en Interactief Spoor', 'Taak 1', 'Groeperen van graden, studierichtingen en lessentabellen in een uniforme, mobiel-vriendelijke structuur.', 'To-Do', '', 21, false),
  (22, 'Schoolteam en Contact', 'Taak 1', 'Aanmaken van een overzichtelijke ''Ons Team''-pagina met profielsjablonen per personeelslid (functie, vakken, foto, contactopties).', 'To-Do', '', 22, false),
  (23, 'Schoolteam en Contact', 'Taak 2', 'Inrichten van een centrale contactpagina ingedeeld op onderwerp (inschrijvingen, administratie, begeleiding) en opnemen in de footer.', 'To-Do', '', 23, false),
  (24, 'Veiligheid, Juridisch en Formulieren', 'Taak 1', 'Implementeren van een correcte cookiebanner en AVG/GDPR-compatibel privacybeleid.', 'To-Do', '', 24, false),
  (25, 'Studierichtingen en Interactief Spoor', 'Taak 2', 'Bouwen van een vergelijkingsfunctie voor studierichtingen (vakken, uren, vervolgtrajecten).', 'To-Do', '', 25, false),
  (26, 'Studierichtingen en Interactief Spoor', 'Taak 3', 'Ontwikkelen van de interactieve keuzehulp ''Kies je Spoor'' (gebaseerd op een treintjes- en statenthema).', 'To-Do', '', 26, false),
  (27, 'Studierichtingen en Interactief Spoor', 'Taak 4', 'Implementeren van een op interesses gebaseerde vragenlijst in de keuzehulp met vrijblijvende suggesties.', 'To-Do', '', 27, false),
  (28, 'AI Chatbot, Robot en Zoekfunctie', 'Taak 5', 'Bouwen van een geavanceerde zoekbalk in de header met directe zoeksuggesties en ondersteuning voor alle apparaten.', 'To-Do', '', 28, false),
  (29, 'Veiligheid, Juridisch en Formulieren', 'Taak 4', 'Bouwen van een online vacaturepagina en digitaal sollicitatieformulier met beveiligde doorsturing naar de directie.', 'To-Do', '', 29, false),
  (30, 'Veiligheid, Juridisch en Formulieren', 'Taak 5', 'Structureren van de pagina voor inschrijvingen en administratieve aanvragen met duidelijke instructies en bevestigingsmeldingen.', 'To-Do', '', 30, false),
  (31, 'AI Chatbot, Robot en Zoekfunctie', 'Taak 1', 'Integreren van een subtiel, niet-storend chatboticoon onderaan de website.', 'To-Do', '', 31, false),
  (32, 'AI Chatbot, Robot en Zoekfunctie', 'Taak 2', 'Koppelen van een centrale kennisbank (schoolreglement, kalender, FAQ''s) aan de chatbot voor betrouwbare antwoorden buiten de openingsuren.', 'To-Do', '', 32, false),
  (33, 'AI Chatbot, Robot en Zoekfunctie', 'Taak 3', 'Vormgeven van het chatbotvenster met de schoolrobot (inclusief eigen naam en vriendelijke begroeting).', 'To-Do', '', 33, false),
  (34, 'AI Chatbot, Robot en Zoekfunctie', 'Taak 4', 'Instellen van een e-mailfallback / doorverwijsformulier wanneer de chatbot de vraag niet kan beantwoorden.', 'To-Do', '', 34, false),
  (35, 'Projectuitvoering en oplevering', 'Taak 2', 'Ontwikkeling: CMS inrichten, design bouwen, content migreren en technische features (chatbot, spoor, zoekfunctie) koppelen.', 'To-Do', '', 35, false),
  (36, 'Studierichtingen en Interactief Spoor', 'Taak 5', 'Testen van de studiekeuzehulp met leerlingen en ouders.', 'To-Do', '', 36, false),
  (37, 'Projectuitvoering en oplevering', 'Taak 3', 'Testfase: Uitvoeren van responsive tests, linkchecks, laadsnelheidsoptimalisatie en gebruikersgroep-tests (leerlingen/ouders).', 'To-Do', '', 37, false),
  (38, 'Beheer en Gebruiksvriendelijkheid', 'Taak 6', 'Opstellen van een handleiding en organiseren van een praktijktest voor het schoolteam.', 'To-Do', '', 38, false),
  (39, 'Projectuitvoering en oplevering', 'Taak 4', 'Oplevering & Onderhoud: Volledige back-up maken, website publiceren, schoolteam opleiden en een vaste beheerder aanwijzen voor updates.', 'To-Do', '', 39, false)
on conflict (id) do nothing;

update public.tasks
set requirement = case requirement
  when 'Requirement 1' then 'Beheer en Gebruiksvriendelijkheid'
  when 'Requirement 2' then 'Design, Layout en Schermresoluties'
  when 'Requirement 3' then 'Visie, Sfeer en Content (Foto''s & Waarden)'
  when 'Requirement 4' then 'Studierichtingen en Interactief Spoor'
  when 'Requirement 5' then 'Schoolteam en Contact'
  when 'Requirement 6' then 'AI Chatbot, Robot en Zoekfunctie'
  when 'Requirement 7' then 'Veiligheid, Juridisch en Formulieren'
  when 'Requirement 8' then 'Projectuitvoering en oplevering'
  else requirement
end
where requirement in (
  'Requirement 1', 'Requirement 2', 'Requirement 3', 'Requirement 4',
  'Requirement 5', 'Requirement 6', 'Requirement 7', 'Requirement 8'
);

-- Voor live-updates: voeg de tabel toe aan de Realtime-publicatie als dit nog niet gebeurd is.
-- Als Supabase meldt dat de tabel al bestaat in de publicatie, is dit deel al actief.
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tasks') then
    execute 'alter publication supabase_realtime add table public.tasks';
  end if;
end $$;
