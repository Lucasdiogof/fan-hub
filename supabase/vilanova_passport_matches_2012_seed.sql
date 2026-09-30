-- Passaporte do Vila Nova — temporada 2012. GERADO por
-- `node tooling/vilanova_passport/generate_passport_sql.mjs` a partir de
-- docs/vila_nova_data/passport/passport_2012.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do Bragantino.
-- Ordem: vilanova_passport_infra.sql -> vilanova_passport_venues_seed.sql -> ESTE.
-- Idempotente (ON CONFLICT DO UPDATE): reexecutar atualiza, nunca duplica, e
-- não encosta em presença de usuário. 38 partidas.

do $$
begin
  if not exists (select 1 from public.clubs where slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.passport_matches (
  id, season, match_date, match_time, status, competition, competition_code, competition_edition, round, phase_status, opponent, club_is_home, neutral_site, home_team, away_team, home_score, away_score, club_score, opponent_score, score_display, outcome, stadium, stadium_status, venue_id, weekday, day_type, day_period, kickoff_at, display_timezone, date_precision, source_provider, source_match_id, source_url, source_confidence, data_notes
) values
  ('vn_rsssf_go2012_r01', 2012, '2012-01-22', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R1', 'CONFIRMED', 'CRAC', false, false, 'CRAC', 'Vila Nova', 2, 1, 1, 2, '2–1', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r01', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r02', 2012, '2012-01-25', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R2', 'CONFIRMED', 'Rio Verde', true, false, 'Vila Nova', 'Rio Verde', 3, 0, 3, 0, '3–0', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r02', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r03', 2012, '2012-01-28', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R3', 'CONFIRMED', 'Goiás', false, false, 'Goiás', 'Vila Nova', 3, 1, 1, 3, '3–1', 'LOSS', 'Estádio Serra Dourada', 'MATCH_SPECIFIC', 'vn_venue_serra_dourada', 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r03', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r04', 2012, '2012-02-01', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R4', 'CONFIRMED', 'Anapolina', true, false, 'Vila Nova', 'Anapolina', 4, 0, 4, 0, '4–0', 'WIN', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r04', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r05', 2012, '2012-02-05', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R5', 'CONFIRMED', 'Aparecidense', true, false, 'Vila Nova', 'Aparecidense', 1, 3, 1, 3, '1–3', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r05', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r06', 2012, '2012-02-08', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R6', 'CONFIRMED', 'Itumbiara', false, false, 'Itumbiara', 'Vila Nova', 0, 0, 0, 0, '0–0', 'DRAW', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r06', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r07', 2012, '2012-02-11', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R7', 'CONFIRMED', 'Atlético-GO', true, false, 'Vila Nova', 'Atlético-GO', 1, 2, 1, 2, '1–2', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r07', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r08', 2012, '2012-02-22', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R8', 'CONFIRMED', 'Goianésia', true, false, 'Vila Nova', 'Goianésia', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r08', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r09', 2012, '2012-02-27', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R9', 'CONFIRMED', 'Morrinhos', false, false, 'Morrinhos', 'Vila Nova', 0, 4, 4, 0, '0–4', 'WIN', null, 'UNKNOWN', null, 'segunda-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r09', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r10', 2012, '2012-03-01', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R10', 'CONFIRMED', 'Goianésia', false, false, 'Goianésia', 'Vila Nova', 1, 0, 0, 1, '1–0', 'LOSS', null, 'UNKNOWN', null, 'quinta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r10', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r11', 2012, '2012-03-04', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R11', 'CONFIRMED', 'Itumbiara', true, false, 'Vila Nova', 'Itumbiara', 3, 2, 3, 2, '3–2', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r11', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r12', 2012, '2012-03-11', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R12', 'CONFIRMED', 'Atlético-GO', false, false, 'Atlético-GO', 'Vila Nova', 2, 2, 2, 2, '2–2', 'DRAW', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r12', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r13', 2012, '2012-03-18', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R13', 'CONFIRMED', 'Aparecidense', false, false, 'Aparecidense', 'Vila Nova', 0, 2, 2, 0, '0–2', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r13', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r14', 2012, '2012-03-25', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R14', 'CONFIRMED', 'Morrinhos', true, false, 'Vila Nova', 'Morrinhos', 3, 1, 3, 1, '3–1', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r14', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r15', 2012, '2012-03-28', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R15', 'CONFIRMED', 'Anapolina', false, false, 'Anapolina', 'Vila Nova', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'quarta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r15', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r16', 2012, '2012-04-01', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R16', 'CONFIRMED', 'Goiás', true, false, 'Vila Nova', 'Goiás', 3, 2, 3, 2, '3–2', 'WIN', 'Estádio Serra Dourada', 'MATCH_SPECIFIC', 'vn_venue_serra_dourada', 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r16', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r17', 2012, '2012-04-08', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R17', 'CONFIRMED', 'Rio Verde', false, false, 'Rio Verde', 'Vila Nova', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r17', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_r18', 2012, '2012-04-15', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'R18', 'CONFIRMED', 'CRAC', true, false, 'Vila Nova', 'CRAC', 0, 1, 0, 1, '0–1', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r18', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_sf1', 2012, '2012-04-22', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'Semifinal - ida', 'CONFIRMED', 'Goiás', true, false, 'Vila Nova', 'Goiás', 0, 1, 0, 1, '0–1', 'LOSS', 'Estádio Serra Dourada', 'MATCH_SPECIFIC', 'vn_venue_serra_dourada', 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'sf1', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_go2012_sf2', 2012, '2012-04-29', null, 'FINISHED', 'Campeonato Goiano', 'GOIANO', 'Campeonato Goiano 2012', 'Semifinal - volta', 'CONFIRMED', 'Goiás', false, false, 'Goiás', 'Vila Nova', 3, 0, 0, 3, '3–0', 'LOSS', 'Estádio Serra Dourada', 'MATCH_SPECIFIC', 'vn_venue_serra_dourada', 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'sf2', 'https://www.rsssfbrasil.com/tablesfq/go2012.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r01', 2012, '2012-06-30', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R01', 'CONFIRMED', 'Oeste', true, false, 'Vila Nova', 'Oeste', 4, 1, 4, 1, '4–1', 'WIN', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r01', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r02', 2012, '2012-07-08', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R02', 'CONFIRMED', 'Chapecoense', false, false, 'Chapecoense', 'Vila Nova', 3, 2, 2, 3, '3–2', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r02', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r03', 2012, '2012-07-14', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R03', 'CONFIRMED', 'Santo André', false, false, 'Santo André', 'Vila Nova', 0, 0, 0, 0, '0–0', 'DRAW', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r03', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r04', 2012, '2012-07-22', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R04', 'CONFIRMED', 'Duque de Caxias', true, false, 'Vila Nova', 'Duque de Caxias', 4, 1, 4, 1, '4–1', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r04', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r05', 2012, '2012-07-28', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R05', 'CONFIRMED', 'Tupi', true, false, 'Vila Nova', 'Tupi', 0, 0, 0, 0, '0–0', 'DRAW', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r05', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r06', 2012, '2012-08-05', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R06', 'CONFIRMED', 'Caxias', false, false, 'Caxias', 'Vila Nova', 2, 1, 1, 2, '2–1', 'LOSS', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r06', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r07', 2012, '2012-08-12', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R07', 'CONFIRMED', 'Madureira', true, false, 'Vila Nova', 'Madureira', 5, 1, 5, 1, '5–1', 'WIN', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r07', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r08', 2012, '2012-08-18', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R08', 'CONFIRMED', 'Macaé', false, false, 'Macaé', 'Vila Nova', 3, 0, 0, 3, '3–0', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r08', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r09', 2012, '2012-08-25', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R09', 'CONFIRMED', 'Brasiliense', true, false, 'Vila Nova', 'Brasiliense', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r09', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r10', 2012, '2012-08-31', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R10', 'CONFIRMED', 'Oeste', false, false, 'Oeste', 'Vila Nova', 3, 1, 1, 3, '3–1', 'LOSS', null, 'UNKNOWN', null, 'sexta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r10', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r11', 2012, '2012-09-08', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R11', 'CONFIRMED', 'Chapecoense', true, false, 'Vila Nova', 'Chapecoense', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r11', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r12', 2012, '2012-09-16', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R12', 'CONFIRMED', 'Santo André', true, false, 'Vila Nova', 'Santo André', 2, 2, 2, 2, '2–2', 'DRAW', null, 'UNKNOWN', null, 'domingo', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r12', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r13', 2012, '2012-09-22', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R13', 'CONFIRMED', 'Duque de Caxias', false, false, 'Duque de Caxias', 'Vila Nova', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r13', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r14', 2012, '2012-09-29', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R14', 'CONFIRMED', 'Tupi', false, false, 'Tupi', 'Vila Nova', 1, 1, 1, 1, '1–1', 'DRAW', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r14', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r15', 2012, '2012-10-05', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R15', 'CONFIRMED', 'Caxias', true, false, 'Vila Nova', 'Caxias', 0, 1, 0, 1, '0–1', 'LOSS', null, 'UNKNOWN', null, 'sexta-feira', 'WEEKDAY', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r15', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r16', 2012, '2012-10-13', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R16', 'CONFIRMED', 'Madureira', false, false, 'Madureira', 'Vila Nova', 3, 1, 1, 3, '3–1', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r16', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r17', 2012, '2012-10-20', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R17', 'CONFIRMED', 'Macaé', true, false, 'Vila Nova', 'Macaé', 1, 0, 1, 0, '1–0', 'WIN', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r17', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null),
  ('vn_rsssf_sc2012_r18', 2012, '2012-10-27', null, 'FINISHED', 'Série C', 'BRASILEIRO_C', 'Série C 2012', 'R18', 'CONFIRMED', 'Brasiliense', false, false, 'Brasiliense', 'Vila Nova', 4, 2, 2, 4, '4–2', 'LOSS', null, 'UNKNOWN', null, 'sábado', 'WEEKEND', 'UNKNOWN', null, 'America/Sao_Paulo', 'date_only', 'RSSSF Brasil', 'r18', 'https://www.rsssfbrasil.com/tablesae/br2012l3.htm', 'HIGH', null)
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
   where season = 2012 and stadium is not null and venue_id is null;
  if v_orphans > 0 then
    raise exception 'ha % partidas de 2012 com estadio sem venue_id -- rode vilanova_passport_venues_seed.sql antes', v_orphans;
  end if;
end $$;
