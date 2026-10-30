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

create table if not exists public.team_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  updated_at timestamptz not null default now()
);

insert into public.team_members (user_id, display_name)
select
  id,
  left(coalesce(
    nullif(btrim(raw_user_meta_data->>'display_name'), ''),
    nullif(btrim(raw_user_meta_data->>'full_name'), ''),
    nullif(split_part(coalesce(email, ''), '@', 1), ''),
    'Teamlid'
  ), 80)
from auth.users
on conflict (user_id) do nothing;

delete from public.team_members member
where not exists (select 1 from auth.users auth_user where auth_user.id = member.user_id);

-- Keep account creation secure; no admin/service-role credential is exposed to the browser.
create or replace function public.sync_team_member_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.team_members (user_id, display_name)
  values (
    new.id,
    left(coalesce(
      nullif(btrim(new.raw_user_meta_data->>'display_name'), ''),
      nullif(btrim(new.raw_user_meta_data->>'full_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Teamlid'
    ), 80)
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke all on function public.sync_team_member_profile() from public, anon, authenticated;
drop trigger if exists sync_team_member_profile on auth.users;
create trigger sync_team_member_profile
  after insert or update of email, raw_user_meta_data on auth.users
  for each row execute function public.sync_team_member_profile();

alter table public.team_members enable row level security;
revoke all on table public.team_members from anon, authenticated;
grant select on table public.team_members to authenticated;
grant update (display_name) on table public.team_members to authenticated;

drop policy if exists "Signed-in team can read member profiles" on public.team_members;
drop policy if exists "Members can update own display name" on public.team_members;
create policy "Signed-in team can read member profiles" on public.team_members
  for select to authenticated using (true);
create policy "Members can update own display name" on public.team_members
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.tasks
  add column if not exists assignee_ids uuid[] not null default '{}'::uuid[];

update public.tasks task
set assignee_ids = (
  select coalesce(array_agg(assigned.user_id order by assigned.user_id), '{}'::uuid[])
  from (
    select existing.user_id
    from unnest(task.assignee_ids) as existing(user_id)
    where exists (
      select 1
      from public.team_members member
      where member.user_id = existing.user_id
    )
    union
    select member.user_id
    from public.team_members member
    left join auth.users auth_user on auth_user.id = member.user_id
    where exists (
      select 1
      from unnest(task.assignees) as old_assignee(name)
      where lower(btrim(old_assignee.name)) in (
        lower(member.display_name),
        lower(split_part(coalesce(auth_user.email, ''), '@', 1))
      )
    )
  ) assigned
)
where cardinality(task.assignees) > 0;

update public.tasks task
set assignees = array(
      select old_assignee.name
      from unnest(task.assignees) as old_assignee(name)
      where not exists (
        select 1
        from public.team_members member
        left join auth.users auth_user on auth_user.id = member.user_id
        where lower(btrim(old_assignee.name)) in (
          lower(member.display_name),
          lower(split_part(coalesce(auth_user.email, ''), '@', 1))
        )
      )
    ),
    assignee = array_to_string(array(
      select old_assignee.name
      from unnest(task.assignees) as old_assignee(name)
      where not exists (
        select 1
        from public.team_members member
        left join auth.users auth_user on auth_user.id = member.user_id
        where lower(btrim(old_assignee.name)) in (
          lower(member.display_name),
          lower(split_part(coalesce(auth_user.email, ''), '@', 1))
        )
      )
    ), ', ')
where cardinality(task.assignees) > 0;

update public.tasks
set assignees = '{}'::text[],
    assignee = ''
where cardinality(assignees) > 0 or btrim(assignee) <> '';

alter table public.tasks enable row level security;
revoke all on table public.tasks from anon;
grant select, insert, update, delete on table public.tasks to authenticated;

drop policy if exists "Signed-in team can read tasks" on public.tasks;
drop policy if exists "Signed-in team can add tasks" on public.tasks;
drop policy if exists "Signed-in team can update tasks" on public.tasks;
drop policy if exists "Signed-in team can delete tasks" on public.tasks;
create policy "Signed-in team can read tasks" on public.tasks for select to authenticated using (true);
create policy "Signed-in team can add tasks" on public.tasks for insert to authenticated with check (true);
create policy "Signed-in team can update tasks" on public.tasks for update to authenticated using (true) with check (true);
create policy "Signed-in team can delete tasks" on public.tasks for delete to authenticated using (true);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'team_members'
     ) then
    alter publication supabase_realtime add table public.team_members;
  end if;
end;
$$;

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
  (1, 'Projectuitvoering en oplevering', '8.1', 'Analyse & Voorbereiding: Huidige site onderzoeken, knelpunten inventariseren en content verzamelen.', 'Afgerond', '', 1, false),
  (2, 'Beheer en Gebruiksvriendelijkheid', '1.1', 'Onderzoeken van de huidige website om complexe beheerelementen te identificeren.', 'To-Do', '', 2, false),
  (3, 'Design, Layout en Schermresoluties', '2.1', 'Opstellen van een stijlgids met schoolkleuren, lettertypes, iconen en huisstijl.', 'To-Do', '', 3, false),
  (4, 'Design, Layout en Schermresoluties', '2.2', 'Inventariseren en stroomlijnen van de menustructuur (belangrijke info binnen 2 à 3 klikken).', 'To-Do', '', 4, false),
  (5, 'Schoolteam en Contact', '5.1', 'Verzamelen, controleren en integreren van officiële links naar sociale-mediakanalen.', 'To-Do', '', 5, false),
  (6, 'Veiligheid, Juridisch en Formulieren', '7.1', 'Controleren en vastleggen van beeldrechten, licenties en een procedure om foto''s eenvoudig te verwijderen.', 'To-Do', '', 6, false),
  (7, 'Visie, Sfeer en Content (Foto''s & Waarden)', '3.1', 'Verzamelen van authentieke schoolfoto''s en korte teksten/video''s om het dagelijkse schoolleven te tonen.', 'To-Do', '', 7, false),
  (8, 'Beheer en Gebruiksvriendelijkheid', '1.2', 'Selecteren en inrichten van een gebruiksvriendelijk CMS met een visuele pagebuilder (inclusief drag-and-dropfunctionaliteit).', 'To-Do', '', 8, false),
  (9, 'Beheer en Gebruiksvriendelijkheid', '1.3', 'Instellen van herbruikbare sjablonen voor terugkerende onderdelen (nieuws, studierichtingen, evenementen).', 'To-Do', '', 9, false),
  (10, 'Beheer en Gebruiksvriendelijkheid', '1.4', 'Configureren van gebruikersrollen en toegangsrechten (beheerder, leerkrachten, redacteurs) en deze testen.', 'To-Do', '', 10, false),
  (11, 'Beheer en Gebruiksvriendelijkheid', '1.5', 'Instellen van een onderhoudsarm platform met een testomgeving, automatische back-ups en beveiligingsupdates.', 'To-Do', '', 11, false),
  (12, 'Veiligheid, Juridisch en Formulieren', '7.2', 'Instellen van een beveiligde HTTPS-verbinding (TLS-certificaat) en sterke beveiliging voor de beheerdersomgeving (incl. 2FA).', 'To-Do', '', 12, false),
  (13, 'Visie, Sfeer en Content (Foto''s & Waarden)', '3.2', 'Inrichten van een overzichtelijke mediabibliotheek in het CMS voor het eenvoudig beheren en vervangen van foto''s.', 'To-Do', '', 13, false),
  (14, 'Design, Layout en Schermresoluties', '2.3', 'Realiseren van volledige responsiviteit (automatische schaalbaarheid voor smartphones, tablets en pc''s).', 'To-Do', '', 14, false),
  (15, 'Design, Layout en Schermresoluties', '2.4', 'Ontwikkelen van een compact uitklapbaar mobiel menu en grote, touch-vriendelijke knoppen.', 'To-Do', '', 15, false),
  (16, 'Design, Layout en Schermresoluties', '2.5', 'Ontwerpen van een heldere homepage met duidelijke introductie, snelkoppelingen en doelgroep-ingangen (leerlingen, ouders, personeel, sollicitanten).', 'To-Do', '', 16, false),
  (17, 'Design, Layout en Schermresoluties', '2.6', 'Implementeren van WCAG-richtlijnen voor toegankelijkheid (kleurcontrast, leesbare lettergroottes, alt-teksten, focusmarkeringen).', 'To-Do', '', 17, false),
  (18, 'Design, Layout en Schermresoluties', '2.7', 'Vormgeven en testen van de Google Maps-locatiekaart in de huisstijl.', 'To-Do', '', 18, false),
  (19, 'Visie, Sfeer en Content (Foto''s & Waarden)', '3.3', 'Visueel uitwerken van de vier kernwaarden (Eigentijds leren, Zelfstandigheid, Samen, Betrokken) met iconen en beelden.', 'To-Do', '', 19, false),
  (20, 'Visie, Sfeer en Content (Foto''s & Waarden)', '3.4', 'Toevoegen van interactieve elementen aan afbeeldingen (zoals aanklikbare zones of verhalen uit de praktijk).', 'To-Do', '', 20, false),
  (21, 'Studierichtingen en Interactief Spoor', '4.1', 'Groeperen van graden, studierichtingen en lessentabellen in een uniforme, mobiel-vriendelijke structuur.', 'To-Do', '', 21, false),
  (22, 'Schoolteam en Contact', '5.2', 'Aanmaken van een overzichtelijke ''Ons Team''-pagina met profielsjablonen per personeelslid (functie, vakken, foto, contactopties).', 'To-Do', '', 22, false),
  (23, 'Schoolteam en Contact', '5.3', 'Inrichten van een centrale contactpagina ingedeeld op onderwerp (inschrijvingen, administratie, begeleiding) en opnemen in de footer.', 'To-Do', '', 23, false),
  (24, 'Veiligheid, Juridisch en Formulieren', '7.3', 'Implementeren van een correcte cookiebanner en AVG/GDPR-compatibel privacybeleid.', 'To-Do', '', 24, false),
  (25, 'Studierichtingen en Interactief Spoor', '4.2', 'Bouwen van een vergelijkingsfunctie voor studierichtingen (vakken, uren, vervolgtrajecten).', 'To-Do', '', 25, false),
  (26, 'Studierichtingen en Interactief Spoor', '4.3', 'Ontwikkelen van de interactieve keuzehulp ''Kies je Spoor'' (gebaseerd op een treintjes- en statenthema).', 'To-Do', '', 26, false),
  (27, 'Studierichtingen en Interactief Spoor', '4.4', 'Implementeren van een op interesses gebaseerde vragenlijst in de keuzehulp met vrijblijvende suggesties.', 'To-Do', '', 27, false),
  (28, 'AI Chatbot, Robot en Zoekfunctie', '6.1', 'Bouwen van een geavanceerde zoekbalk in de header met directe zoeksuggesties en ondersteuning voor alle apparaten.', 'To-Do', '', 28, false),
  (29, 'Veiligheid, Juridisch en Formulieren', '7.4', 'Bouwen van een online vacaturepagina en digitaal sollicitatieformulier met beveiligde doorsturing naar de directie.', 'To-Do', '', 29, false),
  (30, 'Veiligheid, Juridisch en Formulieren', '7.5', 'Structureren van de pagina voor inschrijvingen en administratieve aanvragen met duidelijke instructies en bevestigingsmeldingen.', 'To-Do', '', 30, false),
  (31, 'AI Chatbot, Robot en Zoekfunctie', '6.2', 'Integreren van een subtiel, niet-storend chatboticoon onderaan de website.', 'To-Do', '', 31, false),
  (32, 'AI Chatbot, Robot en Zoekfunctie', '6.3', 'Koppelen van een centrale kennisbank (schoolreglement, kalender, FAQ''s) aan de chatbot voor betrouwbare antwoorden buiten de openingsuren.', 'To-Do', '', 32, false),
  (33, 'AI Chatbot, Robot en Zoekfunctie', '6.4', 'Vormgeven van het chatbotvenster met de schoolrobot (inclusief eigen naam en vriendelijke begroeting).', 'To-Do', '', 33, false),
  (34, 'AI Chatbot, Robot en Zoekfunctie', '6.5', 'Instellen van een e-mailfallback / doorverwijsformulier wanneer de chatbot de vraag niet kan beantwoorden.', 'To-Do', '', 34, false),
  (35, 'Projectuitvoering en oplevering', '8.2', 'Ontwikkeling: CMS inrichten, design bouwen, content migreren en technische features (chatbot, spoor, zoekfunctie) koppelen.', 'To-Do', '', 35, false),
  (36, 'Studierichtingen en Interactief Spoor', '4.5', 'Testen van de studiekeuzehulp met leerlingen en ouders.', 'To-Do', '', 36, false),
  (37, 'Projectuitvoering en oplevering', '8.3', 'Testfase: Uitvoeren van responsive tests, linkchecks, laadsnelheidsoptimalisatie en gebruikersgroep-tests (leerlingen/ouders).', 'To-Do', '', 37, false),
  (38, 'Beheer en Gebruiksvriendelijkheid', '1.6', 'Opstellen van een handleiding en organiseren van een praktijktest voor het schoolteam.', 'To-Do', '', 38, false),
  (39, 'Projectuitvoering en oplevering', '8.4', 'Oplevering & Onderhoud: Volledige back-up maken, website publiceren, schoolteam opleiden en een vaste beheerder aanwijzen voor updates.', 'To-Do', '', 39, false)
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

with numbered_tasks as (
  select id,
    concat(
      case requirement
        when 'Beheer en Gebruiksvriendelijkheid' then 1
        when 'Design, Layout en Schermresoluties' then 2
        when 'Visie, Sfeer en Content (Foto''s & Waarden)' then 3
        when 'Studierichtingen en Interactief Spoor' then 4
        when 'Schoolteam en Contact' then 5
        when 'AI Chatbot, Robot en Zoekfunctie' then 6
        when 'Veiligheid, Juridisch en Formulieren' then 7
        when 'Projectuitvoering en oplevering' then 8
      end,
      '.',
      row_number() over (partition by requirement order by sort_order, id)
    ) as task_code
  from public.tasks
  where requirement in (
    'Beheer en Gebruiksvriendelijkheid', 'Design, Layout en Schermresoluties',
    'Visie, Sfeer en Content (Foto''s & Waarden)', 'Studierichtingen en Interactief Spoor',
    'Schoolteam en Contact', 'AI Chatbot, Robot en Zoekfunctie',
    'Veiligheid, Juridisch en Formulieren', 'Projectuitvoering en oplevering'
  )
)
update public.tasks as task
set task_code = numbered_tasks.task_code
from numbered_tasks
where task.id = numbered_tasks.id;

-- Voor live-updates: voeg de tabel toe aan de Realtime-publicatie als dit nog niet gebeurd is.
-- Als Supabase meldt dat de tabel al bestaat in de publicatie, is dit deel al actief.
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tasks') then
    execute 'alter publication supabase_realtime add table public.tasks';
  end if;
end $$;
