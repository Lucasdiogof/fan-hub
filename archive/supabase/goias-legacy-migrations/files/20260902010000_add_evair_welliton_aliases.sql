-- ============================================================================
-- Migration ADITIVA de `public.person_aliases` + `public.person_alias_sources`
-- — SÓ os aliases de Evair Aparecido Paulino e Welliton Soares de Morais,
-- que agora existem em `public.people` (ver
-- 20260902000000_add_evair_welliton_people.sql, aplicar ANTES desta). NÃO
-- reescreve 20260901030000_seed_goias_person_aliases.sql (já aplicada).
--
-- GERADA por tooling/multiclub/generate_additive_person_aliases_seed.mjs —
-- NUNCA editar à mão. Mesma infraestrutura de person_aliases_seed.json/
-- person_alias_sources_seed.json usada no seed original — só filtrada pro
-- delta de 2 pessoas.
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas, mesmo padrão.
-- person_alias_id resolvido por JOIN em (person_id, normalized_alias),
-- nunca um UUID pré-computado — mesma estratégia "Opção B" do seed
-- original.
-- ============================================================================

insert into public.person_aliases (person_id, alias, normalized_alias, alias_type, is_preferred)
values
  ('6b36f211-ed18-50fb-8cfc-77f8430f1616', 'Evair', 'evair', 'DISPLAY_NAME', true),
  ('6b36f211-ed18-50fb-8cfc-77f8430f1616', 'Evair Aparecido Paulino', 'evair aparecido paulino', 'LEGAL_NAME', false),
  ('a6577244-2373-5e79-b65c-b9200cb2a6e9', 'Welliton', 'welliton', 'DISPLAY_NAME', true),
  ('a6577244-2373-5e79-b65c-b9200cb2a6e9', 'Welliton Soares de Morais', 'welliton soares de morais', 'LEGAL_NAME', false)
on conflict (person_id, normalized_alias) do nothing;

insert into public.person_alias_sources (person_alias_id, source, source_record_key)
select pa.id, v.source, v.source_record_key
from (
  values
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'evair aparecido paulino', 'career_players', 'career_players:evair'),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'evair', 'career_players', 'career_players:evair'),
    ('6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, 'evair', 'guess_players', 'guess_players:evair'),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'welliton soares de morais', 'career_players', 'career_players:welliton'),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'welliton', 'career_players', 'career_players:welliton'),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'welliton', 'guess_players', 'guess_players:welliton_identity_review'),
    ('a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, 'welliton', 'lineup_matches', 'lineup_matches:welliton')
) as v(person_id, normalized_alias, source, source_record_key)
join public.person_aliases pa
  on pa.person_id = v.person_id and pa.normalized_alias = v.normalized_alias
on conflict (person_alias_id, source, source_record_key) do nothing;
