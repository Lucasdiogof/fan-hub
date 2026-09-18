-- Lote gerado automaticamente a partir de tooling/bragantino_passport/
-- source/bragantino_passport_2003.json (node generate_seed_sql.mjs 2003) —
-- nunca edite este arquivo à mão, regenere a partir do JSON fonte.
--
-- Rode no projeto Supabase do BRAGANTINO — NÃO no do Goiás — nesta ordem:
--   1. bragantino_passport_infra.sql       (colunas de enriquecimento)
--   2. bragantino_passport_venues_seed.sql (catálogo de estádios)
--   3. este arquivo
-- Idempotente (ON CONFLICT DO UPDATE): reexecutar atualiza, nunca duplica, e
-- não encosta em presença de usuário.

insert into public.passport_matches (
  id, season, match_date, match_time, status, competition, competition_code, competition_edition, round, phase_status, opponent, club_is_home, neutral_site, home_team, away_team, home_score, away_score, club_score, opponent_score, score_display, outcome, stadium, stadium_status, venue_id, weekday, day_type, day_period, kickoff_at, display_timezone, date_precision, source_provider, source_match_id, source_url, source_confidence, data_notes
) values
  ('pb_ogol_8830982', 2003, '2003-01-30', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Sãocarlense', false, false, 'Sãocarlense', 'Red Bull Bragantino', 0, 1, 1, 0, '0–1', 'WIN', null, 'UNKNOWN', null, 'quinta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-01-30 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830982', 'https://www.ogol.com.br/jogo/2003-01-30-saocarlense-red-bull-bragantino/8830982', 'HIGH', null),
  ('pb_ogol_8830983', 2003, '2003-02-01', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São Bento', false, false, 'São Bento', 'Red Bull Bragantino', 4, 1, 1, 4, '4–1', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'NIGHT', (timestamp '2003-02-01 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830983', 'https://www.ogol.com.br/jogo/2003-02-01-sao-bento-red-bull-bragantino/8830983', 'HIGH', null),
  ('pb_ogol_8830988', 2003, '2003-02-05', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Matonense', true, false, 'Red Bull Bragantino', 'Matonense', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-02-05 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830988', 'https://www.ogol.com.br/jogo/2003-02-05-red-bull-bragantino-matonense/8830988', 'HIGH', null),
  ('pb_ogol_8830992', 2003, '2003-02-09', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Flamengo-SP', true, false, 'Red Bull Bragantino', 'Flamengo-SP', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-02-09 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830992', 'https://www.ogol.com.br/jogo/2003-02-09-red-bull-bragantino-flamengo-sp/8830992', 'HIGH', null),
  ('pb_ogol_8830977', 2003, '2003-02-11', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Atlético Sorocaba', true, false, 'Red Bull Bragantino', 'Atlético Sorocaba', 2, 2, 2, 2, '2–2', 'DRAW', null, 'UNKNOWN', null, 'terça-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-02-11 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830977', 'https://www.ogol.com.br/jogo/2003-02-11-red-bull-bragantino-atletico-sorocaba/8830977', 'HIGH', null),
  ('pb_ogol_8830998', 2003, '2003-02-13', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São José', false, false, 'São José', 'Red Bull Bragantino', 2, 1, 1, 2, '2–1', 'LOSS', null, 'UNKNOWN', null, 'quinta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-02-13 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830998', 'https://www.ogol.com.br/jogo/2003-02-13-sao-jose-red-bull-bragantino/8830998', 'HIGH', null),
  ('pb_ogol_8831002', 2003, '2003-02-16', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Nacional-SP', true, false, 'Red Bull Bragantino', 'Nacional-SP', 4, 3, 4, 3, '4–3', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-02-16 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831002', 'https://www.ogol.com.br/jogo/2003-02-16-red-bull-bragantino-nacional-sp/8831002', 'HIGH', null),
  ('pb_ogol_8831004', 2003, '2003-02-19', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Matonense', false, false, 'Matonense', 'Red Bull Bragantino', 2, 0, 0, 2, '2–0', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-02-19 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831004', 'https://www.ogol.com.br/jogo/2003-02-19-matonense-red-bull-bragantino/8831004', 'HIGH', null),
  ('pb_ogol_8831010', 2003, '2003-02-23', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São Bento', true, false, 'Red Bull Bragantino', 'São Bento', 2, 1, 2, 1, '2–1', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-02-23 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831010', 'https://www.ogol.com.br/jogo/2003-02-23-red-bull-bragantino-sao-bento/8831010', 'HIGH', null),
  ('pb_ogol_8831014', 2003, '2003-02-26', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Sãocarlense', true, false, 'Red Bull Bragantino', 'Sãocarlense', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-02-26 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831014', 'https://www.ogol.com.br/jogo/2003-02-26-red-bull-bragantino-saocarlense/8831014', 'HIGH', null),
  ('pb_ogol_8831017', 2003, '2003-03-01', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Atlético Sorocaba', false, false, 'Atlético Sorocaba', 'Red Bull Bragantino', 2, 1, 1, 2, '2–1', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'NIGHT', (timestamp '2003-03-01 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831017', 'https://www.ogol.com.br/jogo/2003-03-01-atletico-sorocaba-red-bull-bragantino/8831017', 'HIGH', null),
  ('pb_ogol_8831020', 2003, '2003-03-09', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Flamengo-SP', false, false, 'Flamengo-SP', 'Red Bull Bragantino', 2, 0, 0, 2, '2–0', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-03-09 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831020', 'https://www.ogol.com.br/jogo/2003-03-09-flamengo-sp-red-bull-bragantino/8831020', 'HIGH', null),
  ('pb_ogol_8831025', 2003, '2003-03-12', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São José', true, false, 'Red Bull Bragantino', 'São José', 1, 4, 1, 4, '1–4', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-03-12 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831025', 'https://www.ogol.com.br/jogo/2003-03-12-red-bull-bragantino-sao-jose/8831025', 'HIGH', null),
  ('pb_ogol_8831030', 2003, '2003-03-16', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Nacional-SP', false, false, 'Nacional-SP', 'Red Bull Bragantino', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-03-16 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8831030', 'https://www.ogol.com.br/jogo/2003-03-16-nacional-sp-red-bull-bragantino/8831030', 'HIGH', null),
  ('pb_ogol_6463127', 2003, '2003-09-17', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Rio Branco de Andradas', false, false, 'Rio Branco de Andradas', 'Red Bull Bragantino', 3, 1, 1, 3, '3–1', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-09-17 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463127', 'https://www.ogol.com.br/jogo/2003-09-17-rio-branco-de-andradas-red-bull-bragantino/6463127', 'HIGH', null),
  ('pb_ogol_6463128', 2003, '2003-09-21', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Uberaba', true, false, 'Red Bull Bragantino', 'Uberaba', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-09-21 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463128', 'https://www.ogol.com.br/jogo/2003-09-21-red-bull-bragantino-uberaba/6463128', 'HIGH', null),
  ('pb_ogol_6463131', 2003, '2003-10-01', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Uberaba', false, false, 'Uberaba', 'Red Bull Bragantino', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-10-01 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463131', 'https://www.ogol.com.br/jogo/2003-10-01-uberaba-red-bull-bragantino/6463131', 'HIGH', null),
  ('pb_ogol_6463132', 2003, '2003-10-05', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Rio Branco de Andradas', true, false, 'Red Bull Bragantino', 'Rio Branco de Andradas', 3, 1, 3, 1, '3–1', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-10-05 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463132', 'https://www.ogol.com.br/jogo/2003-10-05-red-bull-bragantino-rio-branco-de-andradas/6463132', 'HIGH', null),
  ('pb_ogol_6463252', 2003, '2003-10-12', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Estrela do Norte', false, false, 'Estrela do Norte', 'Red Bull Bragantino', 2, 2, 2, 2, '2–2', 'DRAW', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-10-12 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463252', 'https://www.ogol.com.br/jogo/2003-10-12-estrela-do-norte-red-bull-bragantino/6463252', 'HIGH', null),
  ('pb_ogol_6463277', 2003, '2003-10-15', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Estrela do Norte', true, false, 'Red Bull Bragantino', 'Estrela do Norte', 2, 0, 2, 0, '2–0', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-10-15 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463277', 'https://www.ogol.com.br/jogo/2003-10-15-red-bull-bragantino-estrela-do-norte/6463277', 'HIGH', null),
  ('pb_ogol_6463298', 2003, '2003-10-22', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Rio Branco de Andradas', true, false, 'Red Bull Bragantino', 'Rio Branco de Andradas', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-10-22 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463298', 'https://www.ogol.com.br/jogo/2003-10-22-red-bull-bragantino-rio-branco-de-andradas/6463298', 'HIGH', null),
  ('pb_ogol_6463312', 2003, '2003-10-26', '20:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Rio Branco de Andradas', false, false, 'Rio Branco de Andradas', 'Red Bull Bragantino', 1, 2, 2, 1, '1–2', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-10-26 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463312', 'https://www.ogol.com.br/jogo/2003-10-26-rio-branco-de-andradas-red-bull-bragantino/6463312', 'HIGH', null),
  ('pb_ogol_6463324', 2003, '2003-11-02', '21:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Tupi', true, false, 'Red Bull Bragantino', 'Tupi', 3, 1, 3, 1, '3–1', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-11-02 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463324', 'https://www.ogol.com.br/jogo/2003-11-02-red-bull-bragantino-tupi/6463324', 'HIGH', null),
  ('pb_ogol_6463329', 2003, '2003-11-05', '21:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Tupi', false, false, 'Tupi', 'Red Bull Bragantino', 1, 0, 0, 1, '1–0', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-11-05 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463329', 'https://www.ogol.com.br/jogo/2003-11-05-tupi-red-bull-bragantino/6463329', 'HIGH', null),
  ('pb_ogol_6463335', 2003, '2003-11-09', '21:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Santo André', false, false, 'Santo André', 'Red Bull Bragantino', 4, 1, 1, 4, '4–1', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2003-11-09 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463335', 'https://www.ogol.com.br/jogo/2003-11-09-santo-andre-red-bull-bragantino/6463335', 'HIGH', null),
  ('pb_ogol_6463339', 2003, '2003-11-12', '21:00:00', 'FINISHED', 'Brasileirão Série C', 'BRASILEIRAO_C', 'Série C 2003', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Santo André', true, false, 'Red Bull Bragantino', 'Santo André', 3, 1, 3, 1, '3–1', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2003-11-12 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '6463339', 'https://www.ogol.com.br/jogo/2003-11-12-red-bull-bragantino-santo-andre/6463339', 'HIGH', null)
on conflict (id) do update set
    season = excluded.season,
    match_date = excluded.match_date,
    match_time = excluded.match_time,
    status = excluded.status,
    competition = excluded.competition,
    competition_code = excluded.competition_code,
    competition_edition = excluded.competition_edition,
    round = excluded.round,
    phase_status = excluded.phase_status,
    opponent = excluded.opponent,
    club_is_home = excluded.club_is_home,
    neutral_site = excluded.neutral_site,
    home_team = excluded.home_team,
    away_team = excluded.away_team,
    home_score = excluded.home_score,
    away_score = excluded.away_score,
    club_score = excluded.club_score,
    opponent_score = excluded.opponent_score,
    score_display = excluded.score_display,
    outcome = excluded.outcome,
    stadium = excluded.stadium,
    stadium_status = excluded.stadium_status,
    venue_id = excluded.venue_id,
    weekday = excluded.weekday,
    day_type = excluded.day_type,
    day_period = excluded.day_period,
    kickoff_at = excluded.kickoff_at,
    display_timezone = excluded.display_timezone,
    date_precision = excluded.date_precision,
    source_provider = excluded.source_provider,
    source_match_id = excluded.source_match_id,
    source_url = excluded.source_url,
    source_confidence = excluded.source_confidence,
    data_notes = excluded.data_notes,
    updated_at = now();

do $$
declare v_orphans int;
begin
  select count(*) into v_orphans from public.passport_matches
   where season = 2003 and stadium is not null and venue_id is null;
  if v_orphans > 0 then
    raise exception 'ha % partidas de 2003 com estadio sem venue_id -- rode bragantino_passport_venues_seed.sql', v_orphans;
  end if;
end $$;
