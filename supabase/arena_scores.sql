-- ============================================================================
-- Recordes da Arena na nuvem + Ranking da Torcida. Rode no SQL Editor do
-- Supabase. Guarda o melhor placar de cada usuário por jogo (arena_scores),
-- com RLS (cada um só mexe no próprio), + 2 RPCs security-definer:
--   arena_save_best  → grava mantendo sempre o MAIOR placar
--   arena_leaderboard→ top N de um jogo, anônimo-friendly (só nome do perfil)
-- ============================================================================

create table if not exists public.arena_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id text not null,
  best int not null default 0,
  updated_at timestamptz not null default now(),
  unique (user_id, game_id)
);

create index if not exists arena_scores_game_idx
  on public.arena_scores (game_id, best desc);

alter table public.arena_scores enable row level security;

drop policy if exists "read own scores" on public.arena_scores;
drop policy if exists "insert own scores" on public.arena_scores;
drop policy if exists "update own scores" on public.arena_scores;

create policy "read own scores" on public.arena_scores
  for select using (auth.uid() = user_id);
create policy "insert own scores" on public.arena_scores
  for insert with check (auth.uid() = user_id);
create policy "update own scores" on public.arena_scores
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Grava o placar mantendo sempre o maior; devolve o melhor já salvo.
create or replace function public.arena_save_best(p_game_id text, p_score int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_best int;
begin
  insert into public.arena_scores (user_id, game_id, best, updated_at)
  values (auth.uid(), p_game_id, p_score, now())
  on conflict (user_id, game_id) do update
    set best = greatest(public.arena_scores.best, excluded.best),
        updated_at = case
          when excluded.best > public.arena_scores.best then now()
          else public.arena_scores.updated_at
        end
  returning best into v_best;
  return v_best;
end;
$$;

grant execute on function public.arena_save_best(text, int) to authenticated;

-- Ranking de um jogo: top N por placar (desempate pelo mais antigo a bater).
-- Devolve só o nome do perfil (formatação de privacidade fica no app).
create or replace function public.arena_leaderboard(p_game_id text, p_limit int default 20)
returns table (rank int, user_id uuid, name text, best int, updated_at timestamptz)
language sql
security definer
set search_path = public
as $$
  select
    row_number() over (order by s.best desc, s.updated_at asc)::int as rank,
    s.user_id,
    coalesce(nullif(trim(p.full_name), ''), 'Torcedor') as name,
    s.best,
    s.updated_at
  from public.arena_scores s
  left join public.profiles p on p.id = s.user_id
  where s.game_id = p_game_id and s.best > 0
  order by s.best desc, s.updated_at asc
  limit p_limit;
$$;

grant execute on function public.arena_leaderboard(text, int) to authenticated, anon;
