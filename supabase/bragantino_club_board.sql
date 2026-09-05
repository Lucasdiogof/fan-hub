-- Diretoria do Red Bull Bragantino — SÓ 2 nomes confirmados com segurança
-- nesta rodada (pesquisa web em 2026-09-05, CNN Brasil/Trivela): Marco
-- Antônio Abi Chedid (presidente) e Diego Cerri (CEO/diretor executivo de
-- futebol). Resto do conselho é DATA_GAP — não inventar, completar depois
-- com fonte oficial (site do clube não lista o conselho publicamente hoje).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj) — NUNCA no projeto do Goiás. Schema já existe lá
-- (convergido, SCHEMA_DIFF=0 contra o Goiás) — só INSERT, sem create table.

insert into public.club_board_sections (id, title, sort_order) values
  ('diretoria_executiva', 'Diretoria Executiva', 0)
on conflict (id) do update set title = excluded.title, sort_order = excluded.sort_order;

insert into public.club_board_members (id, section_id, name, role, sort_order) values
  ('marco_antonio_abi_chedid', 'diretoria_executiva', 'Marco Antônio Abi Chedid', 'Presidente', 0),
  ('diego_cerri', 'diretoria_executiva', 'Diego Cerri', 'CEO e Diretor Executivo de Futebol', 1)
on conflict (id) do update set
  name = excluded.name, role = excluded.role, sort_order = excluded.sort_order, updated_at = now();
