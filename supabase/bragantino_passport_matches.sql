-- Passaporte do Bragantino — histórico de partidas do Red Bull Bragantino /
-- Clube Atlético Bragantino (uma única história de clube, nunca duas).
-- Rode no SQL Editor do projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj)
-- — NÃO no do Goiás.
--
-- DECISÃO ARQUITETURAL EM ABERTO (flagrada, não decidida por conta própria):
-- este é um lote inicial (Lote 1/2026) construído como TABELA PRÓPRIA
-- (`bragantino_passport_matches`), separada de `public.passport_matches`
-- (que é 100% Goiás-only hoje — colunas `goias_is_home`/`goias_score`,
-- SEM `club_id`, nunca tenantizada). Alternativa possível pra uma etapa
-- futura de unificação: migrar `passport_matches` pra um schema genérico
-- com `club_id` (backfill Goiás + rename de colunas) e usar UMA tabela
-- pros dois clubes, igual já acontece com `quiz_questions`/
-- `club_board_sections`/`squad_members`. Optei pela tabela própria AGORA
-- porque (a) não requer NENHUMA alteração no schema/dado live do Goiás,
-- (b) o gap "Passaporte nunca foi tenantizado" já era um achado conhecido
-- e maior que o escopo desta rodada (só monta o dataset local do
-- Bragantino). Não aplicar esta decisão como definitiva sem validar com o
-- usuário antes de uma eventual unificação.
--
-- Sem policy de presença/ranking ainda (Passaporte do Bragantino não tem
-- tela própria no app — fora do escopo desta rodada, só o dataset de
-- partidas).

create table if not exists public.bragantino_passport_matches (
  id text primary key,
  calendar_year int not null,
  competition text not null,
  competition_code text,
  competition_edition text,
  round text,
  phase_status text not null default 'ROUND_NOT_EXPOSED_BY_SOURCE'
    check (phase_status in ('CONFIRMED', 'ROUND_NOT_EXPOSED_BY_SOURCE')),
  match_date date not null,
  match_time time,
  weekday text,
  day_type text check (day_type in ('WEEKDAY', 'WEEKEND')),
  day_period text not null default 'UNKNOWN'
    check (day_period in ('MORNING', 'AFTERNOON', 'NIGHT', 'UNKNOWN')),
  home_team text not null,
  away_team text not null,
  club_is_home boolean not null,
  home_score int,
  away_score int,
  club_score int,
  opponent_score int,
  score_display text,
  score_status text not null
    check (score_status in ('FINISHED', 'SCHEDULED', 'POSTPONED', 'CANCELLED', 'UNKNOWN')),
  outcome text check (outcome in ('WIN', 'DRAW', 'LOSS')),
  stadium text,
  stadium_status text not null default 'NEEDS_SOURCE'
    check (stadium_status in ('MATCH_SPECIFIC', 'NEEDS_SOURCE')),
  venue_city text,
  venue_state text,
  venue_country text,
  source_provider text not null,
  source_match_id text,
  source_url text,
  source_confidence text,
  data_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bragantino_passport_matches_year_date_idx
  on public.bragantino_passport_matches (calendar_year, match_date);
create index if not exists bragantino_passport_matches_status_idx
  on public.bragantino_passport_matches (score_status);
create index if not exists bragantino_passport_matches_competition_idx
  on public.bragantino_passport_matches (competition_code);
create index if not exists bragantino_passport_matches_source_idx
  on public.bragantino_passport_matches (source_provider, source_match_id);

alter table public.bragantino_passport_matches enable row level security;

drop policy if exists "bragantino_passport_matches_read_all" on public.bragantino_passport_matches;
create policy "bragantino_passport_matches_read_all"
  on public.bragantino_passport_matches
  for select
  using (true);
