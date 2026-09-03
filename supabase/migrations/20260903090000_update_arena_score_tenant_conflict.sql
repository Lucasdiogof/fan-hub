-- ============================================================================
-- M3.4 — arena_record_score_for_club passa a fazer o upsert pela bridge
-- tenant-aware. NÃO aplicada ainda (arquivo local, aguardando revisão).
--
-- ÚNICA mudança funcional: o target físico do upsert em
-- user_game_item_progress muda de
--     ON CONFLICT (user_id, game_id, item_id)            [PK legada]
-- para
--     ON CONFLICT (club_id, user_id, game_id, item_id)   [bridge M2.2B-A]
-- (índice ugip_club_user_game_item_uidx, já ativo remotamente).
--
-- Tudo o mais é preservado byte-a-byte: assinatura, retorno, semântica de
-- score/cap/replay, auth.uid(), validação de item+club, o guard
-- `key_scope_collision`, os totais de ranking e o search_path seguro.
--
-- O guard `key_scope_collision` (v_prev de outro club_id) é MANTIDO de
-- propósito: enquanto a PK legada (user_id, game_id, item_id) existir, um
-- INSERT de outro clube com a mesma (user, game, item) violaria a PK; o guard
-- dá um erro claro antes disso. Hoje nunca dispara (1 clube). Vira
-- redundante só na M2.2B-B, quando a PK legada for trocada.
--
-- ACL reafirmado explicitamente no fim (CREATE OR REPLACE não deve confiar em
-- ACL implícito; pg_default_acl pode reconceder anon/service_role).
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

  -- KEY_SCOPE guard: a PK legada (user_id, game_id, item_id) ainda existe. Se
  -- já há progresso sob essa chave e ele é de OUTRO clube, recusa em vez de
  -- deixar o INSERT do novo ON CONFLICT (club_id, user_id, game_id, item_id)
  -- bater na PK legada com erro obscuro. Vira moot na M2.2B-B.
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
  on conflict (club_id, user_id, game_id, item_id) do update set
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

-- ACL reafirmado (regra permanente M3.2) — nunca confiar no default.
revoke execute on function public.arena_record_score_for_club(uuid, text, text, text, int, text, int, int, int, boolean, boolean) from public;
revoke execute on function public.arena_record_score_for_club(uuid, text, text, text, int, text, int, int, int, boolean, boolean) from anon;
revoke execute on function public.arena_record_score_for_club(uuid, text, text, text, int, text, int, int, int, boolean, boolean) from service_role;
grant execute on function public.arena_record_score_for_club(uuid, text, text, text, int, text, int, int, int, boolean, boolean) to authenticated;
