-- Bootstrap de identidade — Goiás Esporte Clube.
-- NÃO aplicado ainda (nenhum db push rodado). Standalone, fora de
-- supabase/migrations/ e de infra/supabase/canonical/supabase/migrations/
-- de propósito (ver infra/supabase/clubs/README.md).
--
-- Só existe pra registro/paridade — o Goiás JÁ tem esta linha aplicada de
-- verdade no projeto real (yonozsdgyrhgqrvydbnr), via
-- supabase/migrations/20260902030000_seed_clubs.sql (histórico, intocado).
-- Este arquivo NUNCA deve ser rodado contra o projeto do Goiás — existiria
-- só se um dia um projeto Goiás precisasse ser reconstruído do zero a
-- partir do canonical baseline (cenário hipotético da Fase 2, não agora).
--
-- UUID: uuidV5(CLUBS_UUID_NAMESPACE, 'goias-app:multiclub:club:1')
--   = 4c16340d-300c-5ab2-903f-17519db9b146
-- (idêntico ao já registrado em tooling/multiclub/clubs_registry.json e ao
-- valor real ao vivo — provado em docs/multiclub/49 e 50.)
--
-- order_prefix: 'GOI' — é o mapping documentado pro futuro cutover (Fase 2)
-- do prefixo hoje hardcoded na live schema do Goiás (GOI- em
-- generate_store_order_number, ver docs/multiclub/53). A live schema do
-- Goiás NÃO tem a coluna clubs.order_prefix (0 DDL contra o Goiás nesta
-- rodada) — este valor só existe aqui, no bootstrap hipotético contra um
-- projeto construído a partir do canonical baseline.

do $$
declare
  existing_id uuid;
begin
  select id into existing_id from public.clubs where slug = 'goias';
  if existing_id is not null and existing_id <> '4c16340d-300c-5ab2-903f-17519db9b146'::uuid then
    raise exception 'clubs.slug goias já existe com id % (esperado 4c16340d-300c-5ab2-903f-17519db9b146) — conflito de identidade, PARE.', existing_id;
  end if;
end $$;

insert into public.clubs (id, slug, name, short_name, order_prefix)
values ('4c16340d-300c-5ab2-903f-17519db9b146', 'goias', 'Goiás Esporte Clube', 'Goiás', 'GOI')
on conflict (id) do nothing;
