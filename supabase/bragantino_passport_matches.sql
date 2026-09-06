-- Passaporte do Bragantino — histórico de partidas do Red Bull Bragantino /
-- Clube Atlético Bragantino (uma única história de clube, nunca duas).
-- Rode no SQL Editor do projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj)
-- — NÃO no do Goiás.
--
-- DECISÃO ARQUITETURAL (revista 2026-09-06, corrige a 1ª versão desta
-- migration): Goiás e Bragantino são projetos Supabase FISICAMENTE
-- SEPARADOS — o isolamento entre clubes já existe no nível do projeto, não
-- precisa de `club_id`/tabela com nome de clube pra ficar seguro. Por isso
-- esta tabela se chama `public.passport_matches`, o MESMO nome usado no
-- projeto do Goiás — cada banco só enxerga o próprio clube, e o Flutter
-- pode ter um único repository/DTO (`PassportMatch`, `PassportMatchDto`)
-- pros dois. A 1ª versão desta migration tinha criado
-- `bragantino_passport_matches` (nome com o clube embutido) achando que
-- precisava "tenantizar" pra reaproveitar o schema — desnecessário, dado
-- que cada clube já tem seu próprio banco.
--
-- COMPATIBILIDADE COM O SCHEMA DO GOIÁS — campos que existem nos dois,
-- MESMO nome/tipo (deliberado, pro contrato Flutter ser único):
--   id, season, match_date, match_time, status, competition,
--   competition_code, round, opponent, neutral_site, home_team, away_team,
--   home_score, away_score, opponent_score, score_display, outcome,
--   source_provider, source_match_id, source_url, source_confidence,
--   data_notes, created_at, updated_at.
-- ÚNICA divergência de nome do contrato principal: Goiás usa
-- `goias_is_home`/`goias_score` (nomes com o clube embutido, herdados de
-- antes da arquitetura multiclube — NÃO alterados aqui, fora de escopo
-- tocar no banco do Goiás). Bragantino usa os nomes GENÉRICOS
-- `club_is_home`/`club_score` desde o início, já que é uma tabela nova.
-- ACHADO ENQUANTO AUDITAVA ISSO (fora de escopo consertar agora, só
-- registrando): o Flutter (`PassportMatch.fromMap`,
-- lib/features/passport/domain/entities/passport_match.dart) já lê
-- `club_is_home`/`club_score` — só que a RPC do Goiás
-- (`passport_matches_for_year`) devolve `goias_is_home`/`goias_score`
-- (RETURNS TABLE com esses nomes), então esses 2 campos ficam SEMPRE null
-- pro Goiás em produção hoje. Bug real, pré-existente, não introduzido
-- por esta migration — precisa de uma decisão própria (renomear a RETURNS
-- TABLE da RPC do Goiás é o fix óbvio, mas é mudança em função live).
--
-- Campos SÓ do Goiás, não usados aqui (schema mais antigo, sem
-- equivalente no dataset do Bragantino ainda): kickoff_at,
-- display_timezone, date_precision, competition_source_name, venue_id
-- (FK pra uma tabela `venues` normalizada, hoje vazia mesmo no Goiás).
-- Campos SÓ do Bragantino (enriquecimento novo desta rodada, não
-- exigido pelo `PassportMatch` do Flutter hoje, guardados pra uso
-- futuro/auditoria): competition_edition, phase_status, weekday, day_type,
-- day_period, stadium_status, venue_city, venue_state, venue_country.
-- `stadium` aqui faz o papel de `venue_name` (nome equivalente ao que a
-- RPC do Goiás expõe) — texto direto na própria linha, sem catálogo
-- `venues` separado (o do Goiás está vazio, não valia a complexidade).
--
-- `status` usa EXATAMENTE os 4 valores do Goiás (nunca 'UNKNOWN' — o
-- dataset real não precisou desse estado, e usar só os necessários era
-- pedido explícito).
--
-- Sem policy de presença/ranking ainda (Passaporte do Bragantino não tem
-- tela própria no app — `hasPassport=false` no `ClubCapabilities` do
-- Bragantino hoje — fora do escopo desta rodada, só o dataset de
-- partidas). Quando a feature for ligada, as RPCs equivalentes a
-- `passport_matches_for_year`/`passport_save_attendances` precisam copiar
-- o MESMO guard duplo do Goiás: `status = 'FINISHED'` E
-- `match_date <= current_date` antes de aceitar presença — nunca só no
-- Flutter.

create table if not exists public.passport_matches (
  id text primary key,
  season int not null,
  match_date date not null,
  match_time time,
  status text not null
    check (status in ('FINISHED', 'SCHEDULED', 'POSTPONED', 'CANCELLED')),
  competition text not null,
  competition_code text,
  competition_edition text,
  round text,
  phase_status text not null default 'ROUND_NOT_EXPOSED_BY_SOURCE'
    check (phase_status in ('CONFIRMED', 'ROUND_NOT_EXPOSED_BY_SOURCE')),
  opponent text not null,
  club_is_home boolean not null,
  neutral_site boolean not null default false,
  home_team text not null,
  away_team text not null,
  home_score int,
  away_score int,
  club_score int,
  opponent_score int,
  score_display text,
  outcome text check (outcome in ('WIN', 'DRAW', 'LOSS')),
  stadium text,
  stadium_status text not null default 'NEEDS_SOURCE'
    check (stadium_status in ('MATCH_SPECIFIC', 'NEEDS_SOURCE')),
  venue_city text,
  venue_state text,
  venue_country text,
  weekday text,
  day_type text check (day_type in ('WEEKDAY', 'WEEKEND')),
  day_period text not null default 'UNKNOWN'
    check (day_period in ('MORNING', 'AFTERNOON', 'NIGHT', 'UNKNOWN')),
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
create index if not exists passport_matches_finished_by_season_idx
  on public.passport_matches (season, match_date)
  where status = 'FINISHED';

alter table public.passport_matches enable row level security;

drop policy if exists "passport_matches_read_all" on public.passport_matches;
create policy "passport_matches_read_all"
  on public.passport_matches
  for select
  using (true);
