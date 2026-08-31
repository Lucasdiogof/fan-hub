-- ============================================================================
-- Passaporte Esmeraldino — "Minha trajetória". Rode DEPOIS de
-- passport_esmeraldino.sql e passport_esmeraldino_functions.sql (usa as
-- mesmas tabelas, só acrescenta o que faltava).
--
-- Único dado novo de verdade: qual partida o usuário escolheu como "jogo
-- mais memorável" — todo o resto da tela é calculado em cima de
-- `passport_attendances`/`passport_matches`, que já existem.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Jogo mais memorável — 1 por usuário (`user_id` é a própria chave
-- primária). Sem policy de insert/update/delete pro cliente: só
-- `passport_set_memorable_match` (valida no servidor) e o ajuste dentro de
-- `passport_save_attendances` (auto-limpa se o usuário desmarcar "Eu fui"
-- justamente nessa partida) escrevem aqui.
-- ---------------------------------------------------------------------------
create table if not exists public.passport_memorable_matches (
  user_id uuid primary key references auth.users (id) on delete cascade,
  match_id text not null references public.passport_matches (id) on delete cascade,
  selected_at timestamptz not null default now()
);

alter table public.passport_memorable_matches enable row level security;

drop policy if exists "passport_memorable_matches_read_own" on public.passport_memorable_matches;
create policy "passport_memorable_matches_read_own"
  on public.passport_memorable_matches
  for select
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Define o jogo mais memorável — só aceita partida que o próprio usuário
-- marcou como "Eu fui" (nunca confia em validação só do Flutter).
-- ---------------------------------------------------------------------------
create or replace function public.passport_set_memorable_match(p_match_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_attended boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select attended into v_attended
  from public.passport_attendances
  where user_id = v_uid and match_id = p_match_id;

  if v_attended is not true then
    raise exception 'match_not_attended';
  end if;

  insert into public.passport_memorable_matches (user_id, match_id, selected_at)
  values (v_uid, p_match_id, now())
  on conflict (user_id) do update set
    match_id = excluded.match_id,
    selected_at = now();
end;
$$;

grant execute on function public.passport_set_memorable_match(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Todas as partidas que o usuário marcou como "Eu fui", em qualquer
-- temporada (mesmas colunas de `passport_matches_for_year`, menos
-- `attended` — aqui é sempre true). Usada tanto pro seletor de jogo
-- memorável quanto pra resolver os dados completos da partida já escolhida.
-- ---------------------------------------------------------------------------
create or replace function public.passport_attended_matches()
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
  where a.user_id = auth.uid() and a.attended = true
  order by m.match_date desc, m.kickoff_at desc nulls last;
$$;

grant execute on function public.passport_attended_matches() to authenticated;

-- ---------------------------------------------------------------------------
-- Estádios — quantos distintos e qual o mais visitado, só entre partidas
-- FINISHED marcadas como "Eu fui". Hoje devolve tudo vazio/zero pra
-- qualquer usuário: `venue_id` está null em 100% do catálogo histórico (a
-- fonte não trouxe estádio nenhum — conferido linha a linha no JSON
-- original, não é bug de import). Fica pronta pra funcionar sozinha assim
-- que os dados de `venue_id` forem enriquecidos, sem precisar mexer aqui de
-- novo. Empate de contagem: maior quantidade primeiro, desempate pela
-- presença mais recente naquele estádio.
-- ---------------------------------------------------------------------------
create or replace function public.passport_stadium_summary()
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
    where a.user_id = auth.uid() and a.attended = true and m.status = 'FINISHED'
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

grant execute on function public.passport_stadium_summary() to authenticated;

-- ---------------------------------------------------------------------------
-- Ajuste em `passport_save_attendances`: ao desmarcar "Eu fui" (attended =
-- false), limpa o jogo mais memorável se for justamente essa partida —
-- nunca deixa o memorável apontar pra uma partida que o usuário não marcou
-- mais. Mesma assinatura/shape de retorno de antes, então `create or
-- replace` direto (sem precisar de `drop function` — só o corpo mudou).
-- ---------------------------------------------------------------------------
create or replace function public.passport_save_attendances(p_changes jsonb)
returns table (
  result_match_id text,
  result_attended boolean,
  applied boolean,
  reason text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_match_id text;
  v_attended boolean;
  v_match record;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  for v_item in select * from jsonb_array_elements(p_changes)
  loop
    v_match_id := v_item ->> 'matchId';
    v_attended := (v_item ->> 'attended')::boolean;

    select * into v_match
    from public.passport_matches
    where id = v_match_id;

    if v_match.id is null then
      result_match_id := v_match_id;
      result_attended := v_attended;
      applied := false;
      reason := 'not_found';
      return next;
      continue;
    end if;

    if v_match.status <> 'FINISHED' then
      result_match_id := v_match_id;
      result_attended := v_attended;
      applied := false;
      reason := 'not_finished';
      return next;
      continue;
    end if;

    if v_match.match_date > current_date then
      result_match_id := v_match_id;
      result_attended := v_attended;
      applied := false;
      reason := 'future_match';
      return next;
      continue;
    end if;

    insert into public.passport_attendances as pa (
      user_id, match_id, attended, marked_at, updated_at, source
    )
    values (v_uid, v_match_id, v_attended, now(), now(), 'self_declared')
    on conflict (user_id, match_id) do update set
      attended = v_attended,
      updated_at = now();

    if not v_attended then
      delete from public.passport_memorable_matches
      where user_id = v_uid and match_id = v_match_id;
    end if;

    result_match_id := v_match_id;
    result_attended := v_attended;
    applied := true;
    reason := null;
    return next;
  end loop;
end;
$$;

grant execute on function public.passport_save_attendances(jsonb) to authenticated;
