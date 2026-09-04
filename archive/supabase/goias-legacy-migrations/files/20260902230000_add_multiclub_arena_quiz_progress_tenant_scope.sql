-- M2.2A — Additive Tenant Schema — Progresso Arena/Quiz/Identidade (Grupo B1)
-- user_game_item_progress, score_events, quiz_question_progress, quiz_active_session, arena_selected_content, arena_achievements, player_identity_results, tactical_identity_results — progresso genérico de jogo + resultados dos 2 "testes de identidade" (Que Torcedor/Que Craque).
--
-- Aditivo, backward-compatible: club_id uuid NOT NULL DEFAULT Goiás
-- REFERENCES public.clubs(id), em cada uma das tabelas abaixo
-- (user_game_item_progress, score_events, quiz_question_progress, quiz_active_session, arena_selected_content, arena_achievements, player_identity_results, tactical_identity_results). O app publicado atual, que nunca manda club_id,
-- continua funcionando sem nenhuma mudança — toda linha nova cai
-- automaticamente em Goiás via DEFAULT.
--
-- TRANSITIONAL_COMPATIBILITY_DEFAULT: o DEFAULT Goiás é deliberadamente
-- temporário — existe só enquanto há 1 clube real. Precisa ser reavaliado/
-- removido na M2.2B (Tenant Enforcement), depois da M3 (Tenant-Aware
-- Runtime) fazer o app sempre mandar club_id explícito.
--
-- NÃO faz nesta migration (fora de escopo da M2.2A, ver relatório):
--   * nenhuma PK/UNIQUE alterada ou removida (KEY_SCOPE é M2.2B);
--   * nenhum dado de negócio tocado — só a coluna club_id é escrita;
--   * nenhuma RLS/policy alterada;
--   * nenhuma tabela de Passaporte (NEEDS_PRODUCT_DECISION, fora desta rodada).
--
-- PG11+: ADD COLUMN ... DEFAULT <literal> NOT NULL evita o heap rewrite
-- tradicional (o default fica resolvido no catálogo pras linhas já
-- existentes) — mas continua sendo um DDL de lock breve orientado a
-- metadado nesta escala atual, nunca "zero lock" ou "instantâneo
-- garantido". A FK contra clubs(id) precisa validar cada valor já
-- existente na tabela referenciante — hoje isso é rápido só porque a
-- maior tabela candidata tem 262 linhas, não porque clubs ter 1 linha
-- torna a validação grátis por si só.
--
-- Nenhuma precondition/postcondition aqui compara count(*) contra um
-- número congelado — estas tabelas são vivas. Ver comentário do módulo.
--
-- Plano auditável: data_export/goias/player_reconciliation/multiclub_m2_2a_plan.json
-- Snapshot de auditoria (contexto, não guard): data_export/goias/player_reconciliation/multiclub_m2_2a_row_counts.json

do $$
declare
  v_null_count int;
  v_orphan_count int;
  v_non_goias_count int;
  v_clubs_count int;
begin
  -- PRÉ-condição global: exatamente 1 clube, e ele precisa ser exatamente
  -- Goiás (id E slug, não só o UUID isolado) — nunca gerar backfill sobre
  -- um estado de clubs diferente do esperado.
  select count(*) into v_clubs_count from public.clubs;
  if v_clubs_count <> 1 then
    raise exception 'PRÉ-condição falhou: esperava exatamente 1 linha em public.clubs, achou %', v_clubs_count;
  end if;
  if not exists (
    select 1 from public.clubs where id = '4c16340d-300c-5ab2-903f-17519db9b146'::uuid and slug = 'goias'
  ) then
    raise exception 'PRÉ-condição falhou: club Goiás (id=%, slug=goias) não encontrado exatamente assim em public.clubs', '4c16340d-300c-5ab2-903f-17519db9b146';
  end if;

  -- user_game_item_progress (211 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'user_game_item_progress' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'user_game_item_progress';
  end if;

  alter table public.user_game_item_progress
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists user_game_item_progress_club_id_idx on public.user_game_item_progress (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.user_game_item_progress where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'user_game_item_progress', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.user_game_item_progress t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'user_game_item_progress', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.user_game_item_progress where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'user_game_item_progress', v_non_goias_count;
  end if;

  -- score_events (262 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'score_events' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'score_events';
  end if;

  alter table public.score_events
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists score_events_club_id_idx on public.score_events (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.score_events where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'score_events', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.score_events t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'score_events', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.score_events where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'score_events', v_non_goias_count;
  end if;

  -- quiz_question_progress (160 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'quiz_question_progress' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'quiz_question_progress';
  end if;

  alter table public.quiz_question_progress
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists quiz_question_progress_club_id_idx on public.quiz_question_progress (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.quiz_question_progress where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'quiz_question_progress', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.quiz_question_progress t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'quiz_question_progress', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.quiz_question_progress where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'quiz_question_progress', v_non_goias_count;
  end if;

  -- quiz_active_session (9 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'quiz_active_session' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'quiz_active_session';
  end if;

  alter table public.quiz_active_session
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists quiz_active_session_club_id_idx on public.quiz_active_session (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.quiz_active_session where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'quiz_active_session', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.quiz_active_session t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'quiz_active_session', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.quiz_active_session where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'quiz_active_session', v_non_goias_count;
  end if;

  -- arena_selected_content (9 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'arena_selected_content' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'arena_selected_content';
  end if;

  alter table public.arena_selected_content
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists arena_selected_content_club_id_idx on public.arena_selected_content (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.arena_selected_content where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'arena_selected_content', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.arena_selected_content t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'arena_selected_content', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.arena_selected_content where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'arena_selected_content', v_non_goias_count;
  end if;

  -- arena_achievements (0 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'arena_achievements' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'arena_achievements';
  end if;

  alter table public.arena_achievements
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists arena_achievements_club_id_idx on public.arena_achievements (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.arena_achievements where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'arena_achievements', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.arena_achievements t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'arena_achievements', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.arena_achievements where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'arena_achievements', v_non_goias_count;
  end if;

  -- player_identity_results (1 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'player_identity_results' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'player_identity_results';
  end if;

  alter table public.player_identity_results
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists player_identity_results_club_id_idx on public.player_identity_results (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.player_identity_results where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'player_identity_results', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.player_identity_results t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'player_identity_results', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.player_identity_results where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'player_identity_results', v_non_goias_count;
  end if;

  -- tactical_identity_results (1 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'tactical_identity_results' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'tactical_identity_results';
  end if;

  alter table public.tactical_identity_results
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists tactical_identity_results_club_id_idx on public.tactical_identity_results (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.tactical_identity_results where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'tactical_identity_results', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.tactical_identity_results t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'tactical_identity_results', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.tactical_identity_results where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'tactical_identity_results', v_non_goias_count;
  end if;

end $$;
