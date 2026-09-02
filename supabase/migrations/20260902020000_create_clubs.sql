-- ============================================================================
-- Cria `public.clubs` — a MENOR fundação possível pra dar um `club_id`
-- estável a `player_club_spells` (Etapa B do multiclube), SEM abrir agora
-- toda a implementação multi-clube (branding, integrations, social,
-- features, flavors, Worker). Essas tabelas ficam pra quando o produto
-- realmente precisar de um 2º clube configurado — este schema aqui NUNCA
-- as força a existir.
--
-- Migration ADITIVA: não altera `people`, `person_aliases` nem nenhuma
-- tabela existente.
--
-- clubs.id NÃO usa DEFAULT gen_random_uuid() — precisa ser ESTÁVEL entre
-- regenerações do seed, e principalmente sobreviver a uma futura correção
-- de `slug`/`name` sem trocar de UUID. id = uuidv5(CLUBS_UUID_NAMESPACE,
-- canonicalClubKey), canonicalClubKey vem de um registry persistido
-- (tooling/multiclub/clubs_registry.json) — nunca derivado do slug em si.
-- ============================================================================

create table if not exists public.clubs (
  id uuid primary key,
  slug text not null unique,
  name text not null,
  short_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.clubs is
  'Fundação MÍNIMA multi-clube — só o necessário pra dar club_id a '
  'player_club_spells. NÃO inclui branding/integrations/social/features '
  '(propositalmente fora de escopo da Etapa B) — essas tabelas nascem numa '
  'migration própria quando o produto precisar de fato de um 2º clube.';
comment on column public.clubs.id is
  'Vem do club registry (tooling/multiclub/clubs_registry.json) — NUNCA '
  'gen_random_uuid(), NUNCA derivado diretamente do slug (uma correção de '
  'slug no futuro não pode trocar o id).';
comment on column public.clubs.slug is
  'Chave natural de uso corrente (ex.: "goias") — pode ser corrigida no '
  'futuro sem afetar o id, que vem do registry, não do valor desta coluna.';

alter table public.clubs enable row level security;

-- Permissões EXPLÍCITAS — mesmo racional de person_aliases: não depender
-- do default ACL implícito do schema public pra anon/authenticated.
revoke all on table public.clubs from anon, authenticated;
grant select on table public.clubs to anon, authenticated;

drop policy if exists "read clubs" on public.clubs;
create policy "read clubs" on public.clubs
  for select using (true);
