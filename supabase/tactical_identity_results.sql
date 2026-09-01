-- ============================================================================
-- "Identidade Futebolística" — jogo de perfil da Arena, SEM ranking. Guarda
-- só o ÚLTIMO resultado do usuário (upsert por user_id) — rode este arquivo
-- no SQL Editor do Supabase.
--
-- `answers` (os 10 ids de alternativa escolhidos, na ordem das perguntas)
-- é a coluna que de fato importa: o app sempre reconstrói o resultado a
-- partir dela, nunca confia nas colunas denormalizadas (x, y, archetype,
-- percentuais, closest_coach_id) pra montar a tela — elas só existem pra
-- facilitar consulta/analytics direto no banco.
-- ============================================================================

create table if not exists public.tactical_identity_results (
  user_id uuid not null references auth.users (id) on delete cascade primary key,
  game_type text not null default 'tactical_identity',
  x smallint not null,
  y smallint not null,
  archetype text not null,
  possession_percentage smallint not null,
  vertical_percentage smallint not null,
  dogmatic_percentage smallint not null,
  pragmatic_percentage smallint not null,
  closest_coach_id text,
  answers jsonb not null,
  completed_at timestamptz not null default now()
);

alter table public.tactical_identity_results enable row level security;

drop policy if exists "read own tactical identity result" on public.tactical_identity_results;
drop policy if exists "insert own tactical identity result" on public.tactical_identity_results;
drop policy if exists "update own tactical identity result" on public.tactical_identity_results;

create policy "read own tactical identity result" on public.tactical_identity_results
  for select using (auth.uid() = user_id);
create policy "insert own tactical identity result" on public.tactical_identity_results
  for insert with check (auth.uid() = user_id);
create policy "update own tactical identity result" on public.tactical_identity_results
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
