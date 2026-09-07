-- ============================================================================
-- SEGURANÇA — Passaporte: fecha IDOR/BOLA anônimo encadeável nas 5 RPCs de
-- leitura POR USUÁRIO. Bug COMPARTILHADO Goiás + Bragantino (schema
-- convergente), pré-existente, SEPARADO da validação funcional do Passaporte.
--
-- VETOR (antes): as 5 filtravam por `coalesce(p_user_id, auth.uid())` (confiam
-- no id vindo do cliente) E tinham EXECUTE pra `anon`. Como `passport_ranking`
-- (público) devolve `user_id`, qualquer um com a publishable key do app
-- (embutida em todo build) colhia uids no ranking e lia dados privados de
-- qualquer usuário passando `p_user_id := <uid alheio>`.
--
-- CORREÇÃO (por função, assinatura PRESERVADA pra não quebrar o Flutter):
--   1. v_uid := auth.uid();
--   2. v_uid null                      -> raise 'not authenticated' (P0001);
--   3. p_user_id não-nulo e <> v_uid   -> raise 'forbidden' (42501);
--   4. a query SEMPRE filtra por v_uid, NUNCA pelo p_user_id do cliente.
-- O parâmetro `p_user_id` continua existindo só por compatibilidade de
-- assinatura (o app envia esse nome via PostgREST) — nunca mais é usado como
-- filtro. As funções passam de `language sql` para `language plpgsql` pra
-- poder recusar explicitamente (raise).
--
-- PERMISSÕES (defensivas/idempotentes, mesmo que hoje o ACL não liste PUBLIC):
--   revoke execute from public; revoke execute from anon;
--   grant execute to authenticated; grant execute to service_role.
--
-- NÃO TOCA: `passport_ranking`, `passport_my_rank` (leaderboard intencional;
-- depois desta correção, saber um uid não dá mais nada privado), nem as RPCs
-- públicas de catálogo (`passport_seasons`, `passport_matches_for_year`).
--
-- IDEMPOTENTE + CLUBE-AGNÓSTICO: rode o MESMO arquivo, sem alteração, nos dois
-- projetos: Goiás `yonozsdgyrhgqrvydbnr` e Bragantino `yrgyzkaaudyzmsqwzecj`.
-- ============================================================================

-- 1) passport_summary ---------------------------------------------------------
create or replace function public.passport_summary(p_user_id uuid default null::uuid)
returns table(total_matches integer, years_with_attendance integer, first_marked_match_id text, first_marked_match_date date, last_marked_match_id text, last_marked_match_date date)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;
  if p_user_id is not null and p_user_id <> v_uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  with mine as (
    select a.match_id, m.match_date, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.user_id = v_uid and a.attended = true
  )
  select
    (select count(*) from mine)::int,
    (select count(distinct season) from mine)::int,
    (select match_id from mine order by match_date asc limit 1),
    (select match_date from mine order by match_date asc limit 1),
    (select match_id from mine order by match_date desc limit 1),
    (select match_date from mine order by match_date desc limit 1);
end;
$function$;

-- 2) passport_attendance_breakdown -------------------------------------------
create or replace function public.passport_attendance_breakdown(p_user_id uuid default null::uuid)
returns table(total_attended integer, wins integer, draws integer, losses integer, home_games integer, away_games integer, goals_for integer, goals_against integer)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;
  if p_user_id is not null and p_user_id <> v_uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select
    count(*)::int,
    count(*) filter (where m.outcome = 'WIN')::int,
    count(*) filter (where m.outcome = 'DRAW')::int,
    count(*) filter (where m.outcome = 'LOSS')::int,
    count(*) filter (where m.club_is_home)::int,
    count(*) filter (where not m.club_is_home)::int,
    coalesce(sum(m.club_score), 0)::int,
    coalesce(sum(m.opponent_score), 0)::int
  from public.passport_attendances a
  join public.passport_matches m on m.id = a.match_id
  where a.user_id = v_uid
    and a.attended = true
    and m.status = 'FINISHED';
end;
$function$;

-- 3) passport_stadium_summary ------------------------------------------------
create or replace function public.passport_stadium_summary(p_user_id uuid default null::uuid)
returns table(unique_stadiums integer, most_visited_stadium_name text, most_visited_stadium_count integer)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;
  if p_user_id is not null and p_user_id <> v_uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  with mine as (
    select m.venue_id, m.match_date
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.user_id = v_uid and a.attended = true and m.status = 'FINISHED'
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
end;
$function$;

-- 4) passport_attended_matches -----------------------------------------------
create or replace function public.passport_attended_matches(p_user_id uuid default null::uuid)
returns table(id text, season integer, match_date date, match_time time without time zone, kickoff_at timestamp with time zone, display_timezone text, date_precision text, status text, competition text, competition_code text, round text, opponent text, club_is_home boolean, neutral_site boolean, home_team text, away_team text, home_score integer, away_score integer, club_score integer, opponent_score integer, score_display text, outcome text, venue_name text, venue_city text)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;
  if p_user_id is not null and p_user_id <> v_uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select
    m.id, m.season, m.match_date, m.match_time, m.kickoff_at,
    m.display_timezone, m.date_precision, m.status, m.competition,
    m.competition_code, m.round, m.opponent, m.club_is_home,
    m.neutral_site, m.home_team, m.away_team, m.home_score,
    m.away_score, m.club_score, m.opponent_score, m.score_display,
    m.outcome, v.display_name, v.city
  from public.passport_matches m
  join public.passport_attendances a on a.match_id = m.id
  left join public.venues v on v.id = m.venue_id
  where a.user_id = v_uid and a.attended = true
  order by m.match_date desc, m.kickoff_at desc nulls last;
end;
$function$;

-- 5) passport_memorable_match_id ---------------------------------------------
create or replace function public.passport_memorable_match_id(p_user_id uuid default null::uuid)
returns text
language plpgsql
stable security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;
  if p_user_id is not null and p_user_id <> v_uid then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return (
    select match_id
    from public.passport_memorable_matches
    where user_id = v_uid
  );
end;
$function$;

-- ---------------------------------------------------------------------------
-- Grants normalizados explicitamente (defensivo + idempotente). Usuário
-- DESLOGADO não tem passaporte -> sem anon/public. service_role preservado.
-- ---------------------------------------------------------------------------
do $$
declare
  sig text;
begin
  foreach sig in array array[
    'public.passport_summary(uuid)',
    'public.passport_attendance_breakdown(uuid)',
    'public.passport_stadium_summary(uuid)',
    'public.passport_attended_matches(uuid)',
    'public.passport_memorable_match_id(uuid)'
  ]
  loop
    execute format('revoke execute on function %s from public;', sig);
    execute format('revoke execute on function %s from anon;', sig);
    execute format('grant execute on function %s to authenticated;', sig);
    execute format('grant execute on function %s to service_role;', sig);
  end loop;
end
$$;
