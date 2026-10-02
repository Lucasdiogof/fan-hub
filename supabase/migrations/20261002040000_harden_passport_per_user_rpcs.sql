-- ============================================================================
-- SEGURANÇA — Passaporte: fecha o IDOR/BOLA anônimo das RPCs de leitura por
-- usuário e remove EXECUTE de anon/public de todas as RPCs `passport_*`.
--
-- Promove à cadeia oficial o conteúdo de dois scripts soltos que ficavam fora
-- dela (e por isso o baseline canônico reintroduzia a falha em projeto novo):
--   * supabase/passport_harden_per_user_rpcs.sql
--   * supabase/passport_revoke_anon_execute.sql
-- Os scripts originais permanecem como referência histórica.
--
-- VETOR (antes): cinco RPCs filtravam por `coalesce(p_user_id, auth.uid())`
-- (confiavam no id enviado pelo cliente) e tinham EXECUTE para `anon`. Como
-- `passport_ranking` devolve `user_id`, qualquer pessoa com a chave
-- publishable (embutida em todo build) colhia uids no ranking e lia dados
-- privados de qualquer usuário passando `p_user_id := <uid alheio>`.
--
-- CORREÇÃO (assinaturas PRESERVADAS para não quebrar o Flutter, que envia
-- `p_user_id` via PostgREST):
--   1. v_uid := auth.uid();
--   2. v_uid nulo                       -> raise 'not authenticated' (P0001);
--   3. p_user_id não-nulo e <> v_uid    -> raise 'forbidden' (42501);
--   4. a consulta SEMPRE filtra por v_uid, nunca pelo p_user_id do cliente.
-- `p_user_id` continua existindo só por compatibilidade de assinatura. As
-- funções passam de `language sql` para `language plpgsql` para poder recusar
-- com `raise`.
--
-- PERMISSÕES: toda função `passport_*` perde EXECUTE de public e anon e fica
-- com EXECUTE para authenticated e service_role. O app não chama nenhuma
-- delas sem sessão (usuário deslogado não tem passaporte).
--
-- NÃO ALTERA o corpo de `passport_ranking`/`passport_my_rank` (leaderboard
-- intencional; depois desta correção, conhecer um uid não expõe dado privado)
-- nem das RPCs de catálogo e de escrita — só as permissões delas.
--
-- IDEMPOTENTE e agnóstica de clube: pode rodar mais de uma vez e nos três
-- projetos. Falha de forma explícita (a migration inteira é revertida) se, ao
-- final, anon ainda executar alguma `passport_*` ou authenticated perder acesso.
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
-- Permissões: nenhuma RPC `passport_*` fica executável por anon/public.
-- A lista cobre as 12 funções do baseline canônico e as sobrecargas sem
-- argumento de projetos antigos; as que não existirem são ignoradas.
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
    'public.passport_memorable_match_id(uuid)',
    'public.passport_seasons()',
    'public.passport_matches_for_year(int)',
    'public.passport_my_attendances_for_year(int)',
    'public.passport_save_attendances(jsonb)',
    'public.passport_ranking(int, int)',
    'public.passport_my_rank(int)',
    'public.passport_set_memorable_match(text)',
    'public.passport_summary()',
    'public.passport_attended_matches()',
    'public.passport_stadium_summary()'
  ]
  loop
    if to_regprocedure(sig) is null then
      raise notice 'ignorado (não existe neste projeto): %', sig;
      continue;
    end if;
    execute format('revoke execute on function %s from public;', sig);
    execute format('revoke execute on function %s from anon;', sig);
    execute format('grant execute on function %s to authenticated;', sig);
    execute format('grant execute on function %s to service_role;', sig);
  end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- Verificação final: falha (e reverte a migration) se sobrar exposição ou se o
-- app logado perder acesso. Cobre também qualquer `passport_*` não listada acima.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  exposed text[] := '{}';
  locked_out text[] := '{}';
begin
  for r in
    select p.oid::regprocedure::text as sig,
           has_function_privilege('anon', p.oid, 'execute') as anon_ok,
           has_function_privilege('authenticated', p.oid, 'execute') as auth_ok
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname like 'passport\_%'
      and p.prokind = 'f'
  loop
    if r.anon_ok then exposed := exposed || r.sig; end if;
    if not r.auth_ok then locked_out := locked_out || r.sig; end if;
  end loop;

  if array_length(exposed, 1) > 0 then
    raise exception 'passport_*: anon ainda pode executar: %', exposed;
  end if;
  if array_length(locked_out, 1) > 0 then
    raise exception 'passport_*: authenticated perdeu EXECUTE em: %', locked_out;
  end if;
end
$$;
