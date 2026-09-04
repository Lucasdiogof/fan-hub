-- ============================================================================
-- Seed de `public.clubs` — SOMENTE Goiás Esporte Clube. id vem do club
-- registry persistido (tooling/multiclub/clubs_registry.json), NUNCA
-- gen_random_uuid(), NUNCA derivado do slug — se o slug for corrigido no
-- futuro, o id permanece o mesmo (o registry casa por registryLookupKey,
-- um identificador interno separado do valor da coluna slug).
--
-- GERADA por tooling/multiclub/generate_clubs_seed.mjs — NUNCA editar à
-- mão.
--
-- club_id é IDENTIDADE persistente; slug é atributo mutável. Por isso o
-- conflito é resolvido por (id), nunca por (slug):
--   - mesmo id + mesmo slug já presentes -> idempotente, ON CONFLICT (id)
--     DO NOTHING não faz nada, seguro reaplicar.
--   - slug já usado por uma linha com id DIFERENTE -> NÃO deve ser
--     absorvido silenciosamente. Nunca usar ON CONFLICT (slug) DO UPDATE
--     (isso preservaria o id ERRADO). O guard abaixo detecta esse caso
--     ANTES do INSERT e lança uma exceção explícita — sem ele, a própria
--     UNIQUE(slug) da tabela já rejeitaria o INSERT (erro genérico do
--     Postgres), mas preferimos uma mensagem que deixa claro O QUE
--     aconteceu.
-- ============================================================================

do $$
declare
  existing_id uuid;
begin
  select id into existing_id from public.clubs where slug = 'goias';
  if existing_id is not null and existing_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid then
    raise exception 'clubs.slug % já existe com id % (esperado 4c16340d-300c-5ab2-903f-17519db9b146) — conflito de identidade de clube, PARE e investigue antes de continuar. Nunca fazer UPDATE silencioso do id.', 'goias', existing_id;
  end if;
end $$;

insert into public.clubs (id, slug, name, short_name)
values
  ('4c16340d-300c-5ab2-903f-17519db9b146', 'goias', 'Goiás Esporte Clube', 'Goiás')
on conflict (id) do nothing;
