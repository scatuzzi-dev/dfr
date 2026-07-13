-- Esquema para el Disparador DFR
-- Tablas con prefijo dfr_ para convivir sin choques con las tablas
-- de tus otros proyectos dentro del mismo proyecto de Supabase.
-- Pegar en Supabase: Dashboard → SQL Editor → New query → Run

create extension if not exists "pgcrypto";

create table dfr_organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  region text not null default 'us',
  token text not null,
  creator text,
  created_at timestamptz default now()
);

create table dfr_projects (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references dfr_organizations(id) on delete cascade,
  name text not null,
  project_uuid text not null,
  created_at timestamptz default now()
);

create table dfr_workflows (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references dfr_projects(id) on delete cascade,
  name text not null,
  workflow_uuid text not null,
  created_at timestamptz default now()
);

create table dfr_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  lat double precision not null,
  lng double precision not null,
  created_at timestamptz default now()
);

-- Configuracion global de la app (fila unica, id=1).
-- Por ahora guarda el ID/URL del reproductor de Castr para la
-- transmision en vivo, compartido entre todos los dispositivos.
create table dfr_settings (
  id int primary key default 1,
  castr_player text,
  updated_at timestamptz default now()
);

insert into dfr_settings (id, castr_player) values (1, null);

-- Row Level Security -------------------------------------------------
-- IMPORTANTE: la clave "anon" de Supabase es pública (va embebida en el
-- HTML). Sin políticas RLS, cualquiera con esa clave podría leer o
-- escribir estas tablas -- incluyendo el campo "token" (tu X-User-Token
-- de FlightHub 2, que es un secreto real).
--
-- La política de abajo habilita lectura y escritura para cualquiera que
-- tenga la anon key (vos y a quien le compartas el sitio). Si en algún
-- momento vas a exponer esto más ampliamente, conviene sumar Supabase
-- Auth y restringir las políticas a usuarios autenticados en vez de
-- "true". Esto no afecta ni se mezcla con las políticas RLS que ya
-- tengas en las tablas de tus otros proyectos.

alter table dfr_organizations enable row level security;
alter table dfr_projects enable row level security;
alter table dfr_workflows enable row level security;
alter table dfr_locations enable row level security;
alter table dfr_settings enable row level security;

create policy "dfr allow all - organizations" on dfr_organizations for all using (true) with check (true);
create policy "dfr allow all - projects" on dfr_projects for all using (true) with check (true);
create policy "dfr allow all - workflows" on dfr_workflows for all using (true) with check (true);
create policy "dfr allow all - locations" on dfr_locations for all using (true) with check (true);
create policy "dfr allow all - settings" on dfr_settings for all using (true) with check (true);
