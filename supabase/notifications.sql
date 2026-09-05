-- ============================================================================
-- Push Notifications V1 — 3 tipos: match_access_open (check-in às 48h antes
-- do kickoff pra sócio ativo, ingressos disponíveis pra quem não é), goal
-- (gol do Goiás) e full_time (resultado final). Nada além disso nesta
-- versão.
--
-- STALE (auditoria 2026-09-05) — histórico, NÃO roda mais como está. Já
-- aplicado em produção antes da convergência multiclube; o schema real
-- hoje diverge deste arquivo em pelo menos 1 ponto: `user_notification_
-- preferences` tinha PK só `user_id` aqui, mas em produção é
-- `PRIMARY KEY (user_id, club_id)` (confirmado ao vivo). O schema
-- canônico atual é `supabase/migrations/20260904000000_canonical_
-- baseline.sql` — consulte ele, nunca este arquivo, pra saber a
-- estrutura real das tabelas de notificação.
-- ============================================================================

-- Tokens FCM — multi-device por usuário. `fcm_token` é único: o mesmo
-- aparelho só pertence a uma conta por vez (upsert por token troca o dono
-- automaticamente se outra conta logar no mesmo device).
create table if not exists public.user_notification_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  fcm_token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists user_notification_tokens_user_idx
  on public.user_notification_tokens (user_id)
  where is_active;

alter table public.user_notification_tokens enable row level security;

drop policy if exists "read own tokens" on public.user_notification_tokens;
drop policy if exists "insert own tokens" on public.user_notification_tokens;
drop policy if exists "update own tokens" on public.user_notification_tokens;
drop policy if exists "delete own tokens" on public.user_notification_tokens;

create policy "read own tokens" on public.user_notification_tokens
  for select using (auth.uid() = user_id);
create policy "insert own tokens" on public.user_notification_tokens
  for insert with check (auth.uid() = user_id);
create policy "update own tokens" on public.user_notification_tokens
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own tokens" on public.user_notification_tokens
  for delete using (auth.uid() = user_id);

-- Preferências — só as 2 chaves que a V1 usa. Sem linha = tratado como
-- true/true (opt-out explícito, nunca opt-in silencioso) tanto na leitura
-- do app quanto na hora de montar a lista de destinatários no backend.
create table if not exists public.user_notification_preferences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  matches_enabled boolean not null default true,
  tickets_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.user_notification_preferences enable row level security;

drop policy if exists "read own preferences" on public.user_notification_preferences;
drop policy if exists "insert own preferences" on public.user_notification_preferences;
drop policy if exists "update own preferences" on public.user_notification_preferences;

create policy "read own preferences" on public.user_notification_preferences
  for select using (auth.uid() = user_id);
create policy "insert own preferences" on public.user_notification_preferences
  for insert with check (auth.uid() = user_id);
create policy "update own preferences" on public.user_notification_preferences
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Estado do monitor de partida — 1 linha por jogo acompanhado. `ends_at` é
-- o timeout de segurança (kickoff + 3h): se o provedor nunca devolver
-- FULL_TIME, o monitor para sozinho em vez de pollar pra sempre.
create table if not exists public.match_monitor_sessions (
  match_id text primary key,
  kickoff timestamptz not null,
  home_team_name text not null,
  away_team_name text not null,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'active', 'finished', 'timed_out')),
  last_known_score jsonb,
  started_at timestamptz,
  last_polled_at timestamptz,
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Sem RLS de usuário — só as Edge Functions (service_role) leem/escrevem
-- aqui, não é dado de usuário final.
alter table public.match_monitor_sessions enable row level security;
drop policy if exists "service role only" on public.match_monitor_sessions;
create policy "service role only" on public.match_monitor_sessions
  for all using (false) with check (false);

-- Evento detectado — "aconteceu isso, foi visto uma vez". A unique
-- (event_type, dedupe_key) é a garantia de não duplicar detecção, mesmo com
-- o Cron rodando em paralelo ou reprocessando o mesmo payload (ex.: scorer
-- de um gol sendo preenchido depois não muda o dedupe_key, então o insert
-- vira on conflict do nothing, nunca uma segunda linha).
create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  match_id text not null,
  event_type text not null check (event_type in ('match_access_open', 'goal', 'full_time')),
  dedupe_key text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'failed')),
  detected_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (event_type, dedupe_key)
);

create index if not exists notification_events_status_idx
  on public.notification_events (status);

alter table public.notification_events enable row level security;
drop policy if exists "service role only" on public.notification_events;
create policy "service role only" on public.notification_events
  for all using (false) with check (false);

-- Entrega por destinatário — reservada de uma vez (1 linha pending por par
-- evento×token, insert on conflict do nothing) assim que o evento é
-- reivindicado pra disparo. Retry só busca linhas ainda 'pending': nunca há
-- ambiguidade sobre quem já recebeu, mesmo se a função morrer no meio do
-- envio.
create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.notification_events (id) on delete cascade,
  token_id uuid not null references public.user_notification_tokens (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'sent', 'failed', 'invalid_token')),
  fcm_message_id text,
  error text,
  attempted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (event_id, token_id)
);

create index if not exists notification_deliveries_pending_idx
  on public.notification_deliveries (event_id)
  where status = 'pending';

alter table public.notification_deliveries enable row level security;
drop policy if exists "service role only" on public.notification_deliveries;
create policy "service role only" on public.notification_deliveries
  for all using (false) with check (false);
