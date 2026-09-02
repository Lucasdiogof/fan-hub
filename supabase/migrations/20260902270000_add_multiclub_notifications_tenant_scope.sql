-- M2.2A — Additive Tenant Schema — Notificações (Grupo D)
-- user_notification_preferences, match_monitor_sessions, notification_events — user_notification_tokens (GLOBAL) e notification_deliveries (herda via event_id) ficam de fora, sem club_id direto.
--
-- Aditivo, backward-compatible: club_id uuid NOT NULL DEFAULT Goiás
-- REFERENCES public.clubs(id), em cada uma das tabelas abaixo
-- (user_notification_preferences, match_monitor_sessions, notification_events). O app publicado atual, que nunca manda club_id,
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

  -- user_notification_preferences (0 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'user_notification_preferences' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'user_notification_preferences';
  end if;

  alter table public.user_notification_preferences
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists user_notification_preferences_club_id_idx on public.user_notification_preferences (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.user_notification_preferences where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'user_notification_preferences', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.user_notification_preferences t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'user_notification_preferences', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.user_notification_preferences where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'user_notification_preferences', v_non_goias_count;
  end if;

  -- match_monitor_sessions (1 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'match_monitor_sessions' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'match_monitor_sessions';
  end if;

  alter table public.match_monitor_sessions
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists match_monitor_sessions_club_id_idx on public.match_monitor_sessions (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.match_monitor_sessions where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'match_monitor_sessions', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.match_monitor_sessions t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'match_monitor_sessions', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.match_monitor_sessions where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'match_monitor_sessions', v_non_goias_count;
  end if;

  -- notification_events (0 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'notification_events' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'notification_events';
  end if;

  alter table public.notification_events
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists notification_events_club_id_idx on public.notification_events (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.notification_events where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'notification_events', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.notification_events t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'notification_events', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.notification_events where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'notification_events', v_non_goias_count;
  end if;

end $$;
