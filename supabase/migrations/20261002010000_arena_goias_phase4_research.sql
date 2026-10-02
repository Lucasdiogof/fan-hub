-- ============================================================================
-- Auditoria da Arena do Goiás — fase 4 (aprovada pelo usuário em 2026-10-02).
-- Pesquisa própria (ogol, Bola na Área, Acervo Santista, Futebol80, La Nueva,
-- ficha da final de 1999 publicada pela imprensa pernambucana) + resposta da
-- pesquisa externa (Folha, UOL, GE, FootballDatabase, Feras do Esporte).
--
-- APLICAR:
--   * Goiás 3x0 Santos 2003 = 30/11/2003, Serra Dourada (ogol, Bola na Área,
--     Acervo Santista — que diz 29/11 mas "neste domingo" e cita o título do
--     Cruzeiro do mesmo dia —, Folha de 30/11);
--   * estádios: Flu 2003 Serra Dourada (Bola na Área + pesquisa fase 3),
--     Newell's 2006 Coloso del Parque (La Nueva 23/03/2006 + UOL),
--     Vasco 2013 Maracanã (ogol + Bola na Área + GE);
--   * estreia no Manto: Gustavo 2002 (ogol + FootballDatabase, 1º jogo
--     01/09/2002 x Guarani), Renato Silva 2002 (ogol + pesquisa), Evandro 1992
--     (ogol + pesquisa fase 3 — data exata do 1º jogo segue aberta);
--   * Dalton: posição VOL (pesquisa fase 3 + ficha Futebol80 27/11/1991 no
--     meio-campo + pesquisa fase 4; o ogol diz LD, voto vencido aprovado pelo
--     usuário);
--   * Lúcio do Manto = Lúcio Bala (mesma data de nascimento 14/01/1975 na
--     pesquisa e no ogol): só ganha o apelido como resposta aceita;
--   * Tadeu: 13 gols em 28/08/2026 (400º jogo) deixa de ser conflito — o 14º
--     gol veio em 14/09/2026. Status volta a VERIFIED.
-- CORRIGIR PREMISSA:
--   * "Túlio Maravilha" nas escalações de 1996 (Guarani, Grêmio) e da final de
--     1999 era o Túlio Lustosa Seixas Pinheiro ("Túlio Guerreiro", volante):
--     fichas do ogol dos 3 jogos + Futebol80 + ficha da final. Túlio
--     Maravilha só esteve no Goiás em 1988-1992;
--   * "Michael" da final de 1999 é Michel Dennis Lima da Silva (ficha do ogol +
--     ficha da final: "Michel (Tiago Fraga)").
-- Fica de fora (pendente): Josué 1987-91 e Marcões (uma fonte só), nascimento
-- do Gustavo, lista gol a gol do Tadeu, camisas, fotos, clube formador,
-- registros vazios do Manto.
-- ============================================================================

do $$
declare v text;
begin
  select string_agg(e.id, ', ') into v
  from (values
    ('2003_santos_brA_reacao',       date '2003-01-01'),
    ('2003_fluminense_brA_reacao',   date '2003-10-12'),
    ('2006_newells_lib_grupos',      date '2006-03-22'),
    ('2013_vasco_cdb_quartas_volta', date '2013-10-24')
  ) as e(id, d)
  left join public.lineup_matches m using (id)
  where m.id is null or m.match_date <> e.d or m.venue is not null;
  if v is not null then raise exception 'lineup_matches fora do esperado: % — aborta.', v; end if;

  if (select count(*) from public.lineup_matches m, jsonb_array_elements(m.lineup) p
      where m.id in ('1996_guarani_brA_quartas', '1996_gremio_brA_semi', '1999_santacruz_brB_titulo')
        and p->>'name' = 'Túlio Maravilha') <> 3 then
    raise exception 'Túlio Maravilha não está nas 3 escalações esperadas — aborta.';
  end if;
  if (select count(*) from public.lineup_matches m, jsonb_array_elements(m.lineup) p
      where m.id = '1999_santacruz_brB_titulo' and p->>'name' = 'Michael' and p->>'answer' = 'MICHAEL') <> 1 then
    raise exception 'Michael não está na final de 1999 como esperado — aborta.';
  end if;

  if not exists (select 1 from public.matches where id = '85863207-3408-5312-bcae-4ae904150572'
                 and kickoff_precision = 'YEAR' and kickoff_date is null) then
    raise exception 'matches: Santos 2003 não está só com o ano — aborta.';
  end if;

  select string_agg(e.id, ', ') into v
  from (values ('gustavo', 'ld', 2003), ('renato_silva', 'zag', 2003),
               ('evandro', 'ata', 1993), ('dalton', 'le', 1989), ('lucio', 'mei', 1994)) as e(id, pos, deb)
  left join public.guess_players g using (id)
  where g.id is null or g.position is distinct from e.pos or g.club_debut_year is distinct from e.deb;
  if v is not null then raise exception 'guess_players fora do esperado: % — aborta.', v; end if;
  if (select aliases from public.guess_players where id = 'lucio') <> '[]'::jsonb then
    raise exception 'lucio já tem apelidos — aborta.';
  end if;

  if not exists (select 1 from public.player_club_stats where id = '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3'
                 and appearances = 400 and goals = 13 and verification_status = 'PARTIAL'
                 and as_of_date = '2026-08-28') then
    raise exception 'Tadeu não está em 400/13 PARTIAL — aborta.';
  end if;
end $$;

-- ------------------------------------------------ data e estádios
update public.lineup_matches set match_date = date '2003-11-30', venue = 'Serra Dourada'
where id = '2003_santos_brA_reacao';
update public.lineup_matches m set venue = e.venue
from (values
  ('2003_fluminense_brA_reacao',   'Serra Dourada'),
  ('2006_newells_lib_grupos',      'Coloso del Parque'),
  ('2013_vasco_cdb_quartas_volta', 'Maracanã')
) as e(id, venue)
where m.id = e.id;

update public.matches
set kickoff_month = 11, kickoff_date = date '2003-11-30', kickoff_precision = 'DATE', updated_at = now()
where id = '85863207-3408-5312-bcae-4ae904150572';

-- ------------------------- CORRIGIR PREMISSA: Túlio Guerreiro e Michel Dennis
update public.lineup_matches m
set lineup = (
  select jsonb_agg(
    case
      when p->>'name' = 'Túlio Maravilha'
        then jsonb_build_object('no', p->'no', 'pos', p->'pos', 'name', 'Túlio',
                                'answer', 'TÚLIO', 'aliases', '["Túlio Guerreiro"]'::jsonb)
      when m.id = '1999_santacruz_brB_titulo' and p->>'name' = 'Michael'
        then jsonb_build_object('no', p->'no', 'pos', p->'pos', 'name', 'Michel',
                                'answer', 'MICHEL', 'aliases', '["Michel Dennis"]'::jsonb)
      else p
    end order by ord)
  from jsonb_array_elements(m.lineup) with ordinality as x(p, ord)
)
where m.id in ('1996_guarani_brA_quartas', '1996_gremio_brA_semi', '1999_santacruz_brB_titulo');

-- ------------------------------------------------------------ Manto
update public.guess_players g set club_debut_year = e.deb
from (values ('gustavo', 2002), ('renato_silva', 2002), ('evandro', 1992)) as e(id, deb)
where g.id = e.id;
update public.guess_players set position = 'vol' where id = 'dalton';
update public.guess_players set aliases = '["Lúcio Bala"]'::jsonb where id = 'lucio';

-- ------------------------------------------------------------ Tadeu
update public.player_club_stats set verification_status = 'VERIFIED', updated_at = now()
where id = '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3';

insert into public.player_club_stat_sources
  (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
values (
  '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3', 'press', 'ferasdoesporte:tadeu-400-jogos-2026-08-27',
  '{"appearances": 400, "goals": 13}'::jsonb, 'CORROBORATING', date '2026-08-28',
  '13 gols no 400º jogo (Feras do Esporte, 27/08/2026, e outro levantamento pós-jogo). O 14º gol foi em 14/09/2026 (Botafogo-SP 1x3 Goiás, pênalti — GE), depois desta data de referência: não há conflito.'
);

-- ------------------------------------------------------------ pós-condições
do $$
declare v text;
begin
  select string_agg(id, ', ') into v from public.lineup_matches where jsonb_array_length(lineup) <> 11;
  if v is not null then raise exception 'Pós: escalação sem 11 titulares: %', v; end if;

  if exists (select 1 from public.lineup_matches where to_char(match_date, 'MM-DD') = '01-01') then
    raise exception 'Pós: ainda há data 01/01.';
  end if;

  if exists (select 1 from public.lineup_matches m, jsonb_array_elements(m.lineup) p
             where p->>'name' = 'Túlio Maravilha' and m.season::int > 1992) then
    raise exception 'Pós: Túlio Maravilha ainda aparece depois de 1992.';
  end if;
  if exists (select 1 from public.lineup_matches m, jsonb_array_elements(m.lineup) p
             where m.id = '1999_santacruz_brB_titulo' and p->>'name' = 'Michael') then
    raise exception 'Pós: Michael ainda na final de 1999.';
  end if;

  if (select kickoff_precision from public.matches where id = '85863207-3408-5312-bcae-4ae904150572') <> 'DATE'
     or exists (select 1 from public.matches where kickoff_precision = 'YEAR') then
    raise exception 'Pós: matches ainda tem partida só com o ano.';
  end if;

  if (select count(*) from public.guess_players where data_status = 'verified') <> 79 then
    raise exception 'Pós: total de verified no Manto mudou.';
  end if;

  if (select count(*) from public.guess_players where
        (id = 'gustavo' and club_debut_year = 2002) or (id = 'renato_silva' and club_debut_year = 2002)
     or (id = 'evandro' and club_debut_year = 1992 and data_status = 'incomplete')
     or (id = 'dalton' and position = 'vol') or (id = 'lucio' and aliases = '["Lúcio Bala"]'::jsonb)) <> 5 then
    raise exception 'Pós: Manto não ficou como esperado.';
  end if;

  if not exists (select 1 from public.player_club_stats where id = '3f7956ae-0d5e-4a6d-93b0-2b0007e047d3'
                 and appearances = 400 and goals = 13 and verification_status = 'VERIFIED') then
    raise exception 'Pós: Tadeu não ficou 400/13 VERIFIED.';
  end if;
end $$;
