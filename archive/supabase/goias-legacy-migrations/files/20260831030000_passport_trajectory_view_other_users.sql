-- ============================================================================
-- Permite ver a trajetória de OUTRO torcedor a partir do ranking do
-- Passaporte (tocar num nome do ranking abre a mesma tela de "Minha
-- trajetória", só que com os dados dele). Nenhuma tabela nova — só um
-- parâmetro novo `p_user_id` nas RPCs de leitura que hoje só enxergam
-- `auth.uid()`, e uma RPC nova pro jogo memorável (que hoje só dá pra ler
-- via policy "auth.uid() = user_id", que bloqueia ver o de outro usuário).
--
-- Escrita continua 100% restrita ao próprio usuário (`passport_set_memorable_
-- match`/`passport_save_attendances` não mudam aqui) — só leitura fica
-- pública entre usuários autenticados, no mesmo espírito do ranking (que já
-- expõe nome/avatar/quantidade de jogos de todo mundo).
--
-- `drop function` antes de recriar: adicionar parâmetro muda a assinatura,
-- e Postgres trata isso como uma função DIFERENTE — sem o `drop`, a versão
-- antiga (sem parâmetro) continuaria existindo ao lado da nova.
-- ============================================================================

drop function if exists public.passport_summary();

create or replace function public.passport_summary(p_user_id uuid default null)
returns table (
  total_matches int,
  years_with_attendance int,
  first_marked_match_id text,
  first_marked_match_date date,
  last_marked_match_id text,
  last_marked_match_date date
)
language sql
security definer
set search_path = public
stable
as $$
  with mine as (
    select a.match_id, m.match_date, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.user_id = coalesce(p_user_id, auth.uid()) and a.attended = true
  )
  select
    (select count(*) from mine)::int,
    (select count(distinct season) from mine)::int,
    (select match_id from mine order by match_date asc limit 1),
    (select match_date from mine order by match_date asc limit 1),
    (select match_id from mine order by match_date desc limit 1),
    (select match_date from mine order by match_date desc limit 1);
$$;

grant execute on function public.passport_summary(uuid) to authenticated;

drop function if exists public.passport_attendance_breakdown();

create or replace function public.passport_attendance_breakdown(p_user_id uuid default null)
returns table (
  total_attended int,
  wins int,
  draws int,
  losses int,
  home_games int,
  away_games int,
  goals_for int,
  goals_against int
)
language sql
security definer
set search_path = public
stable
as $$
  select
    count(*)::int,
    count(*) filter (where m.outcome = 'WIN')::int,
    count(*) filter (where m.outcome = 'DRAW')::int,
    count(*) filter (where m.outcome = 'LOSS')::int,
    count(*) filter (where m.goias_is_home)::int,
    count(*) filter (where not m.goias_is_home)::int,
    coalesce(sum(m.goias_score), 0)::int,
    coalesce(sum(m.opponent_score), 0)::int
  from public.passport_attendances a
  join public.passport_matches m on m.id = a.match_id
  where a.user_id = coalesce(p_user_id, auth.uid())
    and a.attended = true
    and m.status = 'FINISHED';
$$;

grant execute on function public.passport_attendance_breakdown(uuid) to authenticated;

drop function if exists public.passport_stadium_summary();

create or replace function public.passport_stadium_summary(p_user_id uuid default null)
returns table (
  unique_stadiums int,
  most_visited_stadium_name text,
  most_visited_stadium_count int
)
language sql
security definer
set search_path = public
stable
as $$
  with mine as (
    select m.venue_id, m.match_date
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.user_id = coalesce(p_user_id, auth.uid()) and a.attended = true and m.status = 'FINISHED'
  ),
  by_venue as (
    select
      v.id as venue_id,
      v.display_name,
      count(*)::int as visit_count,
      max(mine.match_date) as last_visit
    from mine
    join public.venues v on v.id = mine.venue_id
    group by v.id, v.display_name
  )
  select
    (select count(distinct venue_id) from mine where venue_id is not null)::int,
    (select display_name from by_venue order by visit_count desc, last_visit desc limit 1),
    (select visit_count from by_venue order by visit_count desc, last_visit desc limit 1);
$$;

grant execute on function public.passport_stadium_summary(uuid) to authenticated;

drop function if exists public.passport_attended_matches();

create or replace function public.passport_attended_matches(p_user_id uuid default null)
returns table (
  id text,
  season int,
  match_date date,
  match_time time,
  kickoff_at timestamptz,
  display_timezone text,
  date_precision text,
  status text,
  competition text,
  competition_code text,
  round text,
  opponent text,
  goias_is_home boolean,
  neutral_site boolean,
  home_team text,
  away_team text,
  home_score int,
  away_score int,
  goias_score int,
  opponent_score int,
  score_display text,
  outcome text,
  venue_name text,
  venue_city text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    m.id, m.season, m.match_date, m.match_time, m.kickoff_at,
    m.display_timezone, m.date_precision, m.status, m.competition,
    m.competition_code, m.round, m.opponent, m.goias_is_home,
    m.neutral_site, m.home_team, m.away_team, m.home_score,
    m.away_score, m.goias_score, m.opponent_score, m.score_display,
    m.outcome, v.display_name, v.city
  from public.passport_matches m
  join public.passport_attendances a on a.match_id = m.id
  left join public.venues v on v.id = m.venue_id
  where a.user_id = coalesce(p_user_id, auth.uid()) and a.attended = true
  order by m.match_date desc, m.kickoff_at desc nulls last;
$$;

grant execute on function public.passport_attended_matches(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Jogo mais memorável de QUALQUER usuário — a policy de
-- `passport_memorable_matches` ("auth.uid() = user_id") só deixa ler a
-- própria linha, então uma RPC `security definer` é a única forma de expor
-- isso pro ranking sem abrir a tabela inteira via policy pública.
-- ---------------------------------------------------------------------------
create or replace function public.passport_memorable_match_id(p_user_id uuid default null)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select match_id
  from public.passport_memorable_matches
  where user_id = coalesce(p_user_id, auth.uid());
$$;

grant execute on function public.passport_memorable_match_id(uuid) to authenticated;
