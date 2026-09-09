-- ============================================================================
-- Adiciona 'tactical_identity' e 'player_identity' ao `arena_record_score`
-- (pedido do usuário 2026-09-09): 50 pontos na PRIMEIRA vez que o perfil é
-- descoberto, 0 em qualquer replay — nunca pontua de novo por refazer o
-- teste. Os dois jogos nunca tiveram item de conteúdo real (são um teste de
-- perfil único por usuário, não uma coleção de perguntas/jogadores/partidas
-- como os outros 4), então `p_item_id` aqui é sempre o literal `'profile'`
-- — não uma linha de tabela, só a chave que ancora o anti-replay em
-- `user_game_item_progress` (mesma tabela/mecanismo dos outros jogos,
-- sem nenhuma coluna nova).
--
-- Rodar nos DOIS projetos Supabase (schema convergente, mesma RPC nos
-- dois clubes): Goiás e Bragantino.
--
-- `create or replace function` — idempotente, reproduz a função inteira
-- (Postgres não permite alterar só um `case` sem redefinir tudo).
-- ============================================================================

create or replace function public.arena_record_score(
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
set search_path = public
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

  -- item_id nunca é confiado só porque o cliente mandou — precisa existir de
  -- verdade na tabela de conteúdo do jogo correspondente. Sem isso, qualquer
  -- id fabricado (chamando a RPC direto, fora do app) pontuava como se fosse
  -- conteúdo real, porque o anti-replay só limita a REPETIÇÃO do mesmo id,
  -- nunca barra um id novo. tactical_identity/player_identity não têm
  -- tabela de conteúdo (são um perfil único, não uma coleção) — o "conteúdo
  -- válido" pra eles é só a chave fixa `'profile'`.
  v_item_exists := case p_game_id
    when 'quiz' then
      exists (select 1 from public.quiz_questions where id = p_item_id)
    when 'career_path' then
      exists (select 1 from public.career_players where id = p_item_id)
    when 'guess_player' then
      exists (select 1 from public.guess_players where id = p_item_id)
    when 'lineup' then
      exists (select 1 from public.lineup_matches where id = p_item_id)
    when 'tactical_identity' then p_item_id = 'profile'
    when 'player_identity' then p_item_id = 'profile'
    else false
  end;

  if not v_item_exists then
    raise exception 'invalid item_id % for game_id %', p_item_id, p_game_id;
  end if;

  select * into v_prev
  from public.user_game_item_progress
  where user_id = v_uid and game_id = p_game_id and item_id = p_item_id
  for update;

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
    -- Perfil de identidade — só a PRIMEIRA vez vale ponto (50), qualquer
    -- replay vale 0. Nunca escalona por dificuldade/tentativa (não existe
    -- "errar" um teste de perfil).
    when 'tactical_identity' then case when v_is_replay then 0 else 50 end
    when 'player_identity' then case when v_is_replay then 0 else 50 end
    else 0
  end;

  -- Conteúdo já "estragado" (revelado/desistido) numa passada anterior
  -- nunca pode voltar a valer o topo da tabela numa passada seguinte,
  -- não importa que tentativa o cliente reporte agora.
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
    user_id, game_id, item_id, completed_at, attempts_used, wrong_attempts,
    was_revealed, was_abandoned, was_reviewed, score, updated_at
  )
  values (
    v_uid, p_game_id, p_item_id, now(), p_attempt_number, p_wrong_count,
    p_was_revealed, p_was_abandoned, v_is_replay, v_new_score, now()
  )
  on conflict (user_id, game_id, item_id) do update set
    completed_at = now(),
    attempts_used = coalesce(excluded.attempts_used, p.attempts_used),
    wrong_attempts = coalesce(excluded.wrong_attempts, p.wrong_attempts),
    was_revealed = p.was_revealed or excluded.was_revealed,
    was_abandoned = p.was_abandoned or excluded.was_abandoned,
    was_reviewed = true,
    score = v_new_score,
    updated_at = now();

  insert into public.score_events (
    user_id, game_id, item_id, event_type, context, attempt_number,
    previous_item_score, new_item_score, points_delta
  )
  values (
    v_uid, p_game_id, p_item_id, p_event_type, v_context, p_attempt_number,
    coalesce(v_prev.score, 0), v_new_score, v_delta
  );

  return query
  select
    v_delta,
    v_new_score,
    (select coalesce(sum(score), 0)::int
      from public.user_game_item_progress where user_id = v_uid),
    (select coalesce(sum(score), 0)::int
      from public.user_game_item_progress
      where user_id = v_uid and game_id = p_game_id);
end;
$$;

grant execute on function public.arena_record_score(
  text, text, text, int, text, int, int, int, boolean, boolean
) to authenticated;
