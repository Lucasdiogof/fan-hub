-- Elenco do Bragantino — refresh 2026-09-07 (pacote docs/bragantino_data,
-- data/squad_2026_snapshot.json). Roda DEPOIS de
-- squad_members_add_lifecycle_columns.sql (precisa das colunas
-- active/departed_at/departed_to existirem).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).
--
-- Wallace Yan: contratado em 02/09/2026, contrato até 08/2031, titular
-- contra o Bahia em 05/09/2026. Fonte não traz camisa/nascimento/
-- nacionalidade/altura/pé/foto — ficam null (nunca inventar). Posição
-- "MEI/ATA" na fonte -> Meia-atacante/Atacantes, mesmo padrão já usado
-- pro Marcelinho (também MEI/ATA na origem).
insert into public.squad_members
  (id, club_id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, photo_url, club_history, sort_order)
values
  ('wallace-yan', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Wallace Yan', 'Wallace Yan', null, 'Meia-atacante', 'Atacantes', null, null, null, null, null, '[]'::jsonb, 30)
on conflict (id) do update set
  club_id = excluded.club_id, name = excluded.name, full_name = excluded.full_name,
  shirt_number = excluded.shirt_number, position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality, height_cm = excluded.height_cm,
  foot = excluded.foot, photo_url = excluded.photo_url, club_history = excluded.club_history,
  sort_order = excluded.sort_order, updated_at = now();

-- Pedro Henrique: vendido ao Al Ettifaq em 06/09/2026. Marcado inativo,
-- NUNCA deletado — linha e histórico continuam intactos na tabela.
update public.squad_members
set active = false, departed_at = '2026-09-06', departed_to = 'Al Ettifaq', updated_at = now()
where id = 'pedro-henrique' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7';
