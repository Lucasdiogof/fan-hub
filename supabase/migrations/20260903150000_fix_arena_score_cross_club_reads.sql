-- Micro-etapa pré-M4: corrige a única leitura tenant-scoped que faltava
-- filtrar por club_id em arena_record_score_for_club.
--
-- Auditoria ao vivo (prosrc) do corpo completo, feita antes de editar,
-- mostrou que das 3 leituras originalmente suspeitas (v_prev, soma de
-- total_score, soma de game_score), só v_prev estava de fato sem
-- club_id = p_club_id. As duas somas já filtravam corretamente. Esta
-- migration corrige apenas o problema real confirmado.
--
-- key_scope_collision guard: mantido (KEEP_DEFENSIVELY, decisão explícita
-- do dono) mesmo virando estruturalmente inalcançável agora que v_prev só
-- pode conter uma linha do próprio p_club_id — código morto inofensivo,
-- não um motivo técnico para remover.
--
-- Assinatura, tipo de retorno, SECURITY DEFINER, search_path, semântica de
-- pontuação, ON CONFLICT tenant-aware e mensagens de erro preservados
-- integralmente. Nenhuma tabela/constraint/index/default de tabela é
-- alterada aqui.
--
-- Correção (1ª tentativa falhou, SQLSTATE 42P13): a assinatura precisa
-- reproduzir os 7 DEFAULTs que a função já tem em produção
-- (p_attempt_number/p_difficulty/p_wrong_count/p_found_count/p_total_count
-- DEFAULT NULL, p_was_revealed/p_was_abandoned DEFAULT false) — Postgres
-- recusa um CREATE OR REPLACE FUNCTION que remova defaults existentes.
-- pg_get_function_identity_arguments() omite defaults por design (serve só
-- pra resolução de overload); pg_get_function_arguments() é a fonte certa
-- pra reconstruir uma assinatura completa.

do $$
begin
  if (select count(*) from public.clubs) <> 1
     or not exists (
       select 1 from public.clubs
       where id = '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
         and slug = 'goias'
     )
  then
    raise exception 'M2.2B-B/pré-M4 guard: esperava clubs=1 (Goiás) — abortando';
  end if;
end $$;

create or replace function public.arena_record_score_for_club(
  p_club_id uuid,
  p_game_id text,
  p_item_id text,
  p_event_type text,
  p_attempt_number integer default null::integer,
  p_difficulty text default null::text,
  p_wrong_count integer default null::integer,
  p_found_count integer default null::integer,
  p_total_count integer default null::integer,
  p_was_revealed boolean default false,
  p_was_abandoned boolean default false
)
returns table(
  points_delta integer,
  item_score integer,
  total_score integer,
  game_score integer
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $func$
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
    and club_id = p_club_id
  for update;

  -- KEY_SCOPE guard: mantido por defesa (KEEP_DEFENSIVELY), mesmo que agora
  -- estruturalmente inalcançável — v_prev só pode conter uma linha do
  -- próprio p_club_id desde a correção acima, então esta condição nunca
  -- mais deve ser verdadeira. Histórico: protegia contra o INSERT bater na
  -- PK legada (user_id, game_id, item_id), que já não existe desde a
  -- M2.2B-B (KEY_SCOPE_FINAL=true).
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
$func$;

revoke all on function public.arena_record_score_for_club(
  uuid, text, text, text, integer, text, integer, integer, integer, boolean, boolean
) from public, anon, service_role;

grant execute on function public.arena_record_score_for_club(
  uuid, text, text, text, integer, text, integer, integer, integer, boolean, boolean
) to authenticated;
