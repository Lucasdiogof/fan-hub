-- ============================================================================
-- Auditoria da Arena do Goiás — fase 1, correções aprovadas pelo usuário em
-- 2026-10-01 (aba B do relatório + alturas do elenco pela fonte oficial).
--
-- Fontes:
--   * goiasec.com.br/elenco/atleta/<slug> (site oficial, consultado 2026-10-01)
--   * ogol.com.br/jogador/wellington-rato/264017 e /marcos-vinicius/553472
--     (2ª fonte das duas datas de nascimento — concordam com o oficial)
--   * ogol.com.br/jogador/walter/74088 (Goiás só em 2012, 2013, 2016 e 2017)
--   * ogol.com.br/jogador/silvio-criciuma/173926 (Goiás desde 1996; nossas
--     escalações de nov/dez 1996 já o tinham como titular)
--   * Ernando: total 371/12 já conferido ano a ano no ogol e aplicado em
--     career_players (20260930010000); a camada canônica ficou com o 405 antigo.
--
-- Alturas: regra do usuário "na dúvida, a fonte do Goiás". NÃO mexe no
-- Murillo Victorio (o site oficial não publica altura; os 183 vêm de ogol +
-- BeSoccer, ver 20260930030000).
--
-- Tudo roda numa transação implícita (run-sql-file.mjs): se qualquer
-- pré-condição falhar, nada é aplicado.
-- ============================================================================

-- ---------------------------------------------------------------- pré-condições
do $$
declare
  v_mismatch text;
begin
  select string_agg(id, ', ') into v_mismatch
  from (values
    ('wellington_rato',  date '1992-06-28', 172, 'Wellington Soares da Silva'),
    ('marcos_vinicius',  date '1997-03-25', 178, 'Marcos Vinicius da Silva Santos'),
    ('thiago_rodrigues', date '1988-10-20', 189, 'Thiago Rodrigues de Oliveira Nogueira'),
    ('luiz_felipe',      date '1993-09-09', 189, 'Luiz Felipe do Nascimento dos Santos'),
    ('ramon_menezes',    date '1995-05-03', 186, 'Ramon Menezes Roma'),
    ('murilo_camara',    date '2006-11-04', 193, 'Murilo Camara Saquetti Chimelo Pereira'),
    ('nicolas',          date '1997-02-24', 181, 'Nicolas Vichiatto da Silva'),
    ('lourenco',         date '1997-09-07', 169, 'João Paulo Ferreira Lourenço'),
    ('filipe_machado',   date '1996-01-20', 175, 'Luiz Filipe da Rosa Machado'),
    ('anselmo_ramon',    date '1988-06-23', 182, 'Anselmo Ramon Alves Herculano'),
    ('esli_garcia',      date '2000-07-14', 165, 'Esli Samuel García Cordero'),
    ('kadu_sousa',       date '2002-03-03', 178, 'Carlos Eduardo de Sousa Leopoldino'),
    ('halerrandrio',     date '2006-07-08', 175, 'Halerrandrio dos Santos Feitosa'),
    ('luisao',           date '2003-09-09', 192, 'Luis Fellipe Campos Doria')
  ) as e(id, birth, height, full_name)
  left join public.squad_members s using (id)
  where s.id is null
     or s.birth_date is distinct from e.birth
     or s.height_cm is distinct from e.height
     or s.full_name is distinct from e.full_name;
  if v_mismatch is not null then
    raise exception 'squad_members fora do estado documentado: % — aborta.', v_mismatch;
  end if;

  if (select club_debut_year from public.guess_players where id = 'silvio_criciuma') is distinct from 1998 then
    raise exception 'guess_players.silvio_criciuma.club_debut_year não está em 1998 — aborta.';
  end if;

  if not exists (
    select 1 from public.player_club_spells
    where id = '40354072-1a71-50a3-867c-7a96c7af4f18'
      and person_id = '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'
      and start_year = 2019 and end_year = 2019
  ) then
    raise exception 'passagem 2019 do Walter não encontrada como documentada — aborta.';
  end if;
  if exists (
    select 1 from public.player_club_stats
    where spell_id = '40354072-1a71-50a3-867c-7a96c7af4f18'
      and id <> '4a3291af-cde5-49e4-ac80-5f8f954442ef'
  ) or exists (
    select 1 from public.player_positions where spell_id = '40354072-1a71-50a3-867c-7a96c7af4f18'
  ) or exists (
    select 1 from public.player_match_appearances where spell_id = '40354072-1a71-50a3-867c-7a96c7af4f18'
  ) then
    raise exception 'há mais registros ligados à passagem 2019 do Walter do que o documentado — aborta.';
  end if;

  if not exists (
    select 1 from public.player_club_stats
    where id = '4e91e9c8-53e9-456b-a7e9-d4722b0f34f5'
      and stats_scope = 'CLUB_TOTAL' and appearances = 405 and goals is null
  ) then
    raise exception 'estatística canônica do Ernando não está em 405/null — aborta.';
  end if;
end $$;

-- ------------------------------------------------- elenco: nascimento, altura, nome
update public.squad_members s
set birth_date = e.birth, height_cm = e.height, full_name = e.full_name, updated_at = now()
from (values
  ('wellington_rato',  date '1992-06-18', 172, 'Wellington Soares da Silva'),
  ('marcos_vinicius',  date '1997-03-26', 178, 'Marcos Vinicius da Silva Santos'),
  ('thiago_rodrigues', date '1988-10-20', 188, 'Thiago Rodrigues de Oliveira Nogueira'),
  ('luiz_felipe',      date '1993-09-09', 188, 'Luiz Felipe do Nascimento dos Santos'),
  ('ramon_menezes',    date '1995-05-03', 187, 'Ramon Menezes Roma'),
  ('murilo_camara',    date '2006-11-04', 191, 'Murilo Câmara Saquetti Chimelo Pereira'),
  ('nicolas',          date '1997-02-24', 183, 'Nicolas Vichiatto da Silva'),
  ('lourenco',         date '1997-09-07', 170, 'João Paulo Ferreira Lourenço'),
  ('filipe_machado',   date '1996-01-20', 176, 'Luiz Filipe da Rosa Machado'),
  ('anselmo_ramon',    date '1988-06-23', 183, 'Anselmo Ramon Alves Herculano'),
  ('esli_garcia',      date '2000-07-14', 163, 'Esli Samuel Garcia Cordero'),
  ('kadu_sousa',       date '2002-03-03', 177, 'Carlos Eduardo de Sousa Leopoldino'),
  ('halerrandrio',     date '2006-07-08', 176, 'Halerrandrio dos Santos Feitosa'),
  ('luisao',           date '2003-09-09', 192, 'Luís Fellipe Campos Dória')
) as e(id, birth, height, full_name)
where s.id = e.id;

-- --------------------------------------------------- Manto: estreia do Sílvio
update public.guess_players set club_debut_year = 1996 where id = 'silvio_criciuma';

-- ------------------------------------- canônico: Walter não teve passagem em 2019
delete from public.player_club_stats where id = '4a3291af-cde5-49e4-ac80-5f8f954442ef';
delete from public.player_club_spells where id = '40354072-1a71-50a3-867c-7a96c7af4f18';

-- ------------------------------------------------- canônico: Ernando 371 jogos
update public.player_club_stats
set appearances = 371, goals = 12, updated_at = now()
where id = '4e91e9c8-53e9-456b-a7e9-d4722b0f34f5';

insert into public.player_club_stat_sources
  (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
values (
  '4e91e9c8-53e9-456b-a7e9-d4722b0f34f5', 'career_players', 'career_players:ernando',
  '{"appearances": 371, "goals": 12, "period": "2006-2013"}'::jsonb, 'PRIMARY', date '2026-09-30',
  'Soma ano a ano no ogol.com.br (2006=2, 2007=28, 2008=38, 2009=63, 2010=65, 2011=60, 2012=52, 2013=63). O 405 anterior estava errado.'
);

-- ---------------------------------------------------------------- pós-condições
do $$
begin
  if (select count(*) from public.squad_members where
        (id = 'wellington_rato' and birth_date = '1992-06-18')
     or (id = 'marcos_vinicius' and birth_date = '1997-03-26')
     or (id = 'thiago_rodrigues' and height_cm = 188)
     or (id = 'luiz_felipe' and height_cm = 188)
     or (id = 'ramon_menezes' and height_cm = 187)
     or (id = 'murilo_camara' and height_cm = 191 and full_name = 'Murilo Câmara Saquetti Chimelo Pereira')
     or (id = 'nicolas' and height_cm = 183)
     or (id = 'lourenco' and height_cm = 170)
     or (id = 'filipe_machado' and height_cm = 176)
     or (id = 'anselmo_ramon' and height_cm = 183)
     or (id = 'esli_garcia' and height_cm = 163 and full_name = 'Esli Samuel Garcia Cordero')
     or (id = 'kadu_sousa' and height_cm = 177)
     or (id = 'halerrandrio' and height_cm = 176)
     or (id = 'luisao' and full_name = 'Luís Fellipe Campos Dória')) <> 14 then
    raise exception 'Pós-condição falhou: elenco não ficou como esperado.';
  end if;
  if (select height_cm from public.squad_members where id = 'murillo_victorio') is distinct from 183 then
    raise exception 'Pós-condição falhou: murillo_victorio não deveria ter mudado.';
  end if;
  if (select club_debut_year from public.guess_players where id = 'silvio_criciuma') <> 1996 then
    raise exception 'Pós-condição falhou: estreia do Sílvio Criciúma.';
  end if;
  if (select array_agg(start_year order by start_year) from public.player_club_spells
      where person_id = '828c3bc8-7e25-55c3-8468-d3cec50cd2e5') <> array[2012, 2016] then
    raise exception 'Pós-condição falhou: passagens do Walter.';
  end if;
  if not exists (select 1 from public.player_club_stats
                 where id = '4e91e9c8-53e9-456b-a7e9-d4722b0f34f5' and appearances = 371 and goals = 12) then
    raise exception 'Pós-condição falhou: estatística do Ernando.';
  end if;
end $$;
