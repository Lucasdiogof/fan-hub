-- ============================================================================
-- Ranking da Torcida — pontuação cumulativa cross-game (Quiz, Adivinhe a
-- Escalação, Adivinhe o Jogador, Quem Vestiu o Manto?). Rode no SQL Editor
-- do Supabase. SUBSTITUI o ranking antigo (arena_scores/arena_leaderboard,
-- só Quiz por dificuldade) — remove tudo daquele sistema antes de criar o
-- novo, não há uso paralelo dos dois.
--
-- Regra definitiva mora aqui, não no Flutter: `arena_record_score` recebe
-- o RESULTADO cru de uma jogada (tentativa, revelou, desistiu, erros...) e
-- decide sozinha quanto isso vale, olhando o estado anterior do item em
-- `user_game_item_progress`. O Flutter nunca manda uma pontuação pronta —
-- só o que aconteceu. Cada item só pode SUBIR de pontuação por delta
-- contra o que já tem salvo, nunca ser re-creditado do zero — isso sozinho
-- fecha replay/reabrir o app/voltar tela como forma de farmar pontos,
-- porque o item já visitado uma vez limita (ou até zera) o que uma segunda
-- passada pode valer, não importa quantas vezes ela aconteça.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Remove o sistema de ranking antigo (Quiz por dificuldade + Pênaltis).
-- ---------------------------------------------------------------------------
drop function if exists public.arena_leaderboard(text, int);
drop function if exists public.arena_save_best(text, int);
drop table if exists public.arena_scores;

-- ---------------------------------------------------------------------------
-- Estado definitivo de cada conteúdo, por usuário. Chave (user, game, item)
-- — nunca duas linhas pro mesmo conteúdo, upsert sempre.
-- ---------------------------------------------------------------------------
create table if not exists public.user_game_item_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id text not null,
  item_id text not null,
  first_played_at timestamptz not null default now(),
  completed_at timestamptz,
  attempts_used int,
  wrong_attempts int,
  was_revealed boolean not null default false,
  was_abandoned boolean not null default false,
  was_reviewed boolean not null default false,
  score int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, game_id, item_id)
);

create index if not exists user_game_item_progress_user_game_idx
  on public.user_game_item_progress (user_id, game_id);

alter table public.user_game_item_progress enable row level security;

drop policy if exists "read own item progress" on public.user_game_item_progress;
create policy "read own item progress" on public.user_game_item_progress
  for select using (auth.uid() = user_id);
-- Sem policy de insert/update: só a RPC security-definer grava aqui — o
-- cliente nunca escreve pontuação direto na tabela.

-- ---------------------------------------------------------------------------
-- Histórico append-only. Nunca editado/apagado — o ranking pode ser
-- reconstruído inteiramente a partir daqui.
-- ---------------------------------------------------------------------------
create table if not exists public.score_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id text not null,
  item_id text not null,
  event_type text not null,
  context text not null,
  attempt_number int,
  previous_item_score int not null,
  new_item_score int not null,
  points_delta int not null,
  created_at timestamptz not null default now()
);

create index if not exists score_events_user_created_idx
  on public.score_events (user_id, created_at);
create index if not exists score_events_user_game_created_idx
  on public.score_events (user_id, game_id, created_at);

alter table public.score_events enable row level security;

drop policy if exists "read own score events" on public.score_events;
create policy "read own score events" on public.score_events
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- RPC transacional — chamada uma vez por conclusão de conteúdo (resposta
-- certa do quiz, rodada terminada do Adivinhe o Jogador/Quem Vestiu o
-- Manto, escalação concluída ou desistida). Toda a lógica de pontos por
-- jogo mora aqui dentro, não no Flutter.
--
-- p_game_id: 'quiz' | 'career_path' | 'guess_player' | 'lineup'
-- p_item_id: id único do conteúdo dentro do jogo (question_id / player_id /
--            secret round id / match_id)
-- p_event_type: só descritivo, vai pro histórico (first_try_correct,
--   review_correct, correct_after_errors, attempts_exhausted, abandoned,
--   revealed, wrong_answer, completed)
-- p_attempt_number: tentativa em que acertou (career_path 1–5, guess_player
--   1–7) — null quando não se aplica
-- p_difficulty: 'torcedor' | 'esmeraldino' | 'fanatico' (só quiz)
-- p_wrong_count: erros na escalação concluída normalmente (só lineup)
-- p_found_count/p_total_count: jogadores encontrados/total ao desistir (só
--   lineup)
-- p_was_revealed: verdadeiro/desistiu — o item deixou de ser "não
--   respondido" só porque a resposta foi mostrada (career_path/guess_player)
-- p_was_abandoned: desistiu da escalação (lineup)
--
-- "Já joguei isso antes?" é decidido 100% pelo servidor (existe linha em
-- user_game_item_progress?), nunca por uma flag que o Flutter mande —
-- assim não tem como o cliente se declarar "primeira vez" numa segunda
-- passada só reabrindo a tela ou o app.
-- ---------------------------------------------------------------------------
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
begin
  if v_uid is null then
    raise exception 'not authenticated';
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

-- ---------------------------------------------------------------------------
-- Ranking por período. p_period: 'weekly' | 'monthly' | 'all_time'.
-- Semanal/mensal nunca zeram pontos — só filtram score_events pela janela
-- de tempo (America/Sao_Paulo), então o total "geral" nunca perde histórico.
-- Desempate: pontos desc, acertos de primeira desc, revelados+desistências
-- asc, data em que bateu aquela pontuação asc (quem chegou primeiro).
-- ---------------------------------------------------------------------------
create or replace function public.arena_ranking(
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
language sql
security definer
set search_path = public
as $$
  with window_events as (
    select *
    from public.score_events e
    where p_period = 'all_time'
      or (p_period = 'weekly' and e.created_at >= date_trunc(
            'week', now() at time zone 'America/Sao_Paulo'
          ) at time zone 'America/Sao_Paulo')
      or (p_period = 'monthly' and e.created_at >= date_trunc(
            'month', now() at time zone 'America/Sao_Paulo'
          ) at time zone 'America/Sao_Paulo')
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
    -- Sempre falso por enquanto: status de sócio ainda é 100% mock/local
    -- (MockMembershipRepository, sem tabela no Supabase) — não dá pra saber
    -- se OUTRO usuário é sócio a partir do servidor hoje. Quando a
    -- associação virar real no Supabase, troca esta linha por um join na
    -- tabela/coluna real de status.
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
$$;

grant execute on function public.arena_ranking(text, int) to authenticated, anon;

-- ---------------------------------------------------------------------------
-- Posição do usuário atual no ranking (mesmo cálculo/desempate acima),
-- pro card fixo "Sua posição" quando ele não aparece nas primeiras N linhas.
-- ---------------------------------------------------------------------------
create or replace function public.arena_my_rank(p_period text default 'all_time')
returns table (rank int, total_score int)
language sql
security definer
set search_path = public
as $$
  with window_events as (
    select *
    from public.score_events e
    where e.user_id = auth.uid()
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
  all_totals as (
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
    where p_period = 'all_time'
      or (p_period = 'weekly' and e.created_at >= date_trunc(
            'week', now() at time zone 'America/Sao_Paulo'
          ) at time zone 'America/Sao_Paulo')
      or (p_period = 'monthly' and e.created_at >= date_trunc(
            'month', now() at time zone 'America/Sao_Paulo'
          ) at time zone 'America/Sao_Paulo')
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
$$;

grant execute on function public.arena_my_rank(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Detalhamento de um usuário: distribuição de pontos por jogo + estatísticas
-- secundárias (acertos de primeira/revisão, desistências), pro bottom
-- sheet/tela ao tocar em alguém no ranking. Sempre "geral" (não filtra por
-- período) — o detalhamento mostra a carreira completa do jogador.
-- ---------------------------------------------------------------------------
create or replace function public.arena_user_detail(p_user_id uuid)
returns table (
  game_id text,
  game_score int,
  first_try_count int,
  review_count int,
  abandoned_or_revealed_count int
)
language sql
security definer
set search_path = public
as $$
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
  where p.user_id = p_user_id
  group by p.game_id;
$$;

grant execute on function public.arena_user_detail(uuid) to authenticated;
