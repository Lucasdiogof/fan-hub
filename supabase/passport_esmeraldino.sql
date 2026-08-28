-- ============================================================================
-- Passaporte Esmeraldino — histórico de partidas do Goiás (2000–2026) e as
-- presenças autodeclaradas de cada torcedor. Rode no SQL Editor do Supabase
-- ANTES de passport_esmeraldino_import.sql.
--
-- Ranking totalmente separado do `arena_ranking.sql` (Quiz/Escalação/
-- Adivinhe o Jogador/Manto) — nenhuma tabela em comum, nenhuma pontuação
-- soma na outra. Presença aqui vale 1 ponto fixo por partida marcada; a
-- regra fica isolada dentro de `passport_ranking`/`passport_my_rank` pra
-- poder evoluir sem tocar em mais nada.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Estádios — catálogo normalizado, preparado pro futuro "Passaporte de
-- Estádios" (ver item 11 do pedido). Vazio por enquanto: os dados
-- históricos de partida não têm estádio confirmado pela fonte (nunca
-- inventado — `venue_id` fica null em toda partida importada agora).
-- ---------------------------------------------------------------------------
create table if not exists public.venues (
  id text primary key,
  canonical_name text not null,
  display_name text not null,
  city text,
  state text,
  country text,
  latitude numeric,
  longitude numeric,
  aliases text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.venues enable row level security;

drop policy if exists "venues_read_all" on public.venues;
create policy "venues_read_all"
  on public.venues
  for select
  using (true);

-- ---------------------------------------------------------------------------
-- Catálogo de partidas — espelha 1:1 o schema do JSON histórico fornecido
-- (schema_version 1.0.0). Chave primária é o `id` estável da fonte
-- (`pe_xxxxxxxxxxxxxxxx`), nunca gerado aqui — assim reimportar o mesmo
-- arquivo nunca duplica linha, só atualiza.
-- ---------------------------------------------------------------------------
create table if not exists public.passport_matches (
  id text primary key,
  season int not null,
  match_date date not null,
  match_time time,
  kickoff_at timestamptz,
  display_timezone text,
  date_precision text not null
    check (date_precision in ('date_only', 'datetime')),
  status text not null
    check (status in ('FINISHED', 'SCHEDULED', 'POSTPONED', 'CANCELLED')),
  competition text not null,
  competition_code text not null,
  competition_source_name text,
  round text,
  opponent text not null,
  goias_is_home boolean,
  neutral_site boolean,
  home_team text,
  away_team text,
  home_score int,
  away_score int,
  goias_score int,
  opponent_score int,
  score_display text,
  outcome text check (outcome in ('WIN', 'DRAW', 'LOSS')),
  venue_id text references public.venues (id),
  source_provider text not null,
  source_match_id text,
  source_url text,
  source_confidence text,
  data_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists passport_matches_season_date_idx
  on public.passport_matches (season, match_date);
create index if not exists passport_matches_status_idx
  on public.passport_matches (status);
create index if not exists passport_matches_competition_idx
  on public.passport_matches (competition_code);
create index if not exists passport_matches_source_idx
  on public.passport_matches (source_provider, source_match_id);
create index if not exists passport_matches_venue_idx
  on public.passport_matches (venue_id);
-- Consulta mais comum da tela principal: partidas encerradas de uma
-- temporada, em ordem cronológica.
create index if not exists passport_matches_finished_by_season_idx
  on public.passport_matches (season, match_date)
  where status = 'FINISHED';

alter table public.passport_matches enable row level security;

drop policy if exists "passport_matches_read_all" on public.passport_matches;
create policy "passport_matches_read_all"
  on public.passport_matches
  for select
  using (true);

-- ---------------------------------------------------------------------------
-- Presenças autodeclaradas. Sem policy de insert/update/delete pro cliente
-- — só a RPC `passport_save_attendances` (security definer) escreve aqui,
-- porque as regras ("só FINISHED", "nunca partida futura", "só o próprio
-- usuário") precisam valer no servidor, não só no Flutter. Mesmo padrão de
-- `user_game_item_progress` em arena_ranking.sql.
-- ---------------------------------------------------------------------------
create table if not exists public.passport_attendances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  match_id text not null references public.passport_matches (id) on delete cascade,
  attended boolean not null default true,
  marked_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  source text not null default 'self_declared',
  unique (user_id, match_id)
);

create index if not exists passport_attendances_match_idx
  on public.passport_attendances (match_id);
create index if not exists passport_attendances_user_attended_idx
  on public.passport_attendances (user_id) where attended = true;

alter table public.passport_attendances enable row level security;

drop policy if exists "passport_attendances_read_own" on public.passport_attendances;
create policy "passport_attendances_read_own"
  on public.passport_attendances
  for select
  using (auth.uid() = user_id);
-- Sem policy de insert/update: só `passport_save_attendances` grava.

-- ---------------------------------------------------------------------------
-- Log de execuções de sincronização (importação histórica e, futuramente,
-- o sincronizador de partidas recentes — ver `passport_esmeraldino_sync.sql`
-- e o README em tooling/passaporte_esmeraldino). Dado operacional, não de
-- usuário: RLS ligado sem nenhuma policy — só a service role (que ignora
-- RLS) lê/escreve, nunca o app.
-- ---------------------------------------------------------------------------
create table if not exists public.passport_sync_runs (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'running'
    check (status in ('running', 'success', 'partial', 'failed')),
  inserted_count int not null default 0,
  updated_count int not null default 0,
  unchanged_count int not null default 0,
  failed_count int not null default 0,
  error_summary text,
  metadata jsonb not null default '{}'::jsonb
);

alter table public.passport_sync_runs enable row level security;
