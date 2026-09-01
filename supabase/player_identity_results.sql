-- ============================================================================
-- "Que craque esmeraldino é você?" — jogo de perfil da Arena, SEM ranking.
-- Guarda só o ÚLTIMO resultado do usuário (upsert por user_id) — rode este
-- arquivo no SQL Editor do Supabase.
--
-- `answers` (os 10 ids de alternativa escolhidos, na ordem das perguntas) é
-- a coluna que de fato importa: o app sempre reconstrói o resultado a
-- partir dela, nunca confia nas colunas denormalizadas (atributos,
-- archetype, closest_player_id) pra montar a tela — elas só existem pra
-- facilitar consulta/analytics direto no banco. Mesmo padrão de
-- `tactical_identity_results.sql`, tabela independente (os dois testes não
-- compartilham linha nem infraestrutura).
-- ============================================================================

create table if not exists public.player_identity_results (
  user_id uuid not null references auth.users (id) on delete cascade primary key,
  test_type text not null default 'player_identity',
  archetype text not null,
  creativity smallint not null,
  definition smallint not null,
  leadership smallint not null,
  intensity smallint not null,
  technique smallint not null,
  tactics smallint not null,
  closest_player_id text,
  answers jsonb not null,
  completed_at timestamptz not null default now()
);

alter table public.player_identity_results enable row level security;

drop policy if exists "read own player identity result" on public.player_identity_results;
drop policy if exists "insert own player identity result" on public.player_identity_results;
drop policy if exists "update own player identity result" on public.player_identity_results;

create policy "read own player identity result" on public.player_identity_results
  for select using (auth.uid() = user_id);
create policy "insert own player identity result" on public.player_identity_results
  for insert with check (auth.uid() = user_id);
create policy "update own player identity result" on public.player_identity_results
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
