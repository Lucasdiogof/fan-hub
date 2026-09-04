-- M2.2A — Additive Tenant Schema — Progresso Carreira/Escalação + votos (Grupo B2)
-- career_path_progress, lineup_match_progress, match_lineup_votes — progresso específico do Adivinhe o Jogador/Adivinhe a Escalação e os votos da Escalação da Torcida.
--
-- Aditivo, backward-compatible: club_id uuid NOT NULL DEFAULT Goiás
-- REFERENCES public.clubs(id), em cada uma das tabelas abaixo
-- (career_path_progress, lineup_match_progress, match_lineup_votes). O app publicado atual, que nunca manda club_id,
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

  -- career_path_progress (40 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'career_path_progress' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'career_path_progress';
  end if;

  alter table public.career_path_progress
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists career_path_progress_club_id_idx on public.career_path_progress (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.career_path_progress where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'career_path_progress', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.career_path_progress t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'career_path_progress', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.career_path_progress where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'career_path_progress', v_non_goias_count;
  end if;

  -- lineup_match_progress (34 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'lineup_match_progress' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'lineup_match_progress';
  end if;

  alter table public.lineup_match_progress
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists lineup_match_progress_club_id_idx on public.lineup_match_progress (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.lineup_match_progress where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'lineup_match_progress', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.lineup_match_progress t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'lineup_match_progress', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.lineup_match_progress where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'lineup_match_progress', v_non_goias_count;
  end if;

  -- match_lineup_votes (3 linha(s) no snapshot de auditoria 2026-09-02 —
  -- SÓ evidência/contexto no comentário, nunca uma condição executável:
  -- esta tabela é viva, a contagem real no momento do push pode ser
  -- diferente sem que isso signifique problema algum.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'match_lineup_votes' and column_name = 'club_id'
  ) then
    raise exception 'club_id já existe em public.% — abortando (estado inesperado: migration parcialmente replicada ou mudança manual — nunca ADD COLUMN IF NOT EXISTS silencioso)', 'match_lineup_votes';
  end if;

  alter table public.match_lineup_votes
    add column club_id uuid not null default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs (id);

  create index if not exists match_lineup_votes_club_id_idx on public.match_lineup_votes (club_id);

  -- Pós-condições semânticas, contra o estado REAL da tabela nesta
  -- transação — nunca contra o snapshot congelado.
  select count(*) into v_null_count from public.match_lineup_votes where club_id is null;
  if v_null_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id NULL (esperava 0)', 'match_lineup_votes', v_null_count;
  end if;

  select count(*) into v_orphan_count
    from public.match_lineup_votes t left join public.clubs c on c.id = t.club_id
   where c.id is null;
  if v_orphan_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id órfão (esperava 0)', 'match_lineup_votes', v_orphan_count;
  end if;

  select count(*) into v_non_goias_count from public.match_lineup_votes where club_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;
  if v_non_goias_count <> 0 then
    raise exception 'PÓS-condição falhou em %: % linha(s) com club_id != Goiás logo após o ADD COLUMN (esperava 0 — só o DEFAULT deveria ter escrito, nenhuma outra origem de valor)', 'match_lineup_votes', v_non_goias_count;
  end if;

end $$;
