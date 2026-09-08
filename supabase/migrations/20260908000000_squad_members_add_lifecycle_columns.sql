alter table public.squad_members add column if not exists active boolean not null default true;
alter table public.squad_members add column if not exists departed_at date;
alter table public.squad_members add column if not exists departed_to text;
