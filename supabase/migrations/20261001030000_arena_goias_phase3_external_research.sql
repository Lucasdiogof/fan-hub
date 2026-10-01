-- ============================================================================
-- Auditoria da Arena do Goiás — fase 3: resultados da pesquisa externa
-- (pesquisa externa, 2026-10-01) conferidos item a item contra as fichas de jogo e os
-- perfis do ogol.com.br. Aprovado pelo usuário em 2026-10-01.
--
-- Só entram os itens marcados APLICAR e CORRIGIR PREMISSA. Ficam DE FORA
-- (pendentes, de propósito): data do Goiás 3x0 Santos 2003 (29/11 × 30/11),
-- escalação do Athletico-PR 2005 (André Leone × Luciano Almeida), posição do
-- Dalton, estreias de Gustavo/Renato Silva/Evandro, identidades abertas
-- (Marcões, Michael 1999, Josué 1987-91, Hugo 2010/11), registros vazios do
-- Manto, camisas de Amaral/Ramón/Dill, clube formador e fotos.
--
-- Regras:
--   * data real só onde pesquisa + ficha do ogol batem em data, placar,
--     mando e nos 11 titulares;
--   * estádio só onde as duas fontes o citam;
--   * nenhum status vira verified/VERIFIED; a canônica `matches` ganha a
--     data, mas o status continua o que era;
--   * cada bloco tem pré-condição com o valor atual exato — se o banco
--     estiver diferente, a transação inteira é revertida.
-- ============================================================================

-- ------------------------------------------------------------ pré-condições
do $$
declare v text;
begin
  -- 1) escalações: data/estádio/fase atuais
  select string_agg(e.id, ', ') into v
  from (values
    ('2003_juventude_brA_reacao',          date '2003-01-01', 'Goiás', 7, 0, 'Juventude'),
    ('2003_fluminense_brA_reacao',         date '2003-01-01', 'Goiás', 6, 1, 'Fluminense'),
    ('2005_pontepreta_brA_3lugar',         date '2005-01-01', 'Goiás', 4, 1, 'Ponte Preta'),
    ('2005_athleticopr_brA_3lugar',        date '2005-01-01', 'Goiás', 4, 2, 'Athletico-PR'),
    ('2005_corinthians_brA_3lugar',        date '2005-01-01', 'Goiás', 3, 2, 'Corinthians'),
    ('2006_newells_lib_grupos',            date '2006-01-01', 'Newell''s Old Boys', 0, 0, 'Goiás'),
    ('2006_cuenca_lib_1fase',              date '2006-02-01', 'Goiás', 3, 0, 'Deportivo Cuenca'),
    ('2012_guarani_brB_retafinal',         date '2012-01-01', 'Goiás', 5, 0, 'Guarani'),
    ('2013_vasco_cdb_quartas_ida',         date '2013-01-01', 'Goiás', 2, 1, 'Vasco'),
    ('2013_vasco_cdb_quartas_volta',       date '2013-01-01', 'Vasco', 3, 2, 'Goiás'),
    ('1990_flamengo_cdb_final_volta',      date '1990-11-07', 'Goiás', 0, 0, 'Flamengo')
  ) as e(id, d, home, hs, aws, away)
  left join public.lineup_matches m using (id)
  where m.id is null or m.match_date <> e.d or m.home_team <> e.home
     or m.home_score <> e.hs or m.away_score <> e.aws or m.away_team <> e.away
     or m.venue is not null;
  if v is not null then
    raise exception 'lineup_matches fora do estado esperado: % — aborta.', v;
  end if;

  if (select phase from public.lineup_matches where id = '2003_juventude_brA_reacao')
       is distinct from 'Campanha de reação' then
    raise exception 'fase do Goiás x Juventude 2003 não é a esperada — aborta.';
  end if;

  -- 2) Guarani x Goiás 2021: escalação atual exata
  if (select lineup from public.lineup_matches where id = '2021_guarani_brB_acesso') is distinct from '[
    {"no": 1,  "pos": "GOL",   "name": "Tadeu",          "answer": "TADEU",          "aliases": []},
    {"no": 4,  "pos": "ZAG",   "name": "Reynaldo",       "answer": "REYNALDO",       "aliases": []},
    {"no": 3,  "pos": "ZAG",   "name": "David Duarte",   "answer": "DAVID DUARTE",   "aliases": []},
    {"no": 8,  "pos": "VOL",   "name": "Fellipe Bastos", "answer": "FELLIPE BASTOS", "aliases": []},
    {"no": 6,  "pos": "LE",    "name": "Artur",          "answer": "ARTUR",          "aliases": []},
    {"no": 18, "pos": "LD/MC", "name": "Dieguinho",      "answer": "DIEGUINHO",      "aliases": []},
    {"no": 10, "pos": "MEI",   "name": "Élvis",          "answer": "ELVIS",          "aliases": []},
    {"no": 11, "pos": "MC",    "name": "Júlio César",    "answer": "JULIO CESAR",    "aliases": []},
    {"no": 5,  "pos": "VOL",   "name": "Caio Vinícius",  "answer": "CAIO VINICIUS",  "aliases": []},
    {"no": 7,  "pos": "ATA",   "name": "Dadá Belmonte",  "answer": "DADA",           "aliases": ["Dadá"]},
    {"no": 9,  "pos": "ATA",   "name": "Nicolas",        "answer": "NICOLAS",        "aliases": []}
  ]'::jsonb then
    raise exception 'escalação do Guarani x Goiás 2021 diferente da esperada — aborta.';
  end if;

  -- 3) canônica matches: as 9 partidas a datar estão só com o ano
  if (select count(*) from public.matches where id in (
        '3223c44c-2ca5-5de9-8a95-e13324216dc1', '56d56e70-5c18-5797-adf8-16d107fa28bb',
        '2329418e-5027-591c-a117-af085e255027', '36f08f38-be62-552b-ae53-1f746ead75a0',
        '9403f088-d984-5cbe-8fb7-0c4e7500df4e', '84815132-0ade-5cb2-b017-e2f049c4e18f',
        '058d666e-aa84-58d9-b19b-a6ff3ccef4ec', 'e2aab068-3555-5bbf-b99b-2ce45dbb1972',
        'fea69f06-3354-5960-9ce4-3f9ef0a48393')
      and kickoff_precision = 'YEAR' and kickoff_date is null) <> 9 then
    raise exception 'matches: alguma das 9 partidas não está com precisão YEAR — aborta.';
  end if;

  -- 4) Manto: valores atuais exatos
  select string_agg(e.id, ', ') into v
  from (values
    ('junior_vicosa',  'ata', 2018),
    ('leandro_smith',  'le',  2003),
    ('valmir_lucas',   'zag', 2011),
    ('tiago_fraga',    'vol', 2003),
    ('amaral',         'vol', 2005),
    ('vinicius',       'ata', 2023),
    ('gil_baiano',     'ld',  2003),
    ('carlos_alberto', 'mei', 2010)
  ) as e(id, pos, deb)
  left join public.guess_players g using (id)
  where g.id is null or g.position is distinct from e.pos or g.club_debut_year is distinct from e.deb;
  if v is not null then
    raise exception 'guess_players fora do estado esperado: % — aborta.', v;
  end if;
  if (select position from public.guess_players where id = 'gustavo') is not null then
    raise exception 'guess_players.gustavo já tem posição — aborta.';
  end if;

  -- 5) Tadeu: estatística canônica atual
  if not exists (
    select 1 from public.player_club_stats
    where id = '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3'
      and appearances = 400 and goals is null and as_of_date = '2026-08-28'
  ) then
    raise exception 'estatística canônica do Tadeu não está em 400/null em 2026-08-28 — aborta.';
  end if;
end $$;

-- ------------------------------------------------- escalações: datas e estádio
update public.lineup_matches m
set match_date = e.d, venue = e.venue
from (values
  ('2003_juventude_brA_reacao',    date '2003-04-27', 'Serra Dourada'),
  ('2003_fluminense_brA_reacao',   date '2003-10-12', null),
  ('2005_pontepreta_brA_3lugar',   date '2005-10-01', 'Serra Dourada'),
  ('2005_athleticopr_brA_3lugar',  date '2005-11-13', 'Serra Dourada'),
  ('2005_corinthians_brA_3lugar',  date '2005-12-04', 'Serra Dourada'),
  ('2006_newells_lib_grupos',      date '2006-03-22', null),
  ('2012_guarani_brB_retafinal',   date '2012-10-16', 'Serra Dourada'),
  ('2013_vasco_cdb_quartas_ida',   date '2013-09-25', 'Serra Dourada'),
  ('2013_vasco_cdb_quartas_volta', date '2013-10-24', null)
) as e(id, d, venue)
where m.id = e.id;

-- só estádio (a data já estava certa)
update public.lineup_matches set venue = 'Serra Dourada'
where id in ('2006_cuenca_lib_1fase', '1990_flamengo_cdb_final_volta');

-- CORRIGIR PREMISSA: 7x0 foi na 6ª rodada (abril), não na "reação"
update public.lineup_matches set phase = 'Rodada 6'
where id = '2003_juventude_brA_reacao';

-- CORRIGIR PREMISSA: Júlio César (#94) era do Guarani; o 11º titular do
-- Goiás foi Rezende (#7). Camisas pela ficha do jogo (ogol, jogo 7972073).
update public.lineup_matches set lineup = '[
  {"no": 1,  "pos": "GOL",   "name": "Tadeu",          "answer": "TADEU",          "aliases": []},
  {"no": 4,  "pos": "ZAG",   "name": "Reynaldo",       "answer": "REYNALDO",       "aliases": []},
  {"no": 3,  "pos": "ZAG",   "name": "David Duarte",   "answer": "DAVID DUARTE",   "aliases": []},
  {"no": 8,  "pos": "VOL",   "name": "Fellipe Bastos", "answer": "FELLIPE BASTOS", "aliases": []},
  {"no": 6,  "pos": "LE",    "name": "Artur",          "answer": "ARTUR",          "aliases": []},
  {"no": 2,  "pos": "LD/MC", "name": "Dieguinho",      "answer": "DIEGUINHO",      "aliases": []},
  {"no": 10, "pos": "MEI",   "name": "Élvis",          "answer": "ELVIS",          "aliases": []},
  {"no": 7,  "pos": "MC",    "name": "Rezende",        "answer": "REZENDE",        "aliases": []},
  {"no": 5,  "pos": "VOL",   "name": "Caio Vinícius",  "answer": "CAIO VINICIUS",  "aliases": []},
  {"no": 11, "pos": "ATA",   "name": "Dadá Belmonte",  "answer": "DADA",           "aliases": ["Dadá"]},
  {"no": 9,  "pos": "ATA",   "name": "Nicolas",        "answer": "NICOLAS",        "aliases": []}
]'::jsonb
where id = '2021_guarani_brB_acesso';

-- ------------------------------------------- canônica matches: data confirmada
update public.matches m
set kickoff_month = extract(month from e.d)::int, kickoff_date = e.d,
    kickoff_precision = 'DATE', updated_at = now()
from (values
  ('3223c44c-2ca5-5de9-8a95-e13324216dc1'::uuid, date '2003-04-27'),  -- Goiás 7x0 Juventude
  ('56d56e70-5c18-5797-adf8-16d107fa28bb'::uuid, date '2003-10-12'),  -- Goiás 6x1 Fluminense
  ('2329418e-5027-591c-a117-af085e255027'::uuid, date '2005-10-01'),  -- Goiás 4x1 Ponte Preta
  ('36f08f38-be62-552b-ae53-1f746ead75a0'::uuid, date '2005-11-13'),  -- Goiás 4x2 Athletico-PR
  ('9403f088-d984-5cbe-8fb7-0c4e7500df4e'::uuid, date '2005-12-04'),  -- Goiás 3x2 Corinthians
  ('84815132-0ade-5cb2-b017-e2f049c4e18f'::uuid, date '2006-03-22'),  -- Newell's 0x0 Goiás
  ('058d666e-aa84-58d9-b19b-a6ff3ccef4ec'::uuid, date '2012-10-16'),  -- Goiás 5x0 Guarani
  ('e2aab068-3555-5bbf-b99b-2ce45dbb1972'::uuid, date '2013-09-25'),  -- Goiás 2x1 Vasco
  ('fea69f06-3354-5960-9ce4-3f9ef0a48393'::uuid, date '2013-10-24')   -- Vasco 3x2 Goiás
) as e(id, d)
where m.id = e.id;

-- ------------------------------------------------------- Manto: estreia/posição
update public.guess_players g
set club_debut_year = e.deb
from (values
  ('junior_vicosa', 2012), ('leandro_smith', 2001), ('valmir_lucas', 2009),
  ('tiago_fraga', 1999), ('amaral', 2006), ('vinicius', 2022)
) as e(id, deb)
where g.id = e.id;

update public.guess_players g
set position = e.pos
from (values
  ('tiago_fraga', 'mei'), ('gil_baiano', 'pd'), ('carlos_alberto', 'vol'), ('gustavo', 'ld')
) as e(id, pos)
where g.id = e.id;

-- --------------------------------------------- canônica: gols do Tadeu (13)
-- Conflito 13 × 14 continua aberto: status passa a PARTIAL.
update public.player_club_stats
set goals = 13, verification_status = 'PARTIAL', updated_at = now()
where id = '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3';

insert into public.player_club_stat_sources
  (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
values (
  '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3', 'career_players', 'career_players:tadeu',
  '{"appearances": 400, "goals": 13}'::jsonb, 'CORROBORATING', date '2026-08-28',
  '13 gols (todos de pênalti) em fontes contemporâneas ao 400º jogo; a soma sazonal do ogol dá 14 — conflito em aberto, por isso PARTIAL.'
);

-- ----------------------------------------------------------- pós-condições
do $$
declare v text;
begin
  -- toda escalação continua com 11 titulares
  select string_agg(id, ', ') into v from public.lineup_matches
  where jsonb_array_length(lineup) <> 11;
  if v is not null then raise exception 'Pós: escalação sem 11 titulares: %', v; end if;

  -- só o Santos 2003 continua com 01/01 entre os itens desta fase
  select string_agg(id, ', ') into v from public.lineup_matches
  where to_char(match_date, 'MM-DD') = '01-01';
  if v is distinct from '2003_santos_brA_reacao' then
    raise exception 'Pós: datas 01/01 inesperadas: %', v;
  end if;

  -- Júlio César saiu, Rezende entrou, sem camisa repetida
  if exists (select 1 from public.lineup_matches, jsonb_array_elements(lineup) p
             where id = '2021_guarani_brB_acesso' and p->>'name' = 'Júlio César')
     or not exists (select 1 from public.lineup_matches, jsonb_array_elements(lineup) p
             where id = '2021_guarani_brB_acesso' and p->>'name' = 'Rezende')
     or (select count(distinct p->>'no') from public.lineup_matches, jsonb_array_elements(lineup) p
         where id = '2021_guarani_brB_acesso') <> 11 then
    raise exception 'Pós: escalação do Guarani 2021 não ficou como esperado.';
  end if;

  -- Athletico 2005 mantém Luciano Almeida
  if not exists (select 1 from public.lineup_matches, jsonb_array_elements(lineup) p
                 where id = '2005_athleticopr_brA_3lugar' and p->>'name' = 'Luciano Almeida') then
    raise exception 'Pós: Luciano Almeida sumiu do Athletico 2005.';
  end if;

  if (select count(*) from public.matches where kickoff_precision = 'DATE' and id in (
        '3223c44c-2ca5-5de9-8a95-e13324216dc1', '56d56e70-5c18-5797-adf8-16d107fa28bb',
        '2329418e-5027-591c-a117-af085e255027', '36f08f38-be62-552b-ae53-1f746ead75a0',
        '9403f088-d984-5cbe-8fb7-0c4e7500df4e', '84815132-0ade-5cb2-b017-e2f049c4e18f',
        '058d666e-aa84-58d9-b19b-a6ff3ccef4ec', 'e2aab068-3555-5bbf-b99b-2ce45dbb1972',
        'fea69f06-3354-5960-9ce4-3f9ef0a48393')) <> 9 then
    raise exception 'Pós: matches não ficou com as 9 datas.';
  end if;
  if (select kickoff_precision from public.matches where id = '85863207-3408-5312-bcae-4ae904150572') <> 'YEAR' then
    raise exception 'Pós: Santos 2003 não deveria ter data.';
  end if;

  -- nenhum verified novo no Manto (continua 79)
  if (select count(*) from public.guess_players where data_status = 'verified') <> 79 then
    raise exception 'Pós: total de verified no Manto mudou.';
  end if;

  -- pendentes intocados
  if (select club_debut_year from public.guess_players where id = 'gustavo') <> 2003
     or (select club_debut_year from public.guess_players where id = 'renato_silva') <> 2003
     or (select position from public.guess_players where id = 'dalton') <> 'le'
     or (select data_status from public.guess_players where id = 'evandro') <> 'incomplete' then
    raise exception 'Pós: um item pendente foi alterado.';
  end if;

  if not exists (select 1 from public.player_club_stats
                 where id = '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3'
                   and appearances = 400 and goals = 13 and verification_status = 'PARTIAL'
                   and as_of_date = '2026-08-28') then
    raise exception 'Pós: estatística do Tadeu não ficou 400/13 PARTIAL.';
  end if;
end $$;
