-- ============================================================
--  SINERGIAMED — Persistencia en la nube (Supabase)
--  Arregla el problema de que las historias/sesiones se
--  guardaban solo en el navegador (localStorage) y desaparecían.
--
--  CÓMO USAR:
--  Supabase Dashboard -> SQL Editor -> New query -> pegar TODO -> Run
--  Es idempotente: se puede ejecutar varias veces sin romper nada.
-- ============================================================

-- 1) HISTORIAS CLÍNICAS ---------------------------------------
create table if not exists public.clinical_records (
  id           text primary key,
  hc_number    text,
  patient_name text,
  id_number    text,
  record_data  jsonb,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
alter table public.clinical_records add column if not exists hc_number    text;
alter table public.clinical_records add column if not exists patient_name text;
alter table public.clinical_records add column if not exists id_number    text;
alter table public.clinical_records add column if not exists record_data  jsonb;
alter table public.clinical_records add column if not exists created_at   timestamptz default now();
alter table public.clinical_records add column if not exists updated_at   timestamptz default now();

-- 2) PACIENTES DE CÁMARA HIPERBÁRICA --------------------------
create table if not exists public.hyperbaric_patients (
  id           text primary key,
  full_name    text,
  id_number    text,
  phone        text,
  email        text,
  patient_data jsonb,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
alter table public.hyperbaric_patients add column if not exists full_name    text;
alter table public.hyperbaric_patients add column if not exists id_number    text;
alter table public.hyperbaric_patients add column if not exists phone        text;
alter table public.hyperbaric_patients add column if not exists email        text;
alter table public.hyperbaric_patients add column if not exists patient_data jsonb;
alter table public.hyperbaric_patients add column if not exists created_at   timestamptz default now();
alter table public.hyperbaric_patients add column if not exists updated_at   timestamptz default now();

-- 3) SESIONES DE CÁMARA ---------------------------------------
create table if not exists public.hyperbaric_sessions (
  id           text primary key,
  patient_id   text,
  session_num  integer,
  session_date text,
  time_in      text,
  time_out     text,
  session_data jsonb,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
alter table public.hyperbaric_sessions add column if not exists patient_id   text;
alter table public.hyperbaric_sessions add column if not exists session_num  integer;
alter table public.hyperbaric_sessions add column if not exists session_date text;
alter table public.hyperbaric_sessions add column if not exists time_in      text;
alter table public.hyperbaric_sessions add column if not exists time_out     text;
alter table public.hyperbaric_sessions add column if not exists session_data jsonb;
alter table public.hyperbaric_sessions add column if not exists created_at   timestamptz default now();
alter table public.hyperbaric_sessions add column if not exists updated_at   timestamptz default now();

-- 4) RLS + POLÍTICAS (anon + authenticated) ------------------
--    La app se conecta con la clave pública (rol anon) y sincroniza
--    en el arranque, así que damos acceso a anon Y authenticated para
--    que lea/guarde de forma fiable sin depender del timing de sesión.
--    El login (index.html) actúa como barrera de acceso a la interfaz.
do $$
declare t text;
begin
  foreach t in array array['clinical_records','hyperbaric_patients','hyperbaric_sessions']
  loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists sinergia_select on public.%I;', t);
    execute format('drop policy if exists sinergia_insert on public.%I;', t);
    execute format('drop policy if exists sinergia_update on public.%I;', t);
    execute format('drop policy if exists sinergia_delete on public.%I;', t);
    execute format('create policy sinergia_select on public.%I for select to anon, authenticated using (true);', t);
    execute format('create policy sinergia_insert on public.%I for insert to anon, authenticated with check (true);', t);
    execute format('create policy sinergia_update on public.%I for update to anon, authenticated using (true) with check (true);', t);
    -- SIN política de DELETE a propósito: ningún cliente (ni con código viejo
    -- en caché) puede borrar historias. Protege contra pérdida de datos.
    -- Para borrar algo puntual, hazlo desde el dashboard de Supabase.
  end loop;
end $$;

-- 5) VERIFICACIÓN --------------------------------------------
select 'clinical_records'    as tabla, count(*) as filas from public.clinical_records
union all
select 'hyperbaric_patients', count(*) from public.hyperbaric_patients
union all
select 'hyperbaric_sessions', count(*) from public.hyperbaric_sessions;
