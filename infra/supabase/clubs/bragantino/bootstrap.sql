-- Bootstrap de identidade — Red Bull Bragantino.
-- NÃO aplicado ainda (nenhum db push rodado). Standalone, fora de
-- supabase/migrations/ e de infra/supabase/canonical/supabase/migrations/
-- de propósito (ver infra/supabase/clubs/README.md).
--
-- Ordem pretendida (Fase 1, ainda não executada):
--   1. aplicar infra/supabase/canonical/supabase/migrations/ inteiro no
--      projeto Bragantino (yrgyzkaaudyzmsqwzecj) — cria o schema, clubs
--      fica vazia.
--   2. só então rodar ESTE arquivo — insere a 1 linha do Bragantino.
--
-- UUID: uuidV5(CLUBS_UUID_NAMESPACE, 'goias-app:multiclub:club:2')
--   = 51683d2a-ea1d-57c6-8014-996146f242e7
-- Canonizado em tooling/multiclub/clubs_registry.json nesta rodada (via
-- registerNewClub()/saveClubRegistry() reais — não é mais preview) — prova
-- de que o mesmo algoritmo/namespace do Goiás reproduz o UUID real do
-- Goiás está em docs/multiclub/49_m4_multi_supabase_canonical_workdir_revision.md.
-- O prefixo "goias-app:" no canonicalClubKey é histórico (pré-rebrand Fan
-- Hub) — mantido de propósito, trocar mudaria o UUID e quebraria a
-- determinística.
--
-- order_prefix: DATA_GAP — deixado NULL de propósito. Não existe ainda
-- nenhuma decisão de branding/produto sobre o prefixo de pedido de loja do
-- Bragantino (o Store é SCHEMA CAPABILITY genérica no canonical baseline,
-- mas hasStore=false hoje pro Bragantino — nenhum pedido real vai existir
-- até essa decisão de produto acontecer). generate_store_order_number()
-- cai no fallback upper(left(slug,3)) = 'BRA' se chamada antes de um valor
-- explícito ser definido — documentado, nunca hardcoded aqui.

do $$
declare
  existing_id uuid;
begin
  select id into existing_id from public.clubs where slug = 'bragantino';
  if existing_id is not null and existing_id <> '51683d2a-ea1d-57c6-8014-996146f242e7'::uuid then
    raise exception 'clubs.slug bragantino já existe com id % (esperado 51683d2a-ea1d-57c6-8014-996146f242e7) — conflito de identidade, PARE.', existing_id;
  end if;
end $$;

insert into public.clubs (id, slug, name, short_name, order_prefix)
values ('51683d2a-ea1d-57c6-8014-996146f242e7', 'bragantino', 'Red Bull Bragantino', 'Bragantino', null)
on conflict (id) do nothing;
