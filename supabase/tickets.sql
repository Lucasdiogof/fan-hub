-- ============================================================================
-- Ingressos + Check-in de Sócio — ainda 100% mock (sem API/pagamento real),
-- mas persistido no Supabase pra sobreviver a reinício/reinstalação, no
-- mesmo padrão das outras tabelas de progresso da Arena (RLS por
-- auth.uid()). Rode este arquivo no SQL Editor do Supabase.
-- ============================================================================

-- Decisão de check-in do sócio por partida — só existe linha quando o
-- usuário de fato agiu (confirmou ou recusou); "disponível"/"indisponível"/
-- "encerrado" são calculados no app a partir da janela de tempo do fixture,
-- nunca guardados aqui.
create table if not exists public.ticket_checkin_decisions (
  user_id uuid not null references auth.users (id) on delete cascade,
  match_id text not null,
  decision text not null check (decision in ('confirmed', 'declined')),
  sector_id text,
  updated_at timestamptz not null default now(),
  primary key (user_id, match_id)
);

alter table public.ticket_checkin_decisions enable row level security;

drop policy if exists "read own checkin decisions" on public.ticket_checkin_decisions;
drop policy if exists "insert own checkin decisions" on public.ticket_checkin_decisions;
drop policy if exists "update own checkin decisions" on public.ticket_checkin_decisions;
drop policy if exists "delete own checkin decisions" on public.ticket_checkin_decisions;

create policy "read own checkin decisions" on public.ticket_checkin_decisions
  for select using (auth.uid() = user_id);
create policy "insert own checkin decisions" on public.ticket_checkin_decisions
  for insert with check (auth.uid() = user_id);
create policy "update own checkin decisions" on public.ticket_checkin_decisions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own checkin decisions" on public.ticket_checkin_decisions
  for delete using (auth.uid() = user_id);

-- Pedidos de compra (não inclui check-in gratuito de sócio — isso é
-- decision+ticket direto, ver acima). `items` guarda a lista de
-- setor/categoria/quantidade/preço unitário do carrinho no formato que
-- `TicketOrderItem.toJson()` produz.
create table if not exists public.ticket_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  number text not null,
  match_id text not null,
  competition text not null,
  round text not null,
  home_team_id int not null,
  home_team_name text not null,
  away_team_id int not null,
  away_team_name text not null,
  kickoff timestamptz,
  stadium text not null,
  items jsonb not null,
  holder_name text not null,
  holder_document text not null,
  total numeric not null,
  status text not null default 'confirmed',
  created_at timestamptz not null default now()
);

alter table public.ticket_orders enable row level security;

drop policy if exists "read own orders" on public.ticket_orders;
drop policy if exists "insert own orders" on public.ticket_orders;
drop policy if exists "update own orders" on public.ticket_orders;

create policy "read own orders" on public.ticket_orders
  for select using (auth.uid() = user_id);
create policy "insert own orders" on public.ticket_orders
  for insert with check (auth.uid() = user_id);
create policy "update own orders" on public.ticket_orders
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Ingressos — criados por compra (`order_id` preenchido) ou por check-in de
-- sócio (`order_id` nulo, `origin = 'membership_check_in'`, sem preço).
create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  match_id text not null,
  competition text not null,
  round text not null,
  home_team_id int not null,
  home_team_name text not null,
  away_team_id int not null,
  away_team_name text not null,
  kickoff timestamptz,
  stadium text not null,
  sector_id text not null,
  sector_name text not null,
  venue_label text not null,
  gate text not null,
  category_label text,
  holder_name text not null,
  holder_document text not null,
  status text not null default 'active' check (status in ('active', 'cancelled', 'used', 'expired')),
  origin text not null check (origin in ('purchase', 'membership_check_in')),
  order_id uuid references public.ticket_orders (id) on delete set null,
  price numeric,
  created_at timestamptz not null default now()
);

create index if not exists tickets_user_match_idx on public.tickets (user_id, match_id);

-- Permite `upsert(onConflict: 'user_id,match_id')` no check-in de sócio —
-- só um ingresso de check-in ativo por usuário+partida (compra por
-- categoria pode ter vários ingressos pra mesma partida, por isso o índice
-- é parcial, só pra origin = 'membership_check_in').
create unique index if not exists tickets_user_match_checkin_uidx
  on public.tickets (user_id, match_id)
  where origin = 'membership_check_in';

alter table public.tickets enable row level security;

drop policy if exists "read own tickets" on public.tickets;
drop policy if exists "insert own tickets" on public.tickets;
drop policy if exists "update own tickets" on public.tickets;

create policy "read own tickets" on public.tickets
  for select using (auth.uid() = user_id);
create policy "insert own tickets" on public.tickets
  for insert with check (auth.uid() = user_id);
create policy "update own tickets" on public.tickets
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
