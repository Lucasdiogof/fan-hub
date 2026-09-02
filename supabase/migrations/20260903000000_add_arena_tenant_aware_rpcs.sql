-- ============================================================================
-- M3.2 — RPCs tenant-aware ADITIVAS pra Arena (score/ranking). NUNCA
-- substitui nem altera a assinatura de arena_record_score/arena_ranking/
-- arena_my_rank/arena_user_detail — essas continuam byte-idênticas,
-- servindo só o app já publicado enquanto ele existir (M2.2B remove depois).
--
-- p_club_id é OBRIGATÓRIO em toda função nova (nunca aceita NULL, nunca
-- assume Goiás por omissão) — validado explicitamente contra public.clubs
-- em cada uma.
--
-- KEY_SCOPE ainda não resolvido (M2.2B): user_game_item_progress continua
-- com PK (user_id, game_id, item_id), SEM club_id na chave. Pra nunca
-- deixar um clube sobrescrever silenciosamente o progresso salvo de outro
-- clube sob a mesma chave, arena_record_score_for_club recusa (RAISE
-- EXCEPTION) gravar se já existe uma linha com essa chave pertencendo a um
-- club_id diferente — colisão vira erro alto, nunca corrupção silenciosa.
-- Hoje isso é só teórico (clubRegistry só tem 'goias', SECOND_CLUB_BLOCKED
-- = true), mas a função já nasce correta pro dia em que deixar de ser.
-- ============================================================================

create or replace function public.arena_record_score_for_club(
  p_club_id uuid,
  p_game_id text,
  p_item_id text,
  p_event_type text,
  p_attempt_number int default null,
  p_difficulty text default null,
  p_wrong_count int default null,
  p_found_count int default null,
  p_total_count int default null,
  p_was_revealed boolean default false,
  p_was_abandoned boolean default false
)
returns table (points_delta int, item_score int, total_score int, game_score int)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_prev record;
  v_is_replay boolean;
  v_context text;
  v_candidate int;
  v_cap int;
  v_new_score int;
  v_delta int;
  v_item_exists boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  -- item_id precisa existir de verdade na tabela de conteúdo do jogo
  -- correspondente E pertencer ao clube informado — mesma proteção
  -- anti-id-fabricado da RPC legacy, agora também tenant-scoped.
  v_item_exists := case p_game_id
    when 'quiz' then
      exists (
        select 1 from public.quiz_questions
        where id = p_item_id and club_id = p_club_id
      )
    when 'career_path' then
      exists (
        select 1 from public.career_players
        where id = p_item_id and club_id = p_club_id
      )
    when 'guess_player' then
      exists (
        select 1 from public.guess_players
        where id = p_item_id and club_id = p_club_id
      )
    when 'lineup' then
      exists (
        select 1 from public.lineup_matches
        where id = p_item_id and club_id = p_club_id
      )
    else false
  end;

  if not v_item_exists then
    raise exception 'invalid item_id % for game_id % and club_id %',
      p_item_id, p_game_id, p_club_id;
  end if;

  select * into v_prev
  from public.user_game_item_progress
  where user_id = v_uid and game_id = p_game_id and item_id = p_item_id
  for update;

  -- KEY_SCOPE_BLOCKED (ver comentário do arquivo): a chave (user_id,
  -- game_id, item_id) não inclui club_id ainda. Se já existe progresso sob
  -- essa chave e ele é de OUTRO clube, recusa em vez de sobrescrever.
  if v_prev.user_id is not null and v_prev.club_id is distinct from p_club_id then
    raise exception
      'key_scope_collision: item % (game %) already has progress under a different club_id (KEY_SCOPE not yet resolved, see M2.2B)',
      p_item_id, p_game_id;
  end if;

  v_is_replay := v_prev.user_id is not null;
  v_context := case when v_is_replay then 'review' else 'first_play' end;

  v_candidate := case p_game_id
    when 'quiz' then
      case
        when p_event_type in ('first_try_correct', 'review_correct') then
          case p_difficulty
            when 'torcedor' then case when v_is_replay then 3 else 8 end
            when 'esmeraldino' then case when v_is_replay then 4 else 10 end
            when 'fanatico' then case when v_is_replay then 5 else 12 end
            else 0
          end
        else 0
      end
    when 'career_path' then
      case
        when p_was_revealed then 2
        when p_attempt_number is not null then
          case p_attempt_number
            when 1 then 25 when 2 then 20 when 3 then 15
            when 4 then 10 when 5 then 5 else 0
          end
        else 0
      end
    when 'guess_player' then
      case
        when p_was_revealed then 2
        when p_attempt_number is not null then
          case p_attempt_number
            when 1 then 25 when 2 then 22 when 3 then 19 when 4 then 16
            when 5 then 13 when 6 then 10 when 7 then 7 else 0
          end
        else 0
      end
    when 'lineup' then
      case
        when p_was_abandoned then
          round(
            (coalesce(p_found_count, 0)::numeric
              / greatest(coalesce(p_total_count, 1), 1)) * 8
          )::int
        else
          greatest(12, 20 - coalesce(p_wrong_count, 0))
      end
    else 0
  end;

  v_cap := case
    when p_game_id in ('career_path', 'guess_player') and v_is_replay then 5
    when p_game_id = 'lineup' and v_is_replay
      and coalesce(v_prev.was_abandoned, false) then 8
    else v_candidate
  end;

  v_candidate := least(v_candidate, v_cap);
  v_new_score := greatest(coalesce(v_prev.score, 0), v_candidate);
  v_delta := v_new_score - coalesce(v_prev.score, 0);

  insert into public.user_game_item_progress as p (
    user_id, game_id, item_id, club_id, completed_at, attempts_used,
    wrong_attempts, was_revealed, was_abandoned, was_reviewed, score,
    updated_at
  )
  values (
    v_uid, p_game_id, p_item_id, p_club_id, now(), p_attempt_number,
    p_wrong_count, p_was_revealed, p_was_abandoned, v_is_replay, v_new_score,
    now()
  )
  on conflict (user_id, game_id, item_id) do update set
    club_id = p_club_id,
    completed_at = now(),
    attempts_used = coalesce(excluded.attempts_used, p.attempts_used),
    wrong_attempts = coalesce(excluded.wrong_attempts, p.wrong_attempts),
    was_revealed = p.was_revealed or excluded.was_revealed,
    was_abandoned = p.was_abandoned or excluded.was_abandoned,
    was_reviewed = true,
    score = v_new_score,
    updated_at = now();

  insert into public.score_events (
    user_id, game_id, item_id, club_id, event_type, context, attempt_number,
    previous_item_score, new_item_score, points_delta
  )
  values (
    v_uid, p_game_id, p_item_id, p_club_id, p_event_type, v_context,
    p_attempt_number, coalesce(v_prev.score, 0), v_new_score, v_delta
  );

  return query
  select
    v_delta,
    v_new_score,
    (select coalesce(sum(score), 0)::int
      from public.user_game_item_progress
      where user_id = v_uid and club_id = p_club_id),
    (select coalesce(sum(score), 0)::int
      from public.user_game_item_progress
      where user_id = v_uid and club_id = p_club_id and game_id = p_game_id);
end;
$$;

-- Hardening (rodada de revisão): CREATE FUNCTION concede EXECUTE a PUBLIC
-- por padrão — confirmado ao vivo que as 8 RPCs legacy têm `=X/postgres`
-- (PUBLIC) no proacl real, uma dívida (LEGACY_RPC_PUBLIC_EXECUTE_DEBT,
-- tratada depois, nunca nesta etapa — ver o relatório). As 8 novas nunca
-- devem nascer com a mesma dívida: revoga PUBLIC explicitamente ANTES de
-- conceder só o role realmente necessário. Grava score — nunca precisa de
-- `anon` (escrita exige `auth.uid()`), nunca de `service_role` (nenhum
-- caller server-side/Edge Function chama esta RPC).
revoke all on function public.arena_record_score_for_club(
  uuid, text, text, text, int, text, int, int, int, boolean, boolean
) from public;
grant execute on function public.arena_record_score_for_club(
  uuid, text, text, text, int, text, int, int, int, boolean, boolean
) to authenticated;

-- ---------------------------------------------------------------------------
-- Ranking por período, tenant-aware — nunca soma cross-club (window_events
-- filtra por club_id, não só pela janela de tempo).
-- ---------------------------------------------------------------------------
create or replace function public.arena_ranking_for_club(
  p_club_id uuid,
  p_period text default 'all_time',
  p_limit int default 50
)
returns table (
  rank int,
  user_id uuid,
  name text,
  avatar_url text,
  is_member boolean,
  total_score int,
  first_try_count int,
  revealed_or_abandoned_count int,
  reached_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  with window_events as (
    select *
    from public.score_events e
    where e.club_id = p_club_id
      and (
        p_period = 'all_time'
        or (p_period = 'weekly' and e.created_at >= date_trunc(
              'week', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
        or (p_period = 'monthly' and e.created_at >= date_trunc(
              'month', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
      )
  ),
  totals as (
    select
      w.user_id,
      sum(w.points_delta)::int as total_score,
      count(*) filter (
        where w.event_type = 'first_try_correct' and w.points_delta > 0
      )::int as first_try_count,
      count(*) filter (
        where w.event_type in ('revealed', 'abandoned', 'attempts_exhausted')
      )::int as revealed_or_abandoned_count,
      max(w.created_at) as reached_at
    from window_events w
    group by w.user_id
    having sum(w.points_delta) > 0
  )
  select
    row_number() over (
      order by t.total_score desc, t.first_try_count desc,
        t.revealed_or_abandoned_count asc, t.reached_at asc
    )::int as rank,
    t.user_id,
    coalesce(nullif(trim(pr.full_name), ''), 'Torcedor') as name,
    pr.avatar_url,
    -- Mesmo mock explicado na RPC legacy: sócio ainda não é consultável a
    -- partir daqui pro ranking (não é o que get_my_membership_for_club
    -- resolve — aquilo é só "eu, agora"; aqui seria "qualquer um no
    -- ranking").
    false as is_member,
    t.total_score,
    t.first_try_count,
    t.revealed_or_abandoned_count,
    t.reached_at
  from totals t
  left join public.profiles pr on pr.id = t.user_id
  order by t.total_score desc, t.first_try_count desc,
    t.revealed_or_abandoned_count asc, t.reached_at asc
  limit p_limit;
end;
$$;

-- Achado real (ver revisão de segurança): a tela de Ranking da Arena está
-- 100% atrás do redirect global de login (`app_router.dart`, nenhuma rota
-- de Arena está em `_publicRoutes`) — hoje NENHUM caller anônimo alcança
-- esta RPC de verdade, mesmo a legacy `arena_ranking` concedendo `anon`
-- explicitamente (decisão antiga, possivelmente antecipando uso público
-- futuro que não existe hoje). A variante nova nasce com o privilégio que
-- o app REALMENTE usa — nunca `anon`, nunca `service_role`. Revisitar se um
-- uso público real (ex.: embed/web) for decidido no futuro.
revoke all on function public.arena_ranking_for_club(uuid, text, int)
  from public;
grant execute on function public.arena_ranking_for_club(uuid, text, int)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Posição do usuário atual, tenant-aware.
-- ---------------------------------------------------------------------------
create or replace function public.arena_my_rank_for_club(
  p_club_id uuid,
  p_period text default 'all_time'
)
returns table (rank int, total_score int)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  with all_totals as (
    select
      e.user_id,
      sum(e.points_delta)::int as total_score,
      count(*) filter (
        where e.event_type = 'first_try_correct' and e.points_delta > 0
      )::int as first_try_count,
      count(*) filter (
        where e.event_type in ('revealed', 'abandoned', 'attempts_exhausted')
      )::int as revealed_or_abandoned_count,
      max(e.created_at) as reached_at
    from public.score_events e
    where e.club_id = p_club_id
      and (
        p_period = 'all_time'
        or (p_period = 'weekly' and e.created_at >= date_trunc(
              'week', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
        or (p_period = 'monthly' and e.created_at >= date_trunc(
              'month', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
      )
    group by e.user_id
    having sum(e.points_delta) > 0
  ),
  ranked as (
    select
      user_id,
      total_score,
      row_number() over (
        order by total_score desc, first_try_count desc,
          revealed_or_abandoned_count asc, reached_at asc
      )::int as rank
    from all_totals
  )
  select r.rank, r.total_score
  from ranked r
  where r.user_id = auth.uid();
end;
$$;

revoke all on function public.arena_my_rank_for_club(uuid, text) from public;
grant execute on function public.arena_my_rank_for_club(uuid, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Detalhamento de um usuário, tenant-aware. Mesma decisão de design da
-- legacy: confia em p_user_id (não em auth.uid()), de propósito, pro bottom
-- sheet ao tocar em alguém no ranking.
-- ---------------------------------------------------------------------------
create or replace function public.arena_user_detail_for_club(
  p_club_id uuid,
  p_user_id uuid
)
returns table (
  game_id text,
  game_score int,
  first_try_count int,
  review_count int,
  abandoned_or_revealed_count int
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  select
    p.game_id,
    sum(p.score)::int as game_score,
    count(*) filter (
      where not p.was_reviewed and not p.was_revealed and not p.was_abandoned
        and p.score > 0
    )::int as first_try_count,
    count(*) filter (where p.was_reviewed and p.score > 0)::int as review_count,
    count(*) filter (
      where p.was_revealed or p.was_abandoned
    )::int as abandoned_or_revealed_count
  from public.user_game_item_progress p
  where p.user_id = p_user_id and p.club_id = p_club_id
  group by p.game_id;
end;
$$;

revoke all on function public.arena_user_detail_for_club(uuid, uuid)
  from public;
grant execute on function public.arena_user_detail_for_club(uuid, uuid)
  to authenticated;
