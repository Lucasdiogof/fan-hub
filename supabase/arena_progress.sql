-- ============================================================================
-- Progressão persistente da Arena Esmeraldina (Quiz, Adivinhe a Escalação,
-- Adivinhe o Jogador) — rode este arquivo no SQL Editor do Supabase.
-- Cada usuário só enxerga/edita o próprio progresso (RLS por auth.uid()).
-- ============================================================================

-- Quiz: uma linha por pergunta já respondida por aquele usuário (upsert —
-- responder de novo só atualiza a linha, nunca duplica progresso).
create table if not exists public.quiz_question_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  question_id text not null,
  difficulty text not null,
  was_correct_first_attempt boolean not null,
  pending_review boolean not null default false,
  answered_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, question_id)
);

create index if not exists quiz_question_progress_user_difficulty_idx
  on public.quiz_question_progress (user_id, difficulty);

alter table public.quiz_question_progress enable row level security;

drop policy if exists "read own quiz progress" on public.quiz_question_progress;
drop policy if exists "insert own quiz progress" on public.quiz_question_progress;
drop policy if exists "update own quiz progress" on public.quiz_question_progress;

create policy "read own quiz progress" on public.quiz_question_progress
  for select using (auth.uid() = user_id);
create policy "insert own quiz progress" on public.quiz_question_progress
  for insert with check (auth.uid() = user_id);
create policy "update own quiz progress" on public.quiz_question_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Quiz: sessão em andamento (no máx. 1 por usuário+nível) — permite retomar
-- exatamente de onde parou se o app fechar no meio.
create table if not exists public.quiz_active_session (
  user_id uuid not null references auth.users (id) on delete cascade,
  difficulty text not null,
  question_ids text[] not null,
  current_index int not null default 0,
  answers jsonb not null default '[]'::jsonb,
  is_review boolean not null default false,
  started_at timestamptz not null default now(),
  primary key (user_id, difficulty)
);

alter table public.quiz_active_session enable row level security;

drop policy if exists "read own quiz session" on public.quiz_active_session;
drop policy if exists "insert own quiz session" on public.quiz_active_session;
drop policy if exists "update own quiz session" on public.quiz_active_session;
drop policy if exists "delete own quiz session" on public.quiz_active_session;

create policy "read own quiz session" on public.quiz_active_session
  for select using (auth.uid() = user_id);
create policy "insert own quiz session" on public.quiz_active_session
  for insert with check (auth.uid() = user_id);
create policy "update own quiz session" on public.quiz_active_session
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own quiz session" on public.quiz_active_session
  for delete using (auth.uid() = user_id);

-- Adivinhe a Escalação: reaproveita o JSON que LineupGameState.toJson() já
-- produz (guesses, keyboardState, solved/failed por jogador) — só troca o
-- destino de SharedPreferences pra Supabase. status é derivado de
-- completed_at só pra facilitar contar "quantas concluídas" sem decodificar
-- JSON no SQL.
create table if not exists public.lineup_match_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  match_id text not null,
  game_state jsonb not null,
  status text not null default 'in_progress',
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, match_id)
);

create index if not exists lineup_match_progress_user_status_idx
  on public.lineup_match_progress (user_id, status);

alter table public.lineup_match_progress enable row level security;

drop policy if exists "read own lineup progress" on public.lineup_match_progress;
drop policy if exists "insert own lineup progress" on public.lineup_match_progress;
drop policy if exists "update own lineup progress" on public.lineup_match_progress;

create policy "read own lineup progress" on public.lineup_match_progress
  for select using (auth.uid() = user_id);
create policy "insert own lineup progress" on public.lineup_match_progress
  for insert with check (auth.uid() = user_id);
create policy "update own lineup progress" on public.lineup_match_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Adivinhe o Jogador: mesmo padrão, reaproveitando CareerRoundState.toJson().
create table if not exists public.career_path_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  player_id text not null,
  round_state jsonb not null,
  status text not null default 'in_progress',
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, player_id)
);

create index if not exists career_path_progress_user_status_idx
  on public.career_path_progress (user_id, status);

alter table public.career_path_progress enable row level security;

drop policy if exists "read own career progress" on public.career_path_progress;
drop policy if exists "insert own career progress" on public.career_path_progress;
drop policy if exists "update own career progress" on public.career_path_progress;

create policy "read own career progress" on public.career_path_progress
  for select using (auth.uid() = user_id);
create policy "insert own career progress" on public.career_path_progress
  for insert with check (auth.uid() = user_id);
create policy "update own career progress" on public.career_path_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- "Última partida/jogador visto" — substitui LineupStorage/CareerPathStorage
-- .loadSelectedMatchId()/.loadSelectedPlayerId() locais. game_id é 'lineup'
-- ou 'career_path'.
create table if not exists public.arena_selected_content (
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id text not null,
  selected_id text not null,
  primary key (user_id, game_id)
);

alter table public.arena_selected_content enable row level security;

drop policy if exists "read own selected content" on public.arena_selected_content;
drop policy if exists "insert own selected content" on public.arena_selected_content;
drop policy if exists "update own selected content" on public.arena_selected_content;

create policy "read own selected content" on public.arena_selected_content
  for select using (auth.uid() = user_id);
create policy "insert own selected content" on public.arena_selected_content
  for insert with check (auth.uid() = user_id);
create policy "update own selected content" on public.arena_selected_content
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Conquista permanente — inserida uma vez (on conflict do nothing) na
-- primeira vez que Quiz+Escalação+Jogador batem 100%, e nunca mais apagada
-- ou sobrescrita, mesmo que conteúdo novo derrube o progresso atual de novo
-- pra menos de 100%.
create table if not exists public.arena_achievements (
  user_id uuid not null references auth.users (id) on delete cascade,
  achievement_id text not null,
  unlocked_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

alter table public.arena_achievements enable row level security;

drop policy if exists "read own achievements" on public.arena_achievements;
drop policy if exists "insert own achievements" on public.arena_achievements;

create policy "read own achievements" on public.arena_achievements
  for select using (auth.uid() = user_id);
create policy "insert own achievements" on public.arena_achievements
  for insert with check (auth.uid() = user_id);
