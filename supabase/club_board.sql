-- Diretoria do Goiás — seções (In memoriam, Conselho Deliberativo,
-- Presidência Executiva, Diretoria Executiva, Conselho Fiscal, Suplentes) e
-- as pessoas dentro de cada uma. Fonte: goiasec.com.br/perfil/diretoria.
-- Supabase é a fonte da verdade — atualizar nome/cargo aqui reflete no app
-- sem precisar de um novo build.

create table if not exists public.club_board_sections (
  id text primary key,
  title text not null,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.club_board_members (
  id text primary key,
  section_id text not null references public.club_board_sections(id) on delete cascade,
  name text not null,
  role text not null,
  photo_url text,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.club_board_sections enable row level security;
alter table public.club_board_members enable row level security;

drop policy if exists "club_board_sections_read_all" on public.club_board_sections;
create policy "club_board_sections_read_all"
  on public.club_board_sections
  for select
  using (true);

drop policy if exists "club_board_members_read_all" on public.club_board_members;
create policy "club_board_members_read_all"
  on public.club_board_members
  for select
  using (true);

insert into public.club_board_sections (id, title, sort_order) values
  ('in_memoriam', 'In memoriam', 0),
  ('conselho_deliberativo', 'Conselho Deliberativo', 1),
  ('presidencia_executiva', 'Presidência Executiva', 2),
  ('diretoria_executiva', 'Diretoria Executiva', 3),
  ('conselho_fiscal', 'Conselho Fiscal', 4),
  ('suplentes', 'Suplentes', 5)
on conflict (id) do update set
  title = excluded.title,
  sort_order = excluded.sort_order;

insert into public.club_board_members (id, section_id, name, role, sort_order) values
  ('haile_selassie_pinheiro', 'in_memoriam', 'Hailé Selassié de Goiás Pinheiro', 'Presidente de Honra', 0),
  ('lino_barsi', 'in_memoriam', 'Lino Barsi', 'Patrono do clube', 1),

  ('paulo_rogerio_pinheiro', 'conselho_deliberativo', 'Paulo Rogério Pinheiro', 'Presidente do Conselho Deliberativo', 0),
  ('eduardo_ribeiro', 'conselho_deliberativo', 'Eduardo Ribeiro', '1º Vice-Presidente do Conselho Deliberativo', 1),
  ('wagner_donizete_villela', 'conselho_deliberativo', 'Wagner Donizete Villela', '2º Vice-Presidente do Conselho Deliberativo', 2),

  ('aroldo_guidao_filho', 'presidencia_executiva', 'Aroldo Guidão Filho', 'Presidente Executivo', 0),
  ('jose_joao_batista_stival_junior', 'presidencia_executiva', 'José João Batista Stival Júnior', 'Vice-Presidente de Esportes Olímpicos, Paralímpicos, Iniciação Esportiva e Social', 1),
  ('marco_antonio_da_silva_castro', 'presidencia_executiva', 'Marco Antônio da Silva Castro', 'Vice-Presidente Jurídico', 2),
  ('marcus_ulysses_de_oliveira', 'presidencia_executiva', 'Marcus Ulysses de Oliveira', 'Vice-Presidente Marketing, Comunicação e Novos Negócios', 3),

  ('leonardo_pacheco', 'diretoria_executiva', 'Leonardo Pacheco', 'Diretor Executivo', 0),
  ('michel_alves', 'diretoria_executiva', 'Michel Alves', 'Diretor de Futebol', 1),
  ('jessica_rezende', 'diretoria_executiva', 'Jessica Rezende', 'Diretora de Marketing & Comunicação', 2),

  ('lourival_fonseca_jr', 'conselho_fiscal', 'Lourival Fonseca Jr.', 'Presidente do Conselho Fiscal', 0),
  ('marcello_pena', 'conselho_fiscal', 'Marcello Pena', 'Vice-Presidente do Conselho Fiscal', 1),
  ('wandervan_antonio_de_azevedo', 'conselho_fiscal', 'Wandervan Antônio de Azevedo', 'Membro Efetivo do Conselho Fiscal', 2),

  ('jonas_godoy', 'suplentes', 'Jonas Godoy', 'Suplente', 0),
  ('priscila_wardil', 'suplentes', 'Priscila Wardil', 'Suplente', 1),
  ('rogerio_santana', 'suplentes', 'Rogério Santana', 'Suplente', 2)
on conflict (id) do update set
  section_id = excluded.section_id,
  name = excluded.name,
  role = excluded.role,
  sort_order = excluded.sort_order;
