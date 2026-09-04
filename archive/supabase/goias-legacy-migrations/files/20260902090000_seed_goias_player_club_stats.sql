-- ============================================================================
-- Seed de `public.player_club_stats` + `public.player_club_stat_sources`
-- — SOMENTE Goiás, SOMENTE pessoas já em `public.people` (96 APPROVED),
-- SOMENTE onde existe evidência resolvível (ver
-- player_club_stats_seed_stats.json pra auditoria completa).
--
-- GERADA por tooling/multiclub/generate_player_club_stats_seed.mjs a
-- partir de tooling/multiclub/build_player_club_stats_seed.mjs — NUNCA
-- editar à mão.
--
-- CLUB_TOTAL (spell_id null) nunca é dividido entre passagens. SPELL
-- (spell_id preenchido) só existe quando a fonte realmente dá o número
-- daquela passagem, casado por sobreposição de período contra os spells
-- reais — nunca um palpite. NULL != 0: ausência de dado nunca vira zero
-- (ver Walter 2019 = 0 jogos, um fato real, humano-verificado).
--
-- club_id/person_id de linhas SPELL são resolvidos por JOIN em
-- player_club_spells via spell_id — reforçado por FK composta no schema
-- (spell_id, person_id, club_id), nunca só literais soltos.
--
-- source_role (PRIMARY/CORROBORATING/DERIVED_COMPONENT/BASELINE) marca
-- explicitamente o papel de cada linha de provenance — um CLUB_TOTAL
-- derivado por soma tem 1 linha DERIVED_COMPONENT por segmento somado
-- (nunca um blob opaco), e o baseline do Tadeu tem source_role=BASELINE
-- (a Etapa E acha isso pelo campo, nunca por nome de source/notes).
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.player_club_stats (person_id, club_id, spell_id, stats_scope, appearances, goals, verification_status, as_of_date, as_of_match_id)
select
  case when v.stats_scope = 'SPELL' then pcs.person_id else v.person_id end,
  case when v.stats_scope = 'SPELL' then pcs.club_id else c.id end,
  v.spell_id,
  v.stats_scope, v.appearances, v.goals, v.verification_status, v.as_of_date, v.as_of_match_id
from (
  values
    ('b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 83, 3, 'VERIFIED', null::date, null),
    ('e277edea-70b1-5092-ad39-48be1a5297d6'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 76, 24, 'VERIFIED', null::date, null),
    ('50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 391, 145, 'VERIFIED', null::date, null),
    ('75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 26, 1, 'VERIFIED', null::date, null),
    ('6702c943-0b4e-5041-8cd4-76991b85633d'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 25, 4, 'VERIFIED', null::date, null),
    ('6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 16, 6, 'VERIFIED', null::date, null),
    ('34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 8, 0, 'VERIFIED', null::date, null),
    ('c628f9d8-6719-5506-acbd-adfb683fcf9b'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 116, 15, 'VERIFIED', null::date, null),
    ('54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 19, 2, 'VERIFIED', null::date, null),
    ('7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 46, 7, 'VERIFIED', null::date, null),
    ('6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 61, 8, 'VERIFIED', null::date, null),
    ('48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 103, 36, 'VERIFIED', null::date, null),
    ('a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 405, null, 'VERIFIED', null::date, null),
    ('10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 44, 5, 'VERIFIED', null::date, null),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 40, 16, 'VERIFIED', null::date, null),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', 'e34ef702-b7df-570f-a08d-9f00e2b5904d'::uuid, 'SPELL', 25, 8, 'VERIFIED', null::date, null),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', '4a768f8b-78c5-5a17-8750-6adc50aeb9af'::uuid, 'SPELL', 15, 8, 'VERIFIED', null::date, null),
    ('491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 271, 108, 'VERIFIED', null::date, null),
    ('88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 28, 3, 'VERIFIED', null::date, null),
    ('747cb968-a339-586c-94cf-583a3e0c3296'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 31, 0, 'VERIFIED', null::date, null),
    ('140ba628-c222-53a5-8621-a774092a125b'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 12, 0, 'VERIFIED', null::date, null),
    ('66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 831, 0, 'VERIFIED', null::date, null),
    ('652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 173, 47, 'VERIFIED', null::date, null),
    ('424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 47, 4, 'VERIFIED', null::date, null),
    ('be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 35, 1, 'VERIFIED', null::date, null),
    ('09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 386, 10, 'VERIFIED', null::date, null),
    ('d58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 32, 1, 'VERIFIED', null::date, null),
    ('36ed37b5-02be-5117-91d6-a62d5236505f'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 104, 3, 'VERIFIED', null::date, null),
    ('af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 26, 4, 'VERIFIED', null::date, null),
    ('91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 26, 2, 'VERIFIED', null::date, null),
    ('7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 0, 0, 'VERIFIED', null::date, null),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 45, 3, 'VERIFIED', null::date, null),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', '43d3d136-b00e-5393-a108-82adeef94fce'::uuid, 'SPELL', 19, 2, 'VERIFIED', null::date, null),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', '69dd430f-2090-562f-bcc4-bdcfb19e6ae2'::uuid, 'SPELL', 26, 1, 'VERIFIED', null::date, null),
    ('ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 32, 0, 'VERIFIED', null::date, null),
    ('a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 4, 0, 'VERIFIED', null::date, null),
    ('13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 129, 24, 'VERIFIED', null::date, null),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 3, 0, 'VERIFIED', null::date, null),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', 'cc08f610-8dc7-5e5a-b4e4-f5059f3763f6'::uuid, 'SPELL', 2, 0, 'VERIFIED', null::date, null),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', 'abf80090-af12-521a-b764-70c0d43058ff'::uuid, 'SPELL', 1, 0, 'VERIFIED', null::date, null),
    ('a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 38, 2, 'VERIFIED', null::date, null),
    ('493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 177, 78, 'PARTIAL', null::date, null),
    ('879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 96, 6, 'VERIFIED', null::date, null),
    ('16d026a7-49b3-5257-9daa-30601e3ef357'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 120, 49, 'PARTIAL', null::date, null),
    ('b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 150, 18, 'VERIFIED', null::date, null),
    ('d30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 13, 0, 'VERIFIED', null::date, null),
    ('4b153bcc-657a-5007-8c20-48c04130a484'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 63, 25, 'VERIFIED', null::date, null),
    ('2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 37, 0, 'VERIFIED', null::date, null),
    ('81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 87, 28, 'VERIFIED', null::date, null),
    ('e2507d62-8cb5-5152-af56-f67464196ac6'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 400, null, 'VERIFIED', '2026-08-28'::date, 'pe_cb52680435343cc4'),
    ('0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 10, 0, 'VERIFIED', null::date, null),
    ('828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 97, 48, 'PARTIAL', null::date, null),
    ('828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, 'goias', '40354072-1a71-50a3-867c-7a96c7af4f18'::uuid, 'SPELL', 0, null, 'VERIFIED', null::date, null),
    ('4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 22, 2, 'VERIFIED', null::date, null),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 61, 22, 'VERIFIED', null::date, null),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', '81e06be3-b0eb-5f57-be88-33ff1c108854'::uuid, 'SPELL', 53, 21, 'VERIFIED', null::date, null),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', '8b0aa269-c377-52be-bb29-95a0dc69658d'::uuid, 'SPELL', 8, 1, 'VERIFIED', null::date, null)
) as v(person_id, club_slug, spell_id, stats_scope, appearances, goals, verification_status, as_of_date, as_of_match_id)
left join public.clubs c on c.slug = v.club_slug
left join public.player_club_spells pcs on pcs.id = v.spell_id
on conflict do nothing;

insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date)
select pcstat.id, v.source_type, v.source_ref, v.raw_value, v.source_role, v.as_of_date
from (
  values
    ('b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'juninho', '{"period":"jan/2025–atual","team":"Goiás","appearances":83,"goals":3,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('e277edea-70b1-5092-ad39-48be1a5297d6'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'anselmo_ramon', '{"period":"abr/2025–atual","team":"Goiás","appearances":76,"goals":24,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'araujo', '{"club":"Goiás","spells":["1997-2003","2013-2014"],"appearances":391,"goals":145,"note":"Total histórico oficial do Goiás."}'::jsonb, 'PRIMARY', null::date),
    ('75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'brayann', '{"period":"set/2025–atual","team":"Goiás","appearances":26,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('6702c943-0b4e-5041-8cd4-76991b85633d'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'cadu', '{"period":"fev/2026–dez/2026","team":"Goiás","appearances":25,"goals":4,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'kadu_sousa', '{"period":"dez/2025–dez/2026","team":"Goiás","appearances":16,"goals":6,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'danilo', '{"period":"jan/2025–atual","team":"Goiás","appearances":8,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('c628f9d8-6719-5506-acbd-adfb683fcf9b'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'danilo', '{"period":"1999-2003","team":"Goiás","appearances":116,"goals":15,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'djalma', '{"period":"jan/2026–atual","team":"Goiás","appearances":19,"goals":2,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'dudu_cearense', '{"period":"2012-2013","team":"Goiás","appearances":46,"goals":7,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'egidio', '{"period":"2012","team":"Goiás","appearances":61,"goals":8,"loan":true,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'erik', '{"period":"2013-2015","team":"Goiás","appearances":103,"goals":36,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'ernando', '{"period":"2006-2013","team":"Goiás","appearances":405,"goals":null,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'esli_garcia', '{"period":"jan/2025–atual","team":"Goiás","appearances":44,"goals":5,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'evair', '{"club":"Goiás","spells":["2000","2002"],"appearances":40,"goals":16,"note":"Passagens agora individualizadas pela mesma base."}'::jsonb, 'PRIMARY', null::date),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', 'e34ef702-b7df-570f-a08d-9f00e2b5904d'::uuid, 'SPELL', 'career_players_club_career', 'evair', '{"period":"2000","team":"Goiás","appearances":25,"goals":8,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', '4a768f8b-78c5-5a17-8750-6adc50aeb9af'::uuid, 'SPELL', 'career_players_club_career', 'evair', '{"period":"2002","team":"Goiás","appearances":15,"goals":8,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'evair:2000', '{"period":"2000","team":"Goiás","appearances":25,"goals":8,"loan":false,"is_goias":true}'::jsonb, 'CORROBORATING', null::date),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'evair:2002', '{"period":"2002","team":"Goiás","appearances":15,"goals":8,"loan":false,"is_goias":true}'::jsonb, 'CORROBORATING', null::date),
    ('491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'fernandao', '{"club":"Goiás","spells":["1995-2001","2009-2010"],"appearances":271,"goals":108,"note":"Total oficial do Goiás; não distribuir entre as duas passagens."}'::jsonb, 'PRIMARY', null::date),
    ('88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'gege', '{"period":"jan/2026–dez/2026","team":"Goiás","appearances":28,"goals":3,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('747cb968-a339-586c-94cf-583a3e0c3296'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'baldoria', '{"period":"fev/2025–atual","team":"Goiás","appearances":31,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('140ba628-c222-53a5-8621-a774092a125b'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'halerrandrio', '{"period":"abr/2023–atual","team":"Goiás","appearances":12,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'harlei', '{"period":"1999-2014","team":"Goiás","appearances":831,"goals":0,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'iarley', '{"club":"Goiás","spells":["2008-2009","2011-2012"],"appearances":173,"goals":47,"note":"Total histórico local; não atribuir a uma passagem isolada."}'::jsonb, 'PRIMARY', null::date),
    ('424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'jean_carlos', '{"period":"fev/2025–atual","team":"Goiás","appearances":47,"goals":4,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'lourenco', '{"period":"jan/2026–atual","team":"Goiás","appearances":35,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'josue', '{"period":"1997-2004","team":"Goiás","appearances":386,"goals":10,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('d58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'lucas_lima', '{"period":"jan/2026–atual","team":"Goiás","appearances":32,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('36ed37b5-02be-5117-91d6-a62d5236505f'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'lucas_ribeiro', '{"period":"abr/2024–atual","team":"Goiás","appearances":104,"goals":3,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'lucas_rodrigues', '{"period":"fev/2025–atual","team":"Goiás","appearances":26,"goals":4,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'luisao', '{"period":"jan/2026–dez/2026","team":"Goiás","appearances":26,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'felipe_clemente', '{"period":"ago/2026–dez/2026","team":"Goiás","appearances":0,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":"Chegou por empréstimo em 21/08/2026; snapshot antes de estreia oficial pelo Goiás."}'::jsonb, 'PRIMARY', null::date),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', '43d3d136-b00e-5393-a108-82adeef94fce'::uuid, 'SPELL', 'squad_members_club_history', 'luiz_felipe', '{"period":"jan/2025–nov/2025","team":"Goiás","appearances":19,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', '69dd430f-2090-562f-bcc4-bdcfb19e6ae2'::uuid, 'SPELL', 'squad_members_club_history', 'luiz_felipe', '{"period":"jan/2026–atual","team":"Goiás","appearances":26,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'luiz_felipe:jan/2025–nov/2025', '{"period":"jan/2025–nov/2025","team":"Goiás","appearances":19,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'DERIVED_COMPONENT', null::date),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'luiz_felipe:jan/2026–atual', '{"period":"jan/2026–atual","team":"Goiás","appearances":26,"goals":1,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'DERIVED_COMPONENT', null::date),
    ('ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'filipe_machado', '{"period":"jan/2026–nov/2026","team":"Goiás","appearances":32,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'marcos_vinicius', '{"period":"ago/2026–atual","team":"Goiás","appearances":4,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'michael', '{"period":"2017-2019","team":"Goiás","appearances":129,"goals":24,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', 'cc08f610-8dc7-5e5a-b4e4-f5059f3763f6'::uuid, 'SPELL', 'squad_members_club_history', 'murilo_camara', '{"period":"fev/2025–dez/2025","team":"Goiás","appearances":2,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', 'abf80090-af12-521a-b764-70c0d43058ff'::uuid, 'SPELL', 'squad_members_club_history', 'murilo_camara', '{"period":"mar/2026–atual","team":"Goiás","appearances":1,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'murilo_camara:fev/2025–dez/2025', '{"period":"fev/2025–dez/2025","team":"Goiás","appearances":2,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'DERIVED_COMPONENT', null::date),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'murilo_camara:mar/2026–atual', '{"period":"mar/2026–atual","team":"Goiás","appearances":1,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'DERIVED_COMPONENT', null::date),
    ('a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'nicolas', '{"period":"jan/2026–atual","team":"Goiás","appearances":38,"goals":2,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'paulo_baier', '{"club":"Goiás","spells":["2004-2005","2007-2008"],"appearances":177,"goals":78,"note":"Gols seguem total histórico local do projeto; base secundária diverge."}'::jsonb, 'PRIMARY', null::date),
    ('879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'pedrinho', '{"period":"mai/2022–atual","team":"Goiás","appearances":96,"goals":6,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('16d026a7-49b3-5257-9daa-30601e3ef357'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'rafael_moura', '{"club":"Goiás","spells":["2010","2019-2020"],"appearances":120,"goals":49,"note":"Há divergência de escopo em fontes; valor preservado do ledger consolidado do projeto."}'::jsonb, 'PRIMARY', null::date),
    ('b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'rafael_toloi', '{"period":"2008-2012","team":"Goiás","appearances":150,"goals":18,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('d30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'ramon_menezes', '{"period":"mar/2026–dez/2026","team":"Goiás","appearances":13,"goals":0,"loan":true,"is_goias":true,"data_quality":"verified","notes":"Total é snapshot da tabela de carreira; pode variar conforme atualização da fonte."}'::jsonb, 'PRIMARY', null::date),
    ('4b153bcc-657a-5007-8c20-48c04130a484'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'ricardo_goulart', '{"period":"2012","team":"Goiás","appearances":63,"goals":25,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'rodrigo_soares', '{"period":"jan/2026–atual","team":"Goiás","appearances":37,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'rodrigo_tabata', '{"period":"2004-2005","team":"Goiás","appearances":87,"goals":28,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('e2507d62-8cb5-5152-af56-f67464196ac6'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'override_live_data_baseline', 'tadeu_annotation', '{"personCanonicalName":"Tadeu Antônio Ferreira","clubSlug":"goias","appearances":400,"asOfDate":"2026-08-28","asOfMatchId":"pe_cb52680435343cc4","source":"manual_verified","supersedes":{"value":398,"sourceTable":"squad_members","note":"snapshot desatualizado, não incorreto — só anterior à partida de 28/08/2026"}}'::jsonb, 'BASELINE', '2026-08-28'::date),
    ('0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'thiago_rodrigues', '{"period":"jan/2024–atual","team":"Goiás","appearances":10,"goals":0,"loan":false,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'walter', '{"club":"Goiás","spells":["2012-2013","2016-2017"],"appearances":97,"goals":48,"note":"Total histórico local; há ledger com 98/48."}'::jsonb, 'PRIMARY', null::date),
    ('828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, 'goias', '40354072-1a71-50a3-867c-7a96c7af4f18'::uuid, 'SPELL', 'override_spell_model_implication', 'walter_annotation:2', '{"period":"2019","registrationType":"permanent","appearancesKnown":true,"appearances":0,"note":"Integrado ao elenco, suspensão por doping ampliada antes da reestreia — passagem real com 0 jogos, não pendência de verificação."}'::jsonb, 'PRIMARY', null::date),
    ('4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'squad_members_club_history', 'wellington_rato', '{"period":"jul/2025–dez/2026","team":"Goiás","appearances":22,"goals":2,"loan":true,"is_goias":true,"data_quality":"verified","notes":null}'::jsonb, 'PRIMARY', null::date),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_aggregate_stats', 'welliton', '{"club":"Goiás","spells":["2005-2007","2021"],"appearances":61,"goals":22,"note":null}'::jsonb, 'PRIMARY', null::date),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', '81e06be3-b0eb-5f57-be88-33ff1c108854'::uuid, 'SPELL', 'career_players_club_career', 'welliton', '{"period":"2005-2007","team":"Goiás","appearances":53,"goals":21,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', '8b0aa269-c377-52be-bb29-95a0dc69658d'::uuid, 'SPELL', 'career_players_club_career', 'welliton', '{"period":"2021","team":"Goiás","appearances":8,"goals":1,"loan":false,"is_goias":true}'::jsonb, 'PRIMARY', null::date),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'welliton:2005-2007', '{"period":"2005-2007","team":"Goiás","appearances":53,"goals":21,"loan":false,"is_goias":true}'::jsonb, 'CORROBORATING', null::date),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'goias', null::uuid, 'CLUB_TOTAL', 'career_players_club_career', 'welliton:2021', '{"period":"2021","team":"Goiás","appearances":8,"goals":1,"loan":false,"is_goias":true}'::jsonb, 'CORROBORATING', null::date)
) as v(person_id, club_slug, spell_id, stats_scope, source_type, source_ref, raw_value, source_role, as_of_date)
left join public.clubs c on c.slug = v.club_slug
join public.player_club_stats pcstat
  on pcstat.stats_scope = v.stats_scope
  and (v.stats_scope = 'SPELL' and pcstat.spell_id = v.spell_id
       or v.stats_scope = 'CLUB_TOTAL' and pcstat.person_id = v.person_id and pcstat.club_id = c.id)
on conflict (player_club_stat_id, source_type, source_ref) do nothing;
