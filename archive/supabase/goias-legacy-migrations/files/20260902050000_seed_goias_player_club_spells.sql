-- ============================================================================
-- Seed de `public.player_club_spells` + `public.player_club_spell_sources`
-- — SOMENTE Goiás, SOMENTE pessoas já em `public.people` (96 APPROVED,
-- incluindo Evair/Welliton — ver 20260902000000_add_evair_welliton_people.
-- sql), SOMENTE onde existe evidência estruturada suficiente. NÃO cobre os
-- 96 inteiros de propósito — ver player_club_spells_seed_stats.json pra
-- pessoas bloqueadas.
--
-- GERADA por tooling/multiclub/generate_player_club_spells_seed.mjs a
-- partir de tooling/multiclub/build_player_club_spells_seed.mjs — NUNCA
-- editar à mão.
--
-- spell = período CONTÍNUO de vínculo, não contrato individual — uma
-- mudança empréstimo->compra dentro da MESMA passagem NÃO cria um 2º
-- spell (ver Tadeu, Luiz Felipe: mesclados; ver relationship_type em
-- player_club_spell_sources, não mais em player_club_spells).
--
-- id e club_id são literais pré-computados dos registries persistidos
-- (spells_registry.json / clubs_registry.json) — nunca gen_random_uuid().
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.player_club_spells (
  id, person_id, club_id, start_year, start_month, start_precision,
  end_year, end_month, end_precision, is_ongoing, spell_order, verification_status
)
values
  ('216eb0c4-c367-55fe-97a3-42944ffbd5db'::uuid, '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('5b3d8256-74e7-5109-84b6-857f31f8e7a0'::uuid, 'c628f9d8-6719-5506-acbd-adfb683fcf9b'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 1999, null, 'YEAR', 2003, null, 'YEAR', false, 1, 'VERIFIED'),
  ('872c706a-540f-5a90-94d6-c9e18282cfd3'::uuid, 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('7637529d-219b-5714-8c2b-a83b87e06395'::uuid, '28e672db-34c0-5505-b3fa-703cbd422879'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2021, null, 'YEAR', 2022, null, 'YEAR', false, 1, 'VERIFIED'),
  ('d8a7f134-ca1b-542a-8705-4fea3ff7a64c'::uuid, '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2017, null, 'YEAR', 2019, null, 'YEAR', false, 1, 'VERIFIED'),
  ('92087d74-dd21-5d16-81e0-53c391f636a5'::uuid, '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2013, null, 'YEAR', 2015, null, 'YEAR', false, 1, 'VERIFIED'),
  ('7288704d-9f7e-55f6-b7b0-e05e34a87cc8'::uuid, '063cc04f-afd9-516a-96d7-6f27bfb0c818'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2006, null, 'YEAR', 2007, null, 'YEAR', false, 1, 'VERIFIED'),
  ('9cd424a8-dd4a-54fb-8bf5-061d095dfbd1'::uuid, 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2019, 4, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('e206ba3e-a45f-5229-8abf-77ffde1d6ee0'::uuid, '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2012, null, 'YEAR', 2013, null, 'YEAR', false, 1, 'VERIFIED'),
  ('5c254545-4e51-55af-b312-01f3c7d64250'::uuid, '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2016, null, 'YEAR', 2017, null, 'YEAR', false, 2, 'VERIFIED'),
  ('40354072-1a71-50a3-867c-7a96c7af4f18'::uuid, '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2019, null, 'YEAR', 2019, null, 'YEAR', false, 3, 'VERIFIED'),
  ('e34ef702-b7df-570f-a08d-9f00e2b5904d'::uuid, '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2000, null, 'YEAR', 2000, null, 'YEAR', false, 1, 'VERIFIED'),
  ('4a768f8b-78c5-5a17-8750-6adc50aeb9af'::uuid, '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2002, null, 'YEAR', 2002, null, 'YEAR', false, 2, 'VERIFIED'),
  ('81e06be3-b0eb-5f57-be88-33ff1c108854'::uuid, 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2005, null, 'YEAR', 2007, null, 'YEAR', false, 1, 'VERIFIED'),
  ('8b0aa269-c377-52be-bb29-95a0dc69658d'::uuid, 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2021, null, 'YEAR', 2021, null, 'YEAR', false, 2, 'VERIFIED'),
  ('3c64f07b-ae90-5869-a293-ed206d2dbfe4'::uuid, '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2023, 1, 'MONTH', null, null, null, true, 1, 'PARTIAL'),
  ('646cfe81-274a-539d-941e-c19919eaf629'::uuid, 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 6, 'MONTH', null, null, null, true, 1, 'PARTIAL'),
  ('ba8a521d-63e6-5c35-a4c9-5b7746515f64'::uuid, '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2024, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('7153d35c-3268-5d44-b119-230c51e0e18e'::uuid, '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('bf319add-f86d-5e63-a2a4-2e3113617f08'::uuid, '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2024, 4, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('43d3d136-b00e-5393-a108-82adeef94fce'::uuid, '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 1, 'MONTH', 2025, 11, 'MONTH', false, 1, 'VERIFIED'),
  ('69dd430f-2090-562f-bcc4-bdcfb19e6ae2'::uuid, '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', null, null, null, true, 2, 'VERIFIED'),
  ('51689444-28a6-557f-a5d9-02fb4b697aaa'::uuid, 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 3, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('cc08f610-8dc7-5e5a-b4e4-f5059f3763f6'::uuid, 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 2, 'MONTH', 2025, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('abf80090-af12-521a-b764-70c0d43058ff'::uuid, 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 3, 'MONTH', null, null, null, true, 2, 'VERIFIED'),
  ('0b6e0953-6ab4-5506-b755-2babf62ae07b'::uuid, '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('1c73f52f-be80-5369-b45d-d503a5ffcdb3'::uuid, 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 8, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('7bac9de5-aa85-595d-895a-379320402ef8'::uuid, '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('c3b0a45f-123b-5128-ac3e-49de8d1b81b1'::uuid, 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('2bf5083c-3406-5cc0-a52f-62f7204ac01e'::uuid, 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', 2026, 11, 'MONTH', false, 1, 'VERIFIED'),
  ('07905744-e471-5ac8-af46-dfb7e85cf5fa'::uuid, '747cb968-a339-586c-94cf-583a3e0c3296'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 2, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('f010a3b0-f789-56ba-ae20-c07b80fc26fa'::uuid, 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('47cd1ba0-d985-5c8e-96ab-bc03eb28e727'::uuid, 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 2, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('34671275-a21f-5850-b5c3-6b6a7fb682c2'::uuid, '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('b88250ad-de6f-5093-8f36-7fc48890959a'::uuid, 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('d0e72877-85f4-5c97-93b9-a2c9a3c5242a'::uuid, '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 9, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('ea61834d-ecb4-5bfc-98f6-dd1b50fbca67'::uuid, '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 7, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('c1ea058d-af99-53a0-8244-2a61e0488dbb'::uuid, '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2022, 5, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('47b449ee-7e42-56a5-bda4-43cb46e54c26'::uuid, 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 4, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('9fb99be2-3301-57fc-8a90-c541fbe51271'::uuid, '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 2, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('7888b147-6881-56cd-8c19-8bd94bc2ea20'::uuid, '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2026, 8, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('b559ea9c-a5b6-57fe-ab94-82f664deb15b'::uuid, '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 2, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('37f995b4-aec0-5904-80a7-c9ba3d1ad313'::uuid, '140ba628-c222-53a5-8621-a774092a125b'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2023, 4, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('9b1c7d3b-b9c4-5e5f-948f-c234ee19ee56'::uuid, '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 1, 'MONTH', null, null, null, true, 1, 'VERIFIED'),
  ('17202656-70b9-502e-9766-e7bd7b593eee'::uuid, '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2025, 12, 'MONTH', 2026, 12, 'MONTH', false, 1, 'VERIFIED'),
  ('187f624d-8ee2-58e1-9478-3cf35a3a016b'::uuid, '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 1995, null, 'YEAR', 2001, null, 'YEAR', false, 1, 'VERIFIED'),
  ('a39018a0-2ac2-5392-a65d-ed5cfc402add'::uuid, '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2009, null, 'YEAR', 2010, null, 'YEAR', false, 2, 'VERIFIED'),
  ('899833d9-a663-5b45-80f6-5f7ad4f204a9'::uuid, '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 1997, null, 'YEAR', 2004, null, 'YEAR', false, 1, 'VERIFIED'),
  ('9f4e0422-fb5b-53b9-a589-eac66d4f8e60'::uuid, '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2012, null, 'YEAR', 2013, null, 'YEAR', false, 1, 'VERIFIED'),
  ('f7bd5cb2-8432-5028-a0b6-257292085479'::uuid, 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2008, null, 'YEAR', 2012, null, 'YEAR', false, 1, 'VERIFIED'),
  ('1fa876c4-6971-55f8-9816-15e4bf18258c'::uuid, '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2010, null, 'YEAR', 2010, null, 'YEAR', false, 1, 'VERIFIED'),
  ('d7e64579-3f6d-5bb4-b0d3-4e21fdba803d'::uuid, '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2019, null, 'YEAR', 2020, null, 'YEAR', false, 2, 'VERIFIED'),
  ('bae00dc6-80b1-5760-a28d-94c657412299'::uuid, '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 1997, null, 'YEAR', 2003, null, 'YEAR', false, 1, 'VERIFIED'),
  ('31006e1c-bc5b-5a4d-acdf-20607d5d728a'::uuid, '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2013, null, 'YEAR', 2014, null, 'YEAR', false, 2, 'VERIFIED'),
  ('d663da37-f3ca-51c7-9fbb-d9488134fbf2'::uuid, 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2006, null, 'YEAR', 2013, null, 'YEAR', false, 1, 'VERIFIED'),
  ('8bc616d4-3a41-5b2d-a0de-ba76bcd69337'::uuid, '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2008, null, 'YEAR', 2009, null, 'YEAR', false, 1, 'VERIFIED'),
  ('7d03b11e-810c-5924-ae4e-e519a2b7af8b'::uuid, '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2011, null, 'YEAR', 2012, null, 'YEAR', false, 2, 'VERIFIED'),
  ('57afb6fd-32fa-50c7-aa76-2fb6dab53182'::uuid, '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2004, null, 'YEAR', 2005, null, 'YEAR', false, 1, 'VERIFIED'),
  ('16e0a37d-a122-5080-9be4-de38b8b73227'::uuid, '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2007, null, 'YEAR', 2008, null, 'YEAR', false, 2, 'VERIFIED'),
  ('e4e7e6d1-84bd-54f4-86ac-b79e3d3f4334'::uuid, '4b153bcc-657a-5007-8c20-48c04130a484'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2012, null, 'YEAR', 2012, null, 'YEAR', false, 1, 'VERIFIED'),
  ('4337585b-5abf-560e-8115-05d263579128'::uuid, '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2004, null, 'YEAR', 2005, null, 'YEAR', false, 1, 'VERIFIED'),
  ('69d26115-b3d0-5c17-bf05-d69887b0faac'::uuid, '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 2012, null, 'YEAR', 2012, null, 'YEAR', false, 1, 'VERIFIED'),
  ('85c1c9be-0e83-579f-a7e5-a30a61105d54'::uuid, '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 1999, null, 'YEAR', 2014, null, 'YEAR', false, 1, 'VERIFIED'),
  ('2cce4563-18aa-58f4-8646-09c09c507812'::uuid, '7dcb9ad0-b573-5261-aa53-736c3c9b96aa'::uuid, '4c16340d-300c-5ab2-903f-17519db9b146'::uuid, 1994, null, 'YEAR', 2001, null, 'YEAR', false, 1, 'VERIFIED')
on conflict (id) do nothing;

insert into public.player_club_spell_sources (spell_id, source, source_record_key, evidence_type, relationship_type)
values
  ('216eb0c4-c367-55fe-97a3-42944ffbd5db'::uuid, 'squad_members', 'squad_members:danilo:club_history:0', 'PRIMARY', 'PERMANENT'),
  ('5b3d8256-74e7-5109-84b6-857f31f8e7a0'::uuid, 'career_players', 'career_players:danilo:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('872c706a-540f-5a90-94d6-c9e18282cfd3'::uuid, 'squad_members', 'squad_members:nicolas:club_history:8', 'PRIMARY', 'PERMANENT'),
  ('7637529d-219b-5714-8c2b-a83b87e06395'::uuid, 'override', 'override:nicolas_split:spell_model_implication:0', 'PRIMARY', 'UNKNOWN'),
  ('d8a7f134-ca1b-542a-8705-4fea3ff7a64c'::uuid, 'career_players', 'career_players:michael:club_career:3', 'PRIMARY', 'PERMANENT'),
  ('92087d74-dd21-5d16-81e0-53c391f636a5'::uuid, 'career_players', 'career_players:erik:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('7288704d-9f7e-55f6-b7b0-e05e34a87cc8'::uuid, 'override', 'override:fabiano_reclassify:spell_model_implication:0', 'PRIMARY', 'UNKNOWN'),
  ('9cd424a8-dd4a-54fb-8bf5-061d095dfbd1'::uuid, 'career_players', 'career_players:tadeu:club_career:7', 'PRIMARY', 'PERMANENT'),
  ('9cd424a8-dd4a-54fb-8bf5-061d095dfbd1'::uuid, 'squad_members', 'squad_members:tadeu:club_history:8', 'CORROBORATING', 'LOAN'),
  ('9cd424a8-dd4a-54fb-8bf5-061d095dfbd1'::uuid, 'squad_members', 'squad_members:tadeu:club_history:9', 'CORROBORATING', 'PERMANENT'),
  ('e206ba3e-a45f-5229-8abf-77ffde1d6ee0'::uuid, 'override', 'override:walter_annotation:spell_model_implication:0', 'PRIMARY', 'LOAN'),
  ('5c254545-4e51-55af-b312-01f3c7d64250'::uuid, 'override', 'override:walter_annotation:spell_model_implication:1', 'PRIMARY', 'LOAN'),
  ('40354072-1a71-50a3-867c-7a96c7af4f18'::uuid, 'override', 'override:walter_annotation:spell_model_implication:2', 'PRIMARY', 'PERMANENT'),
  ('e34ef702-b7df-570f-a08d-9f00e2b5904d'::uuid, 'career_players', 'career_players:evair:club_career:9', 'PRIMARY', 'PERMANENT'),
  ('4a768f8b-78c5-5a17-8750-6adc50aeb9af'::uuid, 'career_players', 'career_players:evair:club_career:11', 'PRIMARY', 'PERMANENT'),
  ('81e06be3-b0eb-5f57-be88-33ff1c108854'::uuid, 'career_players', 'career_players:welliton:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('8b0aa269-c377-52be-bb29-95a0dc69658d'::uuid, 'career_players', 'career_players:welliton:club_career:11', 'PRIMARY', 'PERMANENT'),
  ('3c64f07b-ae90-5869-a293-ed206d2dbfe4'::uuid, 'squad_members', 'squad_members:ezequiel:club_history:1', 'PRIMARY', 'PERMANENT'),
  ('646cfe81-274a-539d-941e-c19919eaf629'::uuid, 'squad_members', 'squad_members:murillo_victorio:club_history:0', 'PRIMARY', 'PERMANENT'),
  ('ba8a521d-63e6-5c35-a4c9-5b7746515f64'::uuid, 'squad_members', 'squad_members:thiago_rodrigues:club_history:10', 'PRIMARY', 'PERMANENT'),
  ('7153d35c-3268-5d44-b119-230c51e0e18e'::uuid, 'squad_members', 'squad_members:luisao:club_history:2', 'PRIMARY', 'LOAN'),
  ('bf319add-f86d-5e63-a2a4-2e3113617f08'::uuid, 'squad_members', 'squad_members:lucas_ribeiro:club_history:4', 'PRIMARY', 'PERMANENT'),
  ('43d3d136-b00e-5393-a108-82adeef94fce'::uuid, 'squad_members', 'squad_members:luiz_felipe:club_history:5', 'PRIMARY', 'LOAN'),
  ('69dd430f-2090-562f-bcc4-bdcfb19e6ae2'::uuid, 'squad_members', 'squad_members:luiz_felipe:club_history:6', 'PRIMARY', 'PERMANENT'),
  ('51689444-28a6-557f-a5d9-02fb4b697aaa'::uuid, 'squad_members', 'squad_members:ramon_menezes:club_history:9', 'PRIMARY', 'LOAN'),
  ('cc08f610-8dc7-5e5a-b4e4-f5059f3763f6'::uuid, 'squad_members', 'squad_members:murilo_camara:club_history:1', 'PRIMARY', 'PERMANENT'),
  ('abf80090-af12-521a-b764-70c0d43058ff'::uuid, 'squad_members', 'squad_members:murilo_camara:club_history:2', 'PRIMARY', 'PERMANENT'),
  ('0b6e0953-6ab4-5506-b755-2babf62ae07b'::uuid, 'squad_members', 'squad_members:rodrigo_soares:club_history:12', 'PRIMARY', 'PERMANENT'),
  ('1c73f52f-be80-5369-b45d-d503a5ffcdb3'::uuid, 'squad_members', 'squad_members:marcos_vinicius:club_history:15', 'PRIMARY', 'PERMANENT'),
  ('7bac9de5-aa85-595d-895a-379320402ef8'::uuid, 'squad_members', 'squad_members:djalma:club_history:12', 'PRIMARY', 'PERMANENT'),
  ('c3b0a45f-123b-5128-ac3e-49de8d1b81b1'::uuid, 'squad_members', 'squad_members:lourenco:club_history:6', 'PRIMARY', 'PERMANENT'),
  ('2bf5083c-3406-5cc0-a52f-62f7204ac01e'::uuid, 'squad_members', 'squad_members:filipe_machado:club_history:7', 'PRIMARY', 'LOAN'),
  ('07905744-e471-5ac8-af46-dfb7e85cf5fa'::uuid, 'squad_members', 'squad_members:baldoria:club_history:0', 'PRIMARY', 'PERMANENT'),
  ('f010a3b0-f789-56ba-ae20-c07b80fc26fa'::uuid, 'squad_members', 'squad_members:juninho:club_history:6', 'PRIMARY', 'PERMANENT'),
  ('47cd1ba0-d985-5c8e-96ab-bc03eb28e727'::uuid, 'squad_members', 'squad_members:lucas_rodrigues:club_history:0', 'PRIMARY', 'PERMANENT'),
  ('34671275-a21f-5850-b5c3-6b6a7fb682c2'::uuid, 'squad_members', 'squad_members:gege:club_history:11', 'PRIMARY', 'LOAN'),
  ('b88250ad-de6f-5093-8f36-7fc48890959a'::uuid, 'squad_members', 'squad_members:lucas_lima:club_history:9', 'PRIMARY', 'PERMANENT'),
  ('d0e72877-85f4-5c97-93b9-a2c9a3c5242a'::uuid, 'squad_members', 'squad_members:brayann:club_history:8', 'PRIMARY', 'PERMANENT'),
  ('ea61834d-ecb4-5bfc-98f6-dd1b50fbca67'::uuid, 'squad_members', 'squad_members:wellington_rato:club_history:12', 'PRIMARY', 'LOAN'),
  ('c1ea058d-af99-53a0-8244-2a61e0488dbb'::uuid, 'squad_members', 'squad_members:pedrinho:club_history:0', 'PRIMARY', 'PERMANENT'),
  ('47b449ee-7e42-56a5-bda4-43cb46e54c26'::uuid, 'squad_members', 'squad_members:anselmo_ramon:club_history:12', 'PRIMARY', 'PERMANENT'),
  ('9fb99be2-3301-57fc-8a90-c541fbe51271'::uuid, 'squad_members', 'squad_members:cadu:club_history:2', 'PRIMARY', 'LOAN'),
  ('7888b147-6881-56cd-8c19-8bd94bc2ea20'::uuid, 'squad_members', 'squad_members:felipe_clemente:club_history:16', 'PRIMARY', 'LOAN'),
  ('b559ea9c-a5b6-57fe-ab94-82f664deb15b'::uuid, 'squad_members', 'squad_members:jean_carlos:club_history:1', 'PRIMARY', 'PERMANENT'),
  ('37f995b4-aec0-5904-80a7-c9ba3d1ad313'::uuid, 'squad_members', 'squad_members:halerrandrio:club_history:0', 'PRIMARY', 'PERMANENT'),
  ('9b1c7d3b-b9c4-5e5f-948f-c234ee19ee56'::uuid, 'squad_members', 'squad_members:esli_garcia:club_history:7', 'PRIMARY', 'PERMANENT'),
  ('17202656-70b9-502e-9766-e7bd7b593eee'::uuid, 'squad_members', 'squad_members:kadu_sousa:club_history:4', 'PRIMARY', 'LOAN'),
  ('187f624d-8ee2-58e1-9478-3cf35a3a016b'::uuid, 'career_players', 'career_players:fernandao:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('a39018a0-2ac2-5392-a65d-ed5cfc402add'::uuid, 'career_players', 'career_players:fernandao:club_career:5', 'PRIMARY', 'PERMANENT'),
  ('899833d9-a663-5b45-80f6-5f7ad4f204a9'::uuid, 'career_players', 'career_players:josue:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('9f4e0422-fb5b-53b9-a589-eac66d4f8e60'::uuid, 'career_players', 'career_players:dudu_cearense:club_career:6', 'PRIMARY', 'PERMANENT'),
  ('f7bd5cb2-8432-5028-a0b6-257292085479'::uuid, 'career_players', 'career_players:rafael_toloi:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('1fa876c4-6971-55f8-9816-15e4bf18258c'::uuid, 'career_players', 'career_players:rafael_moura:club_career:7', 'PRIMARY', 'PERMANENT'),
  ('d7e64579-3f6d-5bb4-b0d3-4e21fdba803d'::uuid, 'career_players', 'career_players:rafael_moura:club_career:13', 'PRIMARY', 'PERMANENT'),
  ('bae00dc6-80b1-5760-a28d-94c657412299'::uuid, 'career_players', 'career_players:araujo:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('31006e1c-bc5b-5a4d-acdf-20607d5d728a'::uuid, 'career_players', 'career_players:araujo:club_career:8', 'PRIMARY', 'PERMANENT'),
  ('d663da37-f3ca-51c7-9fbb-d9488134fbf2'::uuid, 'career_players', 'career_players:ernando:club_career:0', 'PRIMARY', 'PERMANENT'),
  ('8bc616d4-3a41-5b2d-a0de-ba76bcd69337'::uuid, 'career_players', 'career_players:iarley:club_career:11', 'PRIMARY', 'PERMANENT'),
  ('7d03b11e-810c-5924-ae4e-e519a2b7af8b'::uuid, 'career_players', 'career_players:iarley:club_career:14', 'PRIMARY', 'PERMANENT'),
  ('57afb6fd-32fa-50c7-aa76-2fb6dab53182'::uuid, 'career_players', 'career_players:paulo_baier:club_career:11', 'PRIMARY', 'PERMANENT'),
  ('16e0a37d-a122-5080-9be4-de38b8b73227'::uuid, 'career_players', 'career_players:paulo_baier:club_career:13', 'PRIMARY', 'PERMANENT'),
  ('e4e7e6d1-84bd-54f4-86ac-b79e3d3f4334'::uuid, 'career_players', 'career_players:ricardo_goulart:club_career:2', 'PRIMARY', 'PERMANENT'),
  ('4337585b-5abf-560e-8115-05d263579128'::uuid, 'career_players', 'career_players:rodrigo_tabata:club_career:11', 'PRIMARY', 'PERMANENT'),
  ('69d26115-b3d0-5c17-bf05-d69887b0faac'::uuid, 'career_players', 'career_players:egidio:club_career:9', 'PRIMARY', 'LOAN'),
  ('85c1c9be-0e83-579f-a7e5-a30a61105d54'::uuid, 'career_players', 'career_players:harlei:club_career:3', 'PRIMARY', 'PERMANENT'),
  ('2cce4563-18aa-58f4-8646-09c09c507812'::uuid, 'career_players', 'career_players:dill:club_career:0', 'PRIMARY', 'PERMANENT')
on conflict (spell_id, source, source_record_key) do nothing;
