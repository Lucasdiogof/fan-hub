create table if not exists public.squad_members (
  id text primary key,
  name text not null,
  full_name text,
  shirt_number int,
  position text not null,
  position_group text not null,
  birth_date date,
  nationality text,
  height_cm int,
  foot text,
  photo_url text,
  club_history jsonb not null default '[]'::jsonb,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.squad_members enable row level security;

create policy "squad_members_read_all"
  on public.squad_members
  for select
  using (true);
