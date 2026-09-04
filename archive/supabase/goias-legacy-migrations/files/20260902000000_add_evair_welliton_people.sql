-- ============================================================================
-- Migration ADITIVA de `public.people` — SÓ Evair Aparecido Paulino e
-- Welliton Soares de Morais, reclassificados de BLOCKED_AMBIGUOUS pra
-- APPROVED após validação externa (2026-09-02, overrides evair_reclassify/
-- welliton_reclassify em tooling/multiclub/player_reconciliation_overrides
-- .json). NÃO reescreve nem duplica 20260901010000_seed_goias_people.sql
-- (já aplicada em produção) — essa migration permanece intocada pra
-- sempre.
--
-- GERADA por tooling/multiclub/generate_additive_people_seed.mjs — NUNCA
-- editar à mão. ids vêm EXATAMENTE de people_registry.json (os MESMOS ids
-- que já existiam desde a v3.1, reaproveitados — nunca gerados de novo só
-- porque a classificação mudou de BLOCKED pra APPROVED).
--
-- Idempotência: ON CONFLICT (id) DO NOTHING, mesmo padrão do seed original.
-- ============================================================================

insert into public.people (id, canonical_name, display_name)
values
  ('6b36f211-ed18-50fb-8cfc-77f8430f1616', 'Evair Aparecido Paulino', 'Evair'),
  ('a6577244-2373-5e79-b65c-b9200cb2a6e9', 'Welliton Soares de Morais', 'Welliton')
on conflict (id) do nothing;
