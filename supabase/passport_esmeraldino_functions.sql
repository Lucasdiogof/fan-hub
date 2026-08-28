-- ============================================================================
-- Passaporte Esmeraldino — RPCs. Rode depois de passport_esmeraldino.sql
-- (e depois de passport_esmeraldino_import.sql pra já ter dado pra testar).
--
-- Toda regra de negócio mora aqui, não no Flutter: só partida FINISHED
-- pode ser marcada, nunca partida com data futura, e ninguém edita
-- presença de outro usuário — `passport_save_attendances` garante isso
-- mesmo que o cliente mande qualquer coisa.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Temporadas disponíveis + contagem, pro seletor de ano nunca carregar as
-- 1.697 partidas de uma vez.
-- ---------------------------------------------------------------------------
create or replace function public.passport_seasons()
returns table (season int, match_count int, finished_count int)
language sql
security definer
set search_path = public
stable
as $$
  select
    m.season,
    count(*)::int as match_count,
    count(*) filter (where m.status = 'FINISHED')::int as finished_count
  from public.passport_matches m
  group by m.season
  order by m.season desc;
$$;

grant execute on function public.passport_seasons() to authenticated;

-- ---------------------------------------------------------------------------
-- Partidas de uma temporada, já com a presença do usuário atual (left join
-- — nunca uma segunda fonte de verdade pro que está marcado).
-- ---------------------------------------------------------------------------
create or replace function public.passport_matches_for_year(p_season int)
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
  venue_city text,
  attended boolean
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
    m.outcome, v.display_name, v.city,
    coalesce(a.attended, false) as attended
  from public.passport_matches m
  left join public.venues v on v.id = m.venue_id
  left join public.passport_attendances a
    on a.match_id = m.id and a.user_id = auth.uid()
  where m.season = p_season
  order by m.match_date asc, m.kickoff_at asc nulls last;
$$;

grant execute on function public.passport_matches_for_year(int) to authenticated;

-- ---------------------------------------------------------------------------
-- Resumo do usuário pro cabeçalho da tela (total, anos com presença,
-- primeira e última partida marcada). Nunca conta estádios — isso fica pro
-- Passaporte de Estádios, quando `venue_id` estiver enriquecido de verdade.
-- ---------------------------------------------------------------------------
create or replace function public.passport_summary()
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
    where a.user_id = auth.uid() and a.attended = true
  )
  select
    (select count(*) from mine)::int,
    (select count(distinct season) from mine)::int,
    (select match_id from mine order by match_date asc limit 1),
    (select match_date from mine order by match_date asc limit 1),
    (select match_id from mine order by match_date desc limit 1),
    (select match_date from mine order by match_date desc limit 1);
$$;

grant execute on function public.passport_summary() to authenticated;

-- ---------------------------------------------------------------------------
-- Salvamento em lote — uma chamada só pra N marcações/desmarcações.
-- Transacional por natureza (função plpgsql = uma transação); cada item
-- retorna se foi aplicado e por quê não, quando não foi, pro Flutter nunca
-- ficar sem saber o que realmente aconteceu.
--
-- p_changes: [{"matchId": "pe_...", "attended": true}, ...]
-- ---------------------------------------------------------------------------
-- Colunas de saída com nomes DIFERENTES das colunas reais de
-- `passport_attendances` (que a função também escreve) de propósito —
-- `match_id`/`attended` como nome de saída colidiam com as colunas de
-- mesmo nome da tabela, e o PL/pgSQL tratava a referência dentro do corpo
-- da função como ambígua (variável de saída vs. coluna), quebrando em
-- tempo de execução mesmo com a função criada com sucesso (só validado ao
-- rodar, não ao criar).
--
-- `drop` antes do `create or replace`: mudar o shape de `returns table`
-- exige isso — Postgres recusa `create or replace` quando o tipo de
-- retorno (aqui, os nomes das colunas de saída) muda.
drop function if exists public.passport_save_attendances(jsonb);

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

    result_match_id := v_match_id;
    result_attended := v_attended;
    applied := true;
    reason := null;
    return next;
  end loop;
end;
$$;

grant execute on function public.passport_save_attendances(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Presenças do usuário atual numa temporada — usado pra restaurar seleção
-- local ao reabrir a tela/trocar de ano (independente de já ter vindo junto
-- em `passport_matches_for_year`, fica exposto à parte pra telas que só
-- precisam disso).
-- ---------------------------------------------------------------------------
create or replace function public.passport_my_attendances_for_year(p_season int)
returns table (match_id text)
language sql
security definer
set search_path = public
stable
as $$
  select a.match_id
  from public.passport_attendances a
  join public.passport_matches m on m.id = a.match_id
  where a.user_id = auth.uid() and a.attended = true and m.season = p_season;
$$;

grant execute on function public.passport_my_attendances_for_year(int) to authenticated;

-- ---------------------------------------------------------------------------
-- Ranking do Passaporte — 100% separado do `arena_ranking`. Pontuação
-- simples: 1 partida marcada = 1 ponto. Empate: quem bateu a contagem atual
-- há mais tempo fica na frente (mesmo espírito do `reached_at asc` do
-- ranking da Arena). `p_year` null = geral (todas as temporadas).
-- ---------------------------------------------------------------------------
create or replace function public.passport_ranking(
  p_year int default null,
  p_limit int default 50
)
returns table (
  rank int,
  user_id uuid,
  name text,
  avatar_url text,
  is_member boolean,
  match_count int,
  last_marked_at timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  with mine as (
    select a.user_id, a.marked_at, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.attended = true
      and (p_year is null or m.season = p_year)
  ),
  totals as (
    select
      user_id,
      count(*)::int as match_count,
      max(marked_at) as last_marked_at
    from mine
    group by user_id
  )
  select
    row_number() over (
      order by t.match_count desc, t.last_marked_at asc
    )::int as rank,
    t.user_id,
    coalesce(nullif(trim(pr.full_name), ''), 'Torcedor') as name,
    pr.avatar_url,
    -- Mesma limitação já documentada em arena_ranking: status de sócio
    -- ainda é mock/local, sem tabela real no Supabase pra saber se OUTRO
    -- usuário é sócio.
    false as is_member,
    t.match_count,
    t.last_marked_at
  from totals t
  left join public.profiles pr on pr.id = t.user_id
  order by t.match_count desc, t.last_marked_at asc
  limit p_limit;
$$;

grant execute on function public.passport_ranking(int, int) to authenticated;

-- ---------------------------------------------------------------------------
-- Posição do usuário atual — pro destaque "você está em #N" quando ele não
-- aparece nas primeiras linhas do ranking.
-- ---------------------------------------------------------------------------
create or replace function public.passport_my_rank(p_year int default null)
returns table (rank int, match_count int)
language sql
security definer
set search_path = public
stable
as $$
  with mine as (
    select a.user_id, a.marked_at, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.attended = true
      and (p_year is null or m.season = p_year)
  ),
  totals as (
    select
      user_id,
      count(*)::int as match_count,
      max(marked_at) as last_marked_at
    from mine
    group by user_id
  ),
  ranked as (
    select
      user_id,
      match_count,
      row_number() over (
        order by match_count desc, last_marked_at asc
      )::int as rank
    from totals
  )
  select r.rank, r.match_count
  from ranked r
  where r.user_id = auth.uid();
$$;

grant execute on function public.passport_my_rank(int) to authenticated;
