-- Goiás-app competition viewer: normalized PostgreSQL/Supabase schema.
-- The competition format lives at edition/stage level. Do not hardcode by competition.

create table if not exists competitions (
  id text primary key,
  name text not null,
  category text,
  source_competition_id bigint,
  source_url text,
  created_at timestamptz default now()
);

create table if not exists competition_editions (
  id text primary key,
  competition_id text not null references competitions(id),
  source_edition_id bigint unique,
  season integer,
  name text,
  status text default 'unknown',
  is_complete boolean,
  champion_team_id text,
  runner_up_team_id text,
  source_url text not null,
  last_verified_at timestamptz,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists competition_stages (
  id text primary key,
  edition_id text not null references competition_editions(id),
  name text not null,
  raw_name text,
  stage_type text not null default 'unknown',
  sort_order integer,
  has_groups boolean,
  has_standings boolean,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists competition_groups (
  id text primary key,
  stage_id text not null references competition_stages(id),
  name text not null,
  sort_order integer,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists competition_rounds (
  id text primary key,
  stage_id text not null references competition_stages(id),
  group_id text references competition_groups(id),
  number integer,
  name text,
  sort_order integer,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists teams (
  id text primary key,
  source_team_id bigint unique,
  name text not null,
  short_name text,
  country_code text,
  state_code text,
  crest_url text,
  source_url text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists team_aliases (
  id bigserial primary key,
  team_id text not null references teams(id),
  alias text not null,
  normalized_alias text not null,
  unique(team_id, normalized_alias)
);

create table if not exists stadiums (
  id text primary key,
  source_stadium_id bigint unique,
  name text not null,
  city text,
  state_code text,
  country_code text,
  source_url text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists matches (
  id text primary key,
  source_match_id bigint unique,
  edition_id text not null references competition_editions(id),
  stage_id text references competition_stages(id),
  group_id text references competition_groups(id),
  round_id text references competition_rounds(id),
  datetime_local timestamp,
  home_team_id text references teams(id),
  away_team_id text references teams(id),
  home_score integer,
  away_score integer,
  home_penalties integer,
  away_penalties integer,
  raw_score text,
  status text not null default 'unknown',
  stadium_id text references stadiums(id),
  attendance integer,
  gate_revenue numeric,
  source_url text not null,
  source_notes text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists standings (
  id text primary key,
  edition_id text not null references competition_editions(id),
  stage_id text references competition_stages(id),
  group_id text references competition_groups(id),
  team_id text references teams(id),
  position integer,
  points integer,
  played integer,
  wins integer,
  draws integer,
  losses integer,
  goals_for integer,
  goals_against integer,
  goal_difference integer,
  percentage numeric,
  qualification_status text,
  source_url text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists edition_scorers (
  id text primary key,
  edition_id text not null references competition_editions(id),
  rank integer,
  source_player_id bigint,
  player_name text not null,
  team_id text references teams(id),
  goals integer not null,
  source_url text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists edition_statistics (
  id text primary key,
  edition_id text not null unique references competition_editions(id),
  matches integer,
  goals integer,
  goals_per_match numeric,
  best_attack jsonb not null default '[]'::jsonb,
  best_defense jsonb not null default '[]'::jsonb,
  biggest_wins jsonb not null default '[]'::jsonb,
  streaks jsonb not null default '[]'::jsonb,
  source_url text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists edition_regulations (
  id text primary key,
  edition_id text not null unique references competition_editions(id),
  source_url text,
  source_text text,
  parsed_rules jsonb not null default '{}'::jsonb
);

create table if not exists final_classification (
  id text primary key,
  edition_id text not null references competition_editions(id),
  position integer not null,
  team_id text references teams(id),
  is_champion boolean default false,
  source_url text,
  extra jsonb not null default '{}'::jsonb
);

create table if not exists match_lineups (
  id text primary key,
  match_id text not null references matches(id),
  team_id text references teams(id),
  formation text,
  coach_name text,
  starters jsonb not null default '[]'::jsonb,
  substitutes jsonb not null default '[]'::jsonb,
  source_url text
);

create table if not exists match_events (
  id text primary key,
  match_id text not null references matches(id),
  event_type text,
  team_id text references teams(id),
  source_player_id bigint,
  player_name text,
  related_player_name text,
  minute integer,
  period integer,
  raw_text text,
  source_url text
);

create table if not exists match_officials (
  id text primary key,
  match_id text not null references matches(id),
  role text,
  source_official_id bigint,
  official_name text,
  source_url text
);

create table if not exists data_sources (
  id text primary key,
  entity_type text not null,
  entity_id text not null,
  provider text not null,
  url text not null,
  fetched_at timestamptz,
  checksum text,
  error text,
  extra jsonb not null default '{}'::jsonb
);

create index if not exists idx_editions_competition_season on competition_editions(competition_id, season desc);
create index if not exists idx_matches_edition_datetime on matches(edition_id, datetime_local);
create index if not exists idx_matches_stage on matches(stage_id);
create index if not exists idx_standings_edition_stage on standings(edition_id, stage_id, group_id, position);
create index if not exists idx_scorers_edition_rank on edition_scorers(edition_id, rank);
