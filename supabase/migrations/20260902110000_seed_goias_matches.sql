-- ============================================================================
-- Seed de `public.matches` + `public.match_source_refs` — SOMENTE as 31
-- partidas de lineup_matches.json (Adivinhe a Escalação), a única fonte
-- histórica curada de escalação que este projeto tem hoje. GERADA por
-- tooling/multiclub/generate_matches_seed.mjs a partir de
-- tooling/multiclub/build_matches_seed.mjs — NUNCA editar à mão.
--
-- matches.id é LITERAL, do match registry (tooling/multiclub/matches_
-- registry.json) — nunca gen_random_uuid(). match_source_refs também usa
-- o matchId literal direto, sem JOIN.
--
-- kickoff_date é NULL quando kickoff_precision IN ('YEAR','MONTH') — NUNCA
-- um sentinela "YYYY-01-01"/"YYYY-MM-01" persistido. Ordenação desta
-- migration usa o início do intervalo real de cada precisão (ver
-- kickoff_precision.mjs), nunca a coluna kickoff_date sozinha.
--
-- passport_match_id linkado (via match_source_refs, source_namespace=
-- 'goias_passport') só quando existe candidato ÚNICO em passport_matches
-- por (data, oponente) — ver match_identity_audit.json e matches_seed_
-- stats.json (blockedAmbiguousMatch) pros casos com 2+ candidatos, nunca
-- linkados automaticamente.
--
-- Idempotência: ON CONFLICT (id) DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.matches (
  id, home_club_id, away_club_id, home_team_name, away_team_name,
  kickoff_year, kickoff_month, kickoff_date, kickoff_at, kickoff_precision,
  competition, season, home_score, away_score, verification_status, data_notes
)
select v.id, hc.id, ac.id, v.home_team_name, v.away_team_name,
       v.kickoff_year, v.kickoff_month, v.kickoff_date, v.kickoff_at, v.kickoff_precision,
       v.competition, v.season, v.home_score, v.away_score, v.verification_status, v.data_notes
from (
  values
    ('a03cae2d-062a-56de-95c5-a740abb79517'::uuid, 'goias', null, 'Goiás', 'Flamengo', 1990, 11, '1990-11-07'::date, null, 'DATE', 'Copa do Brasil', '1990', 0, 0, 'VERIFIED', null),
    ('9099c65b-8fcb-57d1-a6bd-65ff5d9a7b6a'::uuid, 'goias', null, 'Goiás', 'Guarani', 1996, 11, '1996-11-27'::date, null, 'DATE', 'Campeonato Brasileiro Série A', '1996', 3, 1, 'VERIFIED', null),
    ('d9a23f58-f510-5c3b-9a01-830484afa34d'::uuid, null, 'goias', 'Grêmio', 'Goiás', 1996, 12, '1996-12-08'::date, null, 'DATE', 'Campeonato Brasileiro Série A', '1996', 2, 2, 'VERIFIED', null),
    ('2f1bbabe-e6ed-5e6b-9f2b-5de3c2921458'::uuid, 'goias', null, 'Goiás', 'Santa Cruz', 1999, 12, '1999-12-12'::date, null, 'DATE', 'Campeonato Brasileiro Série B', '1999', 0, 0, 'VERIFIED', null),
    ('56d56e70-5c18-5797-adf8-16d107fa28bb'::uuid, 'goias', null, 'Goiás', 'Fluminense', 2003, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série A', '2003', 6, 1, 'PARTIAL', 'Data em lineup_matches.match_date ("2003-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('3223c44c-2ca5-5de9-8a95-e13324216dc1'::uuid, 'goias', null, 'Goiás', 'Juventude', 2003, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série A', '2003', 7, 0, 'PARTIAL', 'Data em lineup_matches.match_date ("2003-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('85863207-3408-5312-bcae-4ae904150572'::uuid, 'goias', null, 'Goiás', 'Santos', 2003, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série A', '2003', 3, 0, 'PARTIAL', 'Data em lineup_matches.match_date ("2003-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('36f08f38-be62-552b-ae53-1f746ead75a0'::uuid, 'goias', null, 'Goiás', 'Athletico-PR', 2005, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série A', '2005', 4, 2, 'PARTIAL', 'Data em lineup_matches.match_date ("2005-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('9403f088-d984-5cbe-8fb7-0c4e7500df4e'::uuid, 'goias', null, 'Goiás', 'Corinthians', 2005, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série A', '2005', 3, 2, 'PARTIAL', 'Data em lineup_matches.match_date ("2005-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('2329418e-5027-591c-a117-af085e255027'::uuid, 'goias', null, 'Goiás', 'Ponte Preta', 2005, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série A', '2005', 4, 1, 'PARTIAL', 'Data em lineup_matches.match_date ("2005-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('940dc66b-c7b3-5769-8e1e-b7d06361a343'::uuid, 'goias', null, 'Goiás', 'São Paulo', 2005, 11, '2005-11-16'::date, '2005-11-16T20:30:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série A', '2005', 3, 0, 'VERIFIED', null),
    ('84815132-0ade-5cb2-b017-e2f049c4e18f'::uuid, null, 'goias', 'Newell''s Old Boys', 'Goiás', 2006, null, null::date, null, 'YEAR', 'Copa Libertadores', '2006', 0, 0, 'PARTIAL', 'Data em lineup_matches.match_date ("2006-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('8b3f4a36-c877-561e-a6fc-e3a9b34be1ce'::uuid, 'goias', null, 'Goiás', 'Deportivo Cuenca', 2006, 2, '2006-02-01'::date, '2006-02-01T20:30:00'::timestamptz, 'DATETIME', 'Copa Libertadores', '2006', 3, 0, 'VERIFIED', null),
    ('ad35207e-af8c-5aeb-b873-a1efba5c4680'::uuid, 'goias', null, 'Goiás', 'Estudiantes', 2006, 5, '2006-05-04'::date, '2006-05-04T19:15:00'::timestamptz, 'DATETIME', 'Copa Libertadores', '2006', 3, 1, 'VERIFIED', null),
    ('7a6288eb-0cd0-5903-8d05-83dc261f5015'::uuid, null, 'goias', 'Palmeiras', 'Goiás', 2010, 11, '2010-11-24'::date, '2010-11-24T21:50:00'::timestamptz, 'DATETIME', 'Copa Sul-Americana', '2010', 1, 2, 'VERIFIED', null),
    ('8b85a8ae-9ab4-5296-bfaa-902d6f5ceab8'::uuid, 'goias', null, 'Goiás', 'Independiente', 2010, 12, '2010-12-01'::date, '2010-12-01T22:00:00'::timestamptz, 'DATETIME', 'Copa Sul-Americana', '2010', 2, 0, 'VERIFIED', null),
    ('ad4be142-68c9-5ab3-a313-1fef33fb73a4'::uuid, null, 'goias', 'Independiente', 'Goiás', 2010, 12, '2010-12-08'::date, '2010-12-08T21:00:00'::timestamptz, 'DATETIME', 'Copa Sul-Americana', '2010', 3, 1, 'VERIFIED', null),
    ('058d666e-aa84-58d9-b19b-a6ff3ccef4ec'::uuid, 'goias', null, 'Goiás', 'Guarani', 2012, null, null::date, null, 'YEAR', 'Campeonato Brasileiro Série B', '2012', 5, 0, 'PARTIAL', 'Data em lineup_matches.match_date ("2012-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('d66fb88a-3c5f-5460-9ff4-ec8ca9cf5de9'::uuid, 'goias', null, 'Goiás', 'Joinville', 2012, 11, '2012-11-24'::date, '2012-11-24T16:20:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série B', '2012', 2, 1, 'VERIFIED', null),
    ('e2aab068-3555-5bbf-b99b-2ce45dbb1972'::uuid, 'goias', null, 'Goiás', 'Vasco', 2013, null, null::date, null, 'YEAR', 'Copa do Brasil', '2013', 2, 1, 'PARTIAL', 'Data em lineup_matches.match_date ("2013-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('fea69f06-3354-5960-9ce4-3f9ef0a48393'::uuid, null, 'goias', 'Vasco', 'Goiás', 2013, null, null::date, null, 'YEAR', 'Copa do Brasil', '2013', 3, 2, 'PARTIAL', 'Data em lineup_matches.match_date ("2013-01-01") tem padrão de placeholder ANO-01-01 (mês E dia fabricados) e não há link passport_matches pra confirmar — precisão rebaixada pra YEAR, kickoff_date fica NULL (nunca um sentinela).'),
    ('1e3855de-7bcf-59ec-baf0-978bc8cda659'::uuid, 'goias', null, 'Goiás', 'Fluminense', 2013, 8, '2013-08-28'::date, '2013-08-28T19:30:00'::timestamptz, 'DATETIME', 'Copa do Brasil', '2013', 2, 0, 'VERIFIED', null),
    ('f8e9e61a-2fd5-5152-94e7-4d842917c02f'::uuid, 'goias', null, 'Goiás', 'Aparecidense', 2018, 4, '2018-04-08'::date, '2018-04-08T16:00:00'::timestamptz, 'DATETIME', 'Campeonato Goiano', '2018', 3, 1, 'VERIFIED', null),
    ('cc8d583b-42c1-5f1f-9cbe-31e83d52c2bc'::uuid, 'goias', null, 'Goiás', 'CSA', 2021, 10, '2021-10-15'::date, '2021-10-15T21:30:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série B', '2021', 3, 1, 'VERIFIED', null),
    ('0b06ee45-884c-5a3d-b80a-ac341d203f74'::uuid, null, 'goias', 'Guarani', 'Goiás', 2021, 11, '2021-11-22'::date, '2021-11-22T20:00:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série B', '2021', 0, 2, 'VERIFIED', null),
    ('9559c821-6e12-5b5a-bb91-fa14baefd84c'::uuid, 'goias', null, 'Goiás', 'Corinthians', 2023, 4, '2023-04-23'::date, '2023-04-23T19:00:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série A', '2023', 3, 1, 'VERIFIED', null),
    ('b43c29e9-ade3-5094-a48b-ec3fa574fdb1'::uuid, 'goias', null, 'Goiás', 'Botafogo', 2023, 5, '2023-05-14'::date, '2023-05-14T18:30:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série A', '2023', 2, 1, 'VERIFIED', null),
    ('3d92c7c8-edb0-5154-b5fd-9ca1e7ae7e6a'::uuid, null, 'goias', 'Paysandu', 'Goiás', 2025, 4, '2025-04-09'::date, '2025-04-09T20:00:00'::timestamptz, 'DATETIME', 'Copa Verde', '2025', 0, 0, 'VERIFIED', null),
    ('7a2cca6d-cfc4-5980-b962-c05166163e0d'::uuid, 'goias', null, 'Goiás', 'Cuiabá', 2025, 7, '2025-07-19'::date, '2025-07-19T16:00:00'::timestamptz, 'DATETIME', 'Campeonato Brasileiro Série B', '2025', 3, 1, 'VERIFIED', null),
    ('21078bdc-5503-5062-ab23-164f6548b9dc'::uuid, null, 'goias', 'Atlético-GO', 'Goiás', 2026, 3, '2026-03-07'::date, null, 'DATE', 'Campeonato Goiano', '2026', 0, 2, 'VERIFIED', null),
    ('40c6b119-92cf-5702-bb3f-2f190a322e06'::uuid, 'goias', null, 'Goiás', 'Atlético-GO', 2026, 3, '2026-03-15'::date, null, 'DATE', 'Campeonato Goiano', '2026', 0, 0, 'VERIFIED', null)
) as v(id, home_club_slug, away_club_slug, home_team_name, away_team_name, kickoff_year, kickoff_month, kickoff_date, kickoff_at, kickoff_precision, competition, season, home_score, away_score, verification_status, data_notes)
left join public.clubs hc on hc.slug = v.home_club_slug
left join public.clubs ac on ac.slug = v.away_club_slug
on conflict (id) do nothing;

insert into public.match_source_refs (match_id, source_type, source_namespace, source_ref, source_club_id)
values
  ('a03cae2d-062a-56de-95c5-a740abb79517'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '1990_flamengo_cdb_final_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('d9a23f58-f510-5c3b-9a01-830484afa34d'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '1996_gremio_brA_semi', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('9099c65b-8fcb-57d1-a6bd-65ff5d9a7b6a'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '1996_guarani_brA_quartas', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('2f1bbabe-e6ed-5e6b-9f2b-5de3c2921458'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '1999_santacruz_brB_titulo', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('56d56e70-5c18-5797-adf8-16d107fa28bb'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2003_fluminense_brA_reacao', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('3223c44c-2ca5-5de9-8a95-e13324216dc1'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2003_juventude_brA_reacao', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('85863207-3408-5312-bcae-4ae904150572'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2003_santos_brA_reacao', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('36f08f38-be62-552b-ae53-1f746ead75a0'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2005_athleticopr_brA_3lugar', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('9403f088-d984-5cbe-8fb7-0c4e7500df4e'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2005_corinthians_brA_3lugar', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('2329418e-5027-591c-a117-af085e255027'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2005_pontepreta_brA_3lugar', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('940dc66b-c7b3-5769-8e1e-b7d06361a343'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2005_saopaulo_brA_3lugar', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('940dc66b-c7b3-5769-8e1e-b7d06361a343'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_17d74b2ea9e015d1', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('8b3f4a36-c877-561e-a6fc-e3a9b34be1ce'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2006_cuenca_lib_1fase', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('8b3f4a36-c877-561e-a6fc-e3a9b34be1ce'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_88ef144e0da4d3d2', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('ad35207e-af8c-5aeb-b873-a1efba5c4680'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2006_estudiantes_lib_oitavas_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('ad35207e-af8c-5aeb-b873-a1efba5c4680'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_5874ea43cd176ba9', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('84815132-0ade-5cb2-b017-e2f049c4e18f'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2006_newells_lib_grupos', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('8b85a8ae-9ab4-5296-bfaa-902d6f5ceab8'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2010_independiente_sulamericana_final_ida', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('8b85a8ae-9ab4-5296-bfaa-902d6f5ceab8'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_f2659643432acb89', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('ad4be142-68c9-5ab3-a313-1fef33fb73a4'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2010_independiente_sulamericana_final_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('ad4be142-68c9-5ab3-a313-1fef33fb73a4'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_645af47a1234a92d', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('7a6288eb-0cd0-5903-8d05-83dc261f5015'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2010_palmeiras_sulamericana_semi_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('7a6288eb-0cd0-5903-8d05-83dc261f5015'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_a62fdaf973f98f24', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('058d666e-aa84-58d9-b19b-a6ff3ccef4ec'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2012_guarani_brB_retafinal', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('d66fb88a-3c5f-5460-9ff4-ec8ca9cf5de9'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2012_joinville_brB_titulo', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('d66fb88a-3c5f-5460-9ff4-ec8ca9cf5de9'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_d045a1b785dbf480', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('1e3855de-7bcf-59ec-baf0-978bc8cda659'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2013_fluminense_cdb_oitavas_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('1e3855de-7bcf-59ec-baf0-978bc8cda659'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_43e29e22e41095b6', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('e2aab068-3555-5bbf-b99b-2ce45dbb1972'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2013_vasco_cdb_quartas_ida', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('fea69f06-3354-5960-9ce4-3f9ef0a48393'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2013_vasco_cdb_quartas_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('f8e9e61a-2fd5-5152-94e7-4d842917c02f'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2018_aparecidense_goiano_final_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('f8e9e61a-2fd5-5152-94e7-4d842917c02f'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_fe051cd605ac4b09', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('cc8d583b-42c1-5f1f-9cbe-31e83d52c2bc'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2021_csa_brB_g4', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('cc8d583b-42c1-5f1f-9cbe-31e83d52c2bc'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_26087010ae0b66d6', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('0b06ee45-884c-5a3d-b80a-ac341d203f74'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2021_guarani_brB_acesso', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('0b06ee45-884c-5a3d-b80a-ac341d203f74'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_382ffaa0ed399d2a', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('b43c29e9-ade3-5094-a48b-ec3fa574fdb1'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2023_botafogo_brA_rodada6', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('b43c29e9-ade3-5094-a48b-ec3fa574fdb1'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_9f8a92393fd18710', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('9559c821-6e12-5b5a-bb91-fa14baefd84c'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2023_corinthians_brA_rodada2', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('9559c821-6e12-5b5a-bb91-fa14baefd84c'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_25d23cf4c59101a6', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('7a2cca6d-cfc4-5980-b962-c05166163e0d'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2025_cuiaba_brB_rodada17', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('7a2cca6d-cfc4-5980-b962-c05166163e0d'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_af2020d68d406371', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('3d92c7c8-edb0-5154-b5fd-9ca1e7ae7e6a'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2025_paysandu_copaverde_final_ida', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('3d92c7c8-edb0-5154-b5fd-9ca1e7ae7e6a'::uuid, 'PASSPORT_MATCH', 'goias_passport', 'pe_a44d7062b76636ff', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('21078bdc-5503-5062-ab23-164f6548b9dc'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2026_atleticogo_goiano_final_ida', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid),
  ('40c6b119-92cf-5702-bb3f-2f190a322e06'::uuid, 'LINEUP_MATCH', 'goias_lineup_curated', '2026_atleticogo_goiano_final_volta', '4c16340d-300c-5ab2-903f-17519db9b146'::uuid)
on conflict (source_namespace, source_ref) do nothing;
