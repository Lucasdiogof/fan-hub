-- Bootstrap de identidade — Vila Nova Futebol Clube.
-- NÃO aplicado ainda: o projeto Supabase do Vila Nova ainda não existe
-- (tarefa do usuário). Standalone, fora de supabase/migrations/ de
-- propósito (ver infra/supabase/clubs/README.md).
--
-- Ordem:
--   1. aplicar supabase/migrations/ inteiro (canonical baseline) no projeto
--      Vila Nova — cria o schema, clubs fica vazia.
--   2. só então rodar ESTE arquivo — insere a 1 linha do Vila Nova.
--
-- UUID: uuidV5(CLUBS_UUID_NAMESPACE, 'goias-app:multiclub:club:3')
--   = 3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e
-- Registrado em tooling/multiclub/clubs_registry.json via
-- registerNewClub()/saveClubRegistry() (2026-09-29). O prefixo "goias-app:"
-- do canonicalClubKey é histórico e fica, senão o UUID mudaria.
--
-- order_prefix: DATA_GAP — NULL de propósito até a decisão de produto da
-- Loja do Vila Nova (F7). generate_store_order_number() cai no fallback
-- upper(left(slug,3)) = 'VIL' se chamada antes disso.

do $$
declare
  existing_id uuid;
begin
  select id into existing_id from public.clubs where slug = 'vilanova';
  if existing_id is not null and existing_id <> '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e'::uuid then
    raise exception 'clubs.slug vilanova já existe com id % (esperado 3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e) — conflito de identidade, PARE.', existing_id;
  end if;
end $$;

insert into public.clubs (id, slug, name, short_name, order_prefix)
values ('3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e', 'vilanova', 'Vila Nova Futebol Clube', 'Vila Nova', null)
on conflict (id) do nothing;
