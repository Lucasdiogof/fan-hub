-- ============================================================================
-- Escalação da Torcida — rode este arquivo no SQL Editor do Supabase do Goiás.
-- Cria a tabela de votos (1 por usuário por jogo, editável), a RLS (cada um
-- só mexe no próprio voto) e a função de agregação (security definer) que
-- devolve o consolidado anônimo pra montar a "Escalação da torcida".
-- ============================================================================

create table if not exists public.match_lineup_votes (
  id uuid primary key default gen_random_uuid(),
  match_id text not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  formation text not null,
  slots jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (match_id, user_id)
);

create index if not exists match_lineup_votes_match_idx
  on public.match_lineup_votes (match_id);

alter table public.match_lineup_votes enable row level security;

drop policy if exists "read own vote" on public.match_lineup_votes;
drop policy if exists "insert own vote" on public.match_lineup_votes;
drop policy if exists "update own vote" on public.match_lineup_votes;

create policy "read own vote" on public.match_lineup_votes
  for select using (auth.uid() = user_id);
create policy "insert own vote" on public.match_lineup_votes
  for insert with check (auth.uid() = user_id);
create policy "update own vote" on public.match_lineup_votes
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Agregação anônima: total de votos, contagem por formação e, por formação,
-- a contagem de cada jogador em cada slot. O app escolhe a formação mais
-- votada e o jogador mais escolhido de cada slot dela.
create or replace function public.crowd_lineup(p_match_id text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  with v as (
    select formation, slots
    from public.match_lineup_votes
    where match_id = p_match_id
  ),
  fc as (
    select formation, count(*)::int c from v group by formation
  ),
  sc as (
    select formation, (s ->> 'i')::int slot, s ->> 'pid' pid, count(*)::int c
    from v, jsonb_array_elements(v.slots) s
    group by formation, (s ->> 'i')::int, s ->> 'pid'
  ),
  slot_players as (
    select formation, slot, jsonb_object_agg(pid, c) players
    from sc group by formation, slot
  ),
  formation_slots as (
    select formation, jsonb_object_agg(slot::text, players) slotmap
    from slot_players group by formation
  )
  select jsonb_build_object(
    'total_votes', (select count(*)::int from v),
    'formations', coalesce((select jsonb_object_agg(formation, c) from fc), '{}'::jsonb),
    'slots', coalesce((select jsonb_object_agg(formation, slotmap) from formation_slots), '{}'::jsonb)
  );
$$;

grant execute on function public.crowd_lineup(text) to authenticated, anon;
