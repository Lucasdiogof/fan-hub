-- Lote gerado automaticamente a partir de tooling/bragantino_passport/
-- source/bragantino_passport_2004.json (node generate_seed_sql.mjs 2004) —
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
  ('pb_ogol_8830725', 2004, '2004-01-25', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Flamengo-SP', false, false, 'Flamengo-SP', 'Red Bull Bragantino', 0, 0, 0, 0, '0–0', 'DRAW', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2004-01-25 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830725', 'https://www.ogol.com.br/jogo/2004-01-25-flamengo-sp-red-bull-bragantino/8830725', 'HIGH', null),
  ('pb_ogol_8830729', 2004, '2004-02-01', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São Bento', true, false, 'Red Bull Bragantino', 'São Bento', 0, 1, 0, 1, '0–1', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2004-02-01 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830729', 'https://www.ogol.com.br/jogo/2004-02-01-red-bull-bragantino-sao-bento/8830729', 'HIGH', null),
  ('pb_ogol_8830739', 2004, '2004-02-15', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Inter de Limeira', false, false, 'Inter de Limeira', 'Red Bull Bragantino', 2, 0, 0, 2, '2–0', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2004-02-15 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830739', 'https://www.ogol.com.br/jogo/2004-02-15-inter-de-limeira-red-bull-bragantino/8830739', 'HIGH', null),
  ('pb_ogol_8830742', 2004, '2004-02-21', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Matonense', true, false, 'Red Bull Bragantino', 'Matonense', 1, 2, 1, 2, '1–2', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'NIGHT', (timestamp '2004-02-21 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830742', 'https://www.ogol.com.br/jogo/2004-02-21-red-bull-bragantino-matonense/8830742', 'HIGH', null),
  ('pb_ogol_8830744', 2004, '2004-02-28', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Nacional-SP', false, false, 'Nacional-SP', 'Red Bull Bragantino', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'NIGHT', (timestamp '2004-02-28 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830744', 'https://www.ogol.com.br/jogo/2004-02-28-nacional-sp-red-bull-bragantino/8830744', 'HIGH', null),
  ('pb_ogol_8830749', 2004, '2004-03-03', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Taubaté', true, false, 'Red Bull Bragantino', 'Taubaté', 4, 2, 4, 2, '4–2', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2004-03-03 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830749', 'https://www.ogol.com.br/jogo/2004-03-03-red-bull-bragantino-taubate/8830749', 'HIGH', null),
  ('pb_ogol_8830757', 2004, '2004-03-10', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São Bento', false, false, 'São Bento', 'Red Bull Bragantino', 1, 0, 0, 1, '1–0', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2004-03-10 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830757', 'https://www.ogol.com.br/jogo/2004-03-10-sao-bento-red-bull-bragantino/8830757', 'HIGH', null),
  ('pb_ogol_8830761', 2004, '2004-03-13', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São José', false, false, 'São José', 'Red Bull Bragantino', 0, 1, 1, 0, '0–1', 'WIN', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'NIGHT', (timestamp '2004-03-13 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830761', 'https://www.ogol.com.br/jogo/2004-03-13-sao-jose-red-bull-bragantino/8830761', 'HIGH', null),
  ('pb_ogol_8830735', 2004, '2004-03-17', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'São José', true, false, 'Red Bull Bragantino', 'São José', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2004-03-17 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830735', 'https://www.ogol.com.br/jogo/2004-03-17-red-bull-bragantino-sao-jose/8830735', 'HIGH', null),
  ('pb_ogol_8830765', 2004, '2004-03-20', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Inter de Limeira', true, false, 'Red Bull Bragantino', 'Inter de Limeira', 2, 3, 2, 3, '2–3', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'NIGHT', (timestamp '2004-03-20 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830765', 'https://www.ogol.com.br/jogo/2004-03-20-red-bull-bragantino-inter-de-limeira/8830765', 'HIGH', null),
  ('pb_ogol_8830771', 2004, '2004-03-24', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Matonense', false, false, 'Matonense', 'Red Bull Bragantino', 2, 1, 1, 2, '2–1', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2004-03-24 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830771', 'https://www.ogol.com.br/jogo/2004-03-24-matonense-red-bull-bragantino/8830771', 'HIGH', null),
  ('pb_ogol_8830774', 2004, '2004-03-28', '21:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Nacional-SP', true, false, 'Red Bull Bragantino', 'Nacional-SP', 0, 3, 0, 3, '0–3', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2004-03-28 21:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830774', 'https://www.ogol.com.br/jogo/2004-03-28-red-bull-bragantino-nacional-sp/8830774', 'HIGH', null),
  ('pb_ogol_8830755', 2004, '2004-03-31', '20:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Flamengo-SP', true, false, 'Red Bull Bragantino', 'Flamengo-SP', 1, 2, 1, 2, '1–2', 'LOSS', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'NIGHT', (timestamp '2004-03-31 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830755', 'https://www.ogol.com.br/jogo/2004-03-31-red-bull-bragantino-flamengo-sp/8830755', 'HIGH', null),
  ('pb_ogol_8830779', 2004, '2004-04-04', '20:00:00', 'FINISHED', 'Paulista Série A2', 'PAULISTA_A2', 'Paulista A2 2004', null, 'ROUND_NOT_EXPOSED_BY_SOURCE', 'Taubaté', false, false, 'Taubaté', 'Red Bull Bragantino', 3, 1, 1, 3, '3–1', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'NIGHT', (timestamp '2004-04-04 20:00:00' at time zone 'America/Sao_Paulo'), 'America/Sao_Paulo', 'datetime', 'oGol (ogol.com.br)', '8830779', 'https://www.ogol.com.br/jogo/2004-04-04-taubate-red-bull-bragantino/8830779', 'HIGH', null)
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
   where season = 2004 and stadium is not null and venue_id is null;
  if v_orphans > 0 then
    raise exception 'ha % partidas de 2004 com estadio sem venue_id -- rode bragantino_passport_venues_seed.sql', v_orphans;
  end if;
end $$;
