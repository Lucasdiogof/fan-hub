-- Ryan Augusto e Bruno Gonçalves (Bruninho) não existiam em squad_members —
-- por isso a rodada anterior de Instagram não achou nenhum dos dois por
-- nome nenhum. Mesmo padrão do Wallace Yan em
-- `bragantino_squad_members_2026_09_refresh.sql`: só os campos com fonte
-- confirmada entram, o resto fica null (nunca inventado).
--
-- Ryan Augusto: posição (Lateral-direito) confirmada em
-- `docs/bragantino_data/data/squad_2026_snapshot.json` ("used vs Bahia
-- 2026-09-05"). Sem camisa/nascimento/nacionalidade/altura/pé/foto na fonte.
--
-- Bruno Gonçalves ("Bruninho"): confirmado via Transfermarkt
-- (transfermarkt.com.br/red-bull-bragantino) — nasc. 14/03/2003 (São
-- Paulo/SP), Brasil, 1,74m, posição "Meia Ofensivo" -> mapeado pro mesmo
-- par (position/position_group) já usado no schema pra outros meias-
-- atacantes (Rodriguinho, Marcelinho): 'Meia-atacante'/'Atacantes'. Sem
-- número de camisa/pé/foto confirmados ainda — ficam null.
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj).
insert into public.squad_members
  (id, club_id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, photo_url, instagram_url, club_history, sort_order)
values
  ('ryan-augusto', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Ryan Augusto', 'Ryan Augusto', null, 'Lateral-direito', 'Laterais-direitos', null, null, null, null, null, 'https://www.instagram.com/ryanaugusto_07/', '[]'::jsonb, 90),
  ('bruno-goncalves', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Bruninho', 'Bruno Gonçalves', null, 'Meia-atacante', 'Atacantes', '2003-03-14', 'Brasil', 174, null, null, 'https://www.instagram.com/brunogj03/', '[]'::jsonb, 91)
on conflict (id) do update set
  club_id = excluded.club_id, name = excluded.name, full_name = excluded.full_name,
  shirt_number = excluded.shirt_number, position = excluded.position, position_group = excluded.position_group,
  birth_date = excluded.birth_date, nationality = excluded.nationality, height_cm = excluded.height_cm,
  foot = excluded.foot, photo_url = excluded.photo_url, instagram_url = excluded.instagram_url,
  club_history = excluded.club_history, sort_order = excluded.sort_order, updated_at = now();
