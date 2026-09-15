-- ============================================================================
-- Passaporte Esmeraldino — schema para o catálogo histórico 1943-2026.
--
-- Contexto: a base consolidada (tooling/esmeraldino_passport/source/
-- passaporte_esmeraldino_1943_2026_FINAL.csv, 3.840 partidas elegíveis,
-- 84 temporadas) precisa de duas mudanças de schema em public.passport_matches
-- e de uma tabela nova só de auditoria:
--
-- 1) `match_date` vira NULLABLE. Existe exatamente 1 partida em todo o
--    catálogo (hist-f80-0042, Goiás x ABG, 1946) cuja existência é
--    documentalmente confirmada mas cujo dia/mês nunca foram recuperados —
--    e o time já identificou, na migration que criou `public.matches`
--    (archive/supabase/goias-legacy-migrations/files/20260902100000_create_matches.sql),
--    que fabricar uma data sentinela (tipo `YYYY-01-01`) pra esse caso é
--    exatamente o erro a evitar. Em vez disso: NULL é NULL, e a ordenação
--    das RPCs existentes (`order by match_date asc/desc ... nulls last`)
--    já trata isso corretamente sem precisar mudar nenhuma RPC — conferido
--    em archive/supabase/goias-legacy-migrations/files/20260904190000_multiclub_canonical_convergence.sql.
--    `passport_save_attendances` também não quebra: `v_match.match_date >
--    current_date` com match_date NULL avalia NULL, e um `if null then` em
--    plpgsql não entra no ramo — não bloqueia marcar presença numa partida
--    de data desconhecida, nem trata como futura.
--
-- 2) `date_precision` ganha o valor `year_only` (além dos já existentes
--    `date_only`/`datetime`), pro caso acima.
--
-- 3) Cinco colunas novas em `passport_matches`, pra não descartar
--    informação de auditoria que o CSV carrega e que a tabela não tinha
--    campo pra guardar: `historical_source_no` (índice no catálogo
--    Futebol80, chave auxiliar de dedupe), `officiality`
--    (OFFICIAL_COMPETITIVE/COMPETITIVE_SECONDARY), `date_confidence`,
--    `score_confidence` (a tabela já tinha `source_confidence` e
--    `venue_confidence`, faltavam estas duas).
--
-- 4) Tabela nova `passport_matches_excluded` — os 32 registros
--    administrativos/amistosos/W.O./anulados do CSV de excluídos. Nunca
--    aparecem no Passaporte (sem FK de `passport_attendances`, sem RPC
--    pública, sem policy de leitura pra `anon`/`authenticated`), mas ficam
--    preservados pra auditoria histórica — mesmo padrão de
--    `passport_sync_runs` (só `service_role`).
--
-- Nada aqui apaga ou desconecta uma linha de `passport_matches` existente
-- — só ALTER COLUMN/ADD COLUMN/ADD CONSTRAINT e uma tabela nova. Presenças
-- de usuário em `passport_attendances` não são tocadas.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) match_date nullable
-- ---------------------------------------------------------------------------
alter table public.passport_matches
  alter column match_date drop not null;

-- ---------------------------------------------------------------------------
-- 2) date_precision aceita 'year_only'
-- ---------------------------------------------------------------------------
alter table public.passport_matches
  drop constraint if exists passport_matches_date_precision_check;

alter table public.passport_matches
  add constraint passport_matches_date_precision_check
  check (date_precision = any (array['date_only', 'datetime', 'year_only']));

-- ---------------------------------------------------------------------------
-- 3) Colunas novas de auditoria histórica
-- ---------------------------------------------------------------------------
alter table public.passport_matches
  add column if not exists historical_source_no text,
  add column if not exists officiality text,
  add column if not exists date_confidence text,
  add column if not exists score_confidence text,
  add column if not exists dataset_origin text;

comment on column public.passport_matches.historical_source_no is
  'Número do registro na fonte histórica original (ex.: índice no catálogo Futebol80). Usado como chave auxiliar de dedupe além do id — nunca a única chave.';
comment on column public.passport_matches.officiality is
  'OFFICIAL_COMPETITIVE | COMPETITIVE_SECONDARY — só partidas nessas duas categorias entram nesta tabela; amistosos/W.O./anulados ficam em passport_matches_excluded.';
comment on column public.passport_matches.date_confidence is
  'Confiança na data reportada (HIGH/MEDIUM/LOW), independente da confiança no placar ou na fonte em geral.';
comment on column public.passport_matches.score_confidence is
  'Confiança no placar reportado (HIGH/MEDIUM/LOW), independente da confiança na data.';
comment on column public.passport_matches.dataset_origin is
  'Lote/pipeline de origem do registro (ex.: historical_futebol80, modern_audited_2000_2026) — proveniência, não confiança.';

-- Dedupe adicional: nenhum número de fonte histórica pode aparecer em mais
-- de uma linha (a maioria das linhas — 2000-2026 via RSSSF/oGol — não tem
-- esse campo, por isso parcial).
create unique index if not exists passport_matches_historical_source_no_key
  on public.passport_matches (historical_source_no)
  where historical_source_no is not null;

-- ---------------------------------------------------------------------------
-- 4) Tabela de auditoria — partidas/eventos excluídos do Passaporte
-- ---------------------------------------------------------------------------
create table if not exists public.passport_matches_excluded (
  id text primary key,
  season integer not null,
  match_date date,
  date_precision text,
  status text not null,
  competition text,
  competition_code text,
  round text,
  opponent text,
  club_is_home boolean,
  neutral_site boolean,
  home_score integer,
  away_score integer,
  club_score integer,
  opponent_score integer,
  score_display text,
  outcome text,
  officiality text not null,
  historical_source_no text,
  source_provider text,
  source_match_id text,
  source_url text,
  dataset_origin text,
  data_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.passport_matches_excluded is
  'Amistosos, torneios não-oficiais, W.O. sem partida disputada, jogos anulados/desconsiderados e eventos administrativos — preservados só para auditoria histórica. Nunca lido pelo app: sem FK de passport_attendances, sem RPC pública, sem policy de leitura pra anon/authenticated. Fonte: tooling/esmeraldino_passport/source/passaporte_esmeraldino_EXCLUIDOS_ADMIN.csv.';

create index if not exists passport_matches_excluded_season_idx
  on public.passport_matches_excluded (season);

alter table public.passport_matches_excluded enable row level security;
-- Sem policy pública de propósito — mesmo padrão de passport_sync_runs:
-- os grants abaixo são o default do Supabase (schema privilege), quem
-- realmente bloqueia anon/authenticated é RLS habilitado sem nenhuma
-- policy; só service_role (que ignora RLS) lê/escreve de fato.
grant delete, insert, references, select, trigger, truncate, update
  on public.passport_matches_excluded to anon;
grant delete, insert, references, select, trigger, truncate, update
  on public.passport_matches_excluded to authenticated;
grant delete, insert, references, select, trigger, truncate, update
  on public.passport_matches_excluded to service_role;
