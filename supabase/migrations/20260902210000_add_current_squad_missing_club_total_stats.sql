-- Etapa F4.5 — adiciona 2 linhas de player_club_stats (CLUB_TOTAL,
-- Goiás) para squad_members RESOLVED que ainda não tinham nenhum
-- CLUB_TOTAL: Ezequiel e Murillo Victorio, ambos ainda sem estreia pelo
-- time profissional do Goiás. appearances=0, goals=0 refletem uma
-- ausência de jogos CONFIRMADA (não "dado desconhecido") via ogol.com.br
-- (fonte externa estruturada), corroborada por uma 2ª fonte independente
-- por jogador. verification_status='PARTIAL' porque são fontes externas
-- secundárias, não confirmação oficial explícita do clube com o número —
-- nunca promovido a VERIFIED.
--
-- Semântica exata de "0": 0 aparições PROFISSIONAIS pelo Goiás (STARTED
-- ou SUBSTITUTE_USED, mesma semântica de player_match_appearances da
-- Etapa E). Nunca "0 vezes relacionado em súmula" nem "0 jogos de base" —
-- ambos os jogadores têm minutos reais registrados na base/sub-20/sub-23,
-- só nunca estrearam no time principal. Estar relacionado numa súmula
-- (UNUSED_SUBSTITUTE) NUNCA conta como appearance nesta ou em nenhuma
-- etapa futura.
--
-- as_of_date=2026-09-02 é obrigatório e literal: isto é um SNAPSHOT, não
-- um fato atemporal — se um dos dois estrear depois desta data, o "0"
-- continua historicamente correto e pode receber delta/live futuramente
-- (arquitetura baseline+delta da Etapa D/E, não implementada aqui).
--
-- Não recalcula/toca nenhuma das outras 29 linhas CLUB_TOTAL já
-- existentes.
--
-- Evidência completa: tooling/multiclub/current_squad_gap_evidence.json
-- Plano auditável: data_export/goias/player_reconciliation/current_squad_canonical_gap_fix_plan.json

do $$
declare
  v_stat_id uuid;
  v_before_count int;
  v_after_count int;
  v_after_sources_count int;
  v_after_primary_count int;
  v_duplicate_club_total int;
begin
  if not exists (select 1 from public.clubs where id = '4c16340d-300c-5ab2-903f-17519db9b146') then
    raise exception 'PRÉ-condição falhou: club_id % (Goiás) não existe em clubs', '4c16340d-300c-5ab2-903f-17519db9b146';
  end if;

  -- PRÉ: nenhuma das 2 pessoas alvo pode já ter uma linha CLUB_TOTAL no Goiás.
  select count(*) into v_before_count
    from public.player_club_stats
   where club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
     and stats_scope = 'CLUB_TOTAL'
     and person_id in ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'e590ad99-16d4-52a1-88fd-2fbb064444b6');
  if v_before_count <> 0 then
    raise exception 'PRÉ-condição falhou: esperava 0 linhas CLUB_TOTAL pré-existentes pras % pessoas alvo, achou %', 2, v_before_count;
  end if;

  -- Ezequiel Alves de Oliveira Vieira (squad_members:ezequiel, person_id=66cd616b-9b5d-56f9-879e-1b171a8a33d0)
  if not exists (select 1 from public.people where id = '66cd616b-9b5d-56f9-879e-1b171a8a33d0') then
    raise exception 'PRÉ-condição falhou: person_id % (%) não existe em people', '66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'Ezequiel Alves de Oliveira Vieira';
  end if;

  insert into public.player_club_stats (person_id, club_id, spell_id, stats_scope, appearances, goals, verification_status, data_mode, as_of_date, as_of_match_id)
  values ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', '4c16340d-300c-5ab2-903f-17519db9b146', null, 'CLUB_TOTAL', 0, 0, 'PARTIAL', 'SNAPSHOT', '2026-09-02', null)
  returning id into v_stat_id;

    insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
    values (v_stat_id, 'external_verified', 'ogol.com.br/jogador/ezequiel/722092', '{"sourceType":"external_verified","sourceRef":"ogol.com.br/jogador/ezequiel/722092","url":"https://www.ogol.com.br/jogador/ezequiel/722092","detail":"''Sem jogos disputados'' (2026) pro time profissional do Goiás; times 2023-2026 todos com traço/sem registro no profissional; só há números reais em Goiás U23 (2024, 7 jogos) e Goiás U20 (2023, 26 jogos), que não contam pro CLUB_TOTAL do time principal."}'::jsonb, 'PRIMARY', '2026-09-02', '''Sem jogos disputados'' (2026) pro time profissional do Goiás; times 2023-2026 todos com traço/sem registro no profissional; só há números reais em Goiás U23 (2024, 7 jogos) e Goiás U20 (2023, 26 jogos), que não contam pro CLUB_TOTAL do time principal.');
    insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
    values (v_stat_id, 'external_corroborating', 'goiasec.com.br/elenco/atleta/ezequiel', '{"sourceType":"external_corroborating","sourceRef":"goiasec.com.br/elenco/atleta/ezequiel","url":"https://www.goiasec.com.br/elenco/atleta/ezequiel","detail":"site oficial do clube — perfil sem número de jogos/gols listado, sem contradizer o achado do ogol"}'::jsonb, 'CORROBORATING', '2026-09-02', 'site oficial do clube — perfil sem número de jogos/gols listado, sem contradizer o achado do ogol');

  -- Murillo Carvalho Victorio (squad_members:murillo_victorio, person_id=e590ad99-16d4-52a1-88fd-2fbb064444b6)
  if not exists (select 1 from public.people where id = 'e590ad99-16d4-52a1-88fd-2fbb064444b6') then
    raise exception 'PRÉ-condição falhou: person_id % (%) não existe em people', 'e590ad99-16d4-52a1-88fd-2fbb064444b6', 'Murillo Carvalho Victorio';
  end if;

  insert into public.player_club_stats (person_id, club_id, spell_id, stats_scope, appearances, goals, verification_status, data_mode, as_of_date, as_of_match_id)
  values ('e590ad99-16d4-52a1-88fd-2fbb064444b6', '4c16340d-300c-5ab2-903f-17519db9b146', null, 'CLUB_TOTAL', 0, 0, 'PARTIAL', 'SNAPSHOT', '2026-09-02', null)
  returning id into v_stat_id;

    insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
    values (v_stat_id, 'external_verified', 'ogol.com.br/jogador/murillo-victorio/972457', '{"sourceType":"external_verified","sourceRef":"ogol.com.br/jogador/murillo-victorio/972457","url":"https://www.ogol.com.br/jogador/murillo-victorio/972457","detail":"''-'' pro time profissional 2026; 12 jogos/1 gol marcado/12 gols sofridos no Goiás Sub-20 2026 (Brasileiro Sub-20 Série B 3 jogos, Copinha 4 jogos, Copa Goiás 1 jogo, Goiano Sub-20 4 jogos) — não contam pro CLUB_TOTAL do time principal"}'::jsonb, 'PRIMARY', '2026-09-02', '''-'' pro time profissional 2026; 12 jogos/1 gol marcado/12 gols sofridos no Goiás Sub-20 2026 (Brasileiro Sub-20 Série B 3 jogos, Copinha 4 jogos, Copa Goiás 1 jogo, Goiano Sub-20 4 jogos) — não contam pro CLUB_TOTAL do time principal');
    insert into public.player_club_stat_sources (player_club_stat_id, source_type, source_ref, raw_value, source_role, as_of_date, notes)
    values (v_stat_id, 'external_corroborating', 'web_search_summary', '{"sourceType":"external_corroborating","sourceRef":"web_search_summary","url":null,"detail":"resumo de busca web (múltiplas fontes) confirma ''Murillo has not yet played for Goiás in the professional squad''"}'::jsonb, 'CORROBORATING', '2026-09-02', 'resumo de busca web (múltiplas fontes) confirma ''Murillo has not yet played for Goiás in the professional squad''');

  -- PÓS: exatamente 2 linhas CLUB_TOTAL agora existem pras pessoas alvo.
  select count(*) into v_after_count
    from public.player_club_stats
   where club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
     and stats_scope = 'CLUB_TOTAL'
     and person_id in ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'e590ad99-16d4-52a1-88fd-2fbb064444b6');
  if v_after_count <> 2 then
    raise exception 'PÓS-condição falhou: esperava % linhas CLUB_TOTAL pras pessoas alvo, achou %', 2, v_after_count;
  end if;

  -- PÓS: 0 CLUB_TOTAL duplicado por pessoa (cada uma das 2 exatamente 1).
  select count(*) into v_duplicate_club_total
    from (
      select person_id, count(*) as n
        from public.player_club_stats
       where club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
         and stats_scope = 'CLUB_TOTAL'
         and person_id in ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'e590ad99-16d4-52a1-88fd-2fbb064444b6')
       group by person_id
    ) x
   where x.n <> 1;
  if v_duplicate_club_total <> 0 then
    raise exception 'PÓS-condição falhou: % pessoa(s) alvo com CLUB_TOTAL duplicado (esperava exatamente 1 cada)', v_duplicate_club_total;
  end if;

  select count(*) into v_after_sources_count
    from public.player_club_stat_sources s
    join public.player_club_stats st on st.id = s.player_club_stat_id
   where st.club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
     and st.stats_scope = 'CLUB_TOTAL'
     and st.person_id in ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'e590ad99-16d4-52a1-88fd-2fbb064444b6');
  if v_after_sources_count <> 4 then
    raise exception 'PÓS-condição falhou: esperava % linhas de provenance pras % stats novas, achou %', 4, 2, v_after_sources_count;
  end if;

  select count(*) into v_after_primary_count
    from public.player_club_stat_sources s
    join public.player_club_stats st on st.id = s.player_club_stat_id
   where st.club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
     and st.stats_scope = 'CLUB_TOTAL'
     and st.person_id in ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'e590ad99-16d4-52a1-88fd-2fbb064444b6')
     and s.source_role = 'PRIMARY';
  if v_after_primary_count <> 2 then
    raise exception 'PÓS-condição falhou: esperava exatamente 1 fonte PRIMARY por stat novo (% no total), achou %', 2, v_after_primary_count;
  end if;
end $$;
