-- M2.2A — Additive Tenant Schema — Ingressos/Loja (Grupo B3)
-- ticket_checkin_decisions, ticket_orders, tickets, store_orders — order_number de store_orders continua UNIQUE GLOBAL (M2.1 classificou KEEP_GLOBAL), sequence intocada.
--
-- Aditivo, backward-compatible: club_id uuid NOT NULL DEFAULT Goiás
-- REFERENCES public.clubs(id), em cada uma das tabelas abaixo
-- (ticket_checkin_decisions, ticket_orders, tickets, store_orders). O app publicado atual, que nunca manda club_id,
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

  -- ticket_checkin_decisions (1 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'ticket_checkin_decisions' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'ticket_checkin_decisions';
  end if;

  alter table public.ticket_checkin_decisions
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists ticket_checkin_decisions_club_id_idx on public.ticket_checkin_decisions (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.ticket_checkin_decisions where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'ticket_checkin_decisions', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.ticket_checkin_decisions t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'ticket_checkin_decisions', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.ticket_checkin_decisions where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'ticket_checkin_decisions', v_non_goias_count;
  end if;

  -- ticket_orders (0 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'ticket_orders' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'ticket_orders';
  end if;

  alter table public.ticket_orders
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists ticket_orders_club_id_idx on public.ticket_orders (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.ticket_orders where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'ticket_orders', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.ticket_orders t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'ticket_orders', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.ticket_orders where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'ticket_orders', v_non_goias_count;
  end if;

  -- tickets (0 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'tickets' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'tickets';
  end if;

  alter table public.tickets
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists tickets_club_id_idx on public.tickets (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.tickets where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'tickets', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.tickets t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'tickets', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.tickets where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'tickets', v_non_goias_count;
  end if;

  -- store_orders (0 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'store_orders' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'store_orders';
  end if;

  alter table public.store_orders
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists store_orders_club_id_idx on public.store_orders (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.store_orders where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'store_orders', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.store_orders t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'store_orders', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.store_orders where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'store_orders', v_non_goias_count;
  end if;

end $$;
