-- ============================================================================
-- Seed de `public.people` — SOMENTE os 94 candidatos canônicos
-- classificados APPROVED em data_export/goias/player_reconciliation/
-- people_insert_plan.json (v3.1 da reconciliação de jogadores, ver
-- docs/multiclub/15_player_reconciliation_report.md). PROVISIONAL (99),
-- BLOCKED_AMBIGUOUS (83) e BLOCKED_INSUFFICIENT_IDENTITY (19) ficam de fora
-- de propósito — preservados nos JSONs pra enriquecimento futuro, nunca
-- forçados a virar pessoa só pra "fechar o banco".
--
-- GERADA por tooling/multiclub/generate_people_seed.mjs — NUNCA editar à
-- mão. Rodar o gerador de novo produz este arquivo byte-a-byte idêntico
-- (entrada determinística: people_insert_plan.json + people_registry.json).
--
-- IDs vêm EXATAMENTE de tooling/multiclub/people_registry.json — nunca
-- gen_random_uuid(), nunca recalculado aqui. Cada id já foi cross-validado
-- contra o registry antes deste arquivo ser escrito (ver o gerador).
--
-- Escopo deliberadamente mínimo — só identidade (id/canonical_name/
-- display_name), nada de clube/jogos/posição/período/estatística. Isso
-- pertence a player_club_spells/player_positions/player_club_stats,
-- migrations futuras ainda não criadas (ver docs/multiclub/
-- 16_live_data_architecture.md).
--
-- Idempotência: ON CONFLICT (id) DO NOTHING, de propósito — este é um seed
-- HISTÓRICO de identidade inicial. Uma correção de nome descoberta depois
-- (ex.: o caso Fabiano, pesquisado nesta mesma reconciliação) deve vir numa
-- migration EXPLÍCITA e posterior com UPDATE, nunca reaplicando este
-- arquivo por cima — DO NOTHING evita que rodar este seed de novo (por
-- engano, ou numa nova instância do banco já corrigida manualmente)
-- sobrescreva silenciosamente uma correção mais recente.
-- ============================================================================

insert into public.people (id, canonical_name, display_name)
values
  ('34d6fed1-6282-564a-bcb0-5be7d705760a', 'Danilo Cunha da Silva', 'Danilo'),
  ('c628f9d8-6719-5506-acbd-adfb683fcf9b', 'Danilo Gabriel de Andrade', 'Danilo'),
  ('a597dae2-6ca9-5588-b1e3-a3532dd36f0e', 'Nicolas Vichiatto da Silva', 'Nicolas'),
  ('28e672db-34c0-5505-b3fa-703cbd422879', 'Nicolas Godinho Johann', 'Nicolas'),
  ('13c239d9-de5a-51de-b9ce-b4c42aa88d57', 'Michael Richard Delgado de Oliveira', 'Michael'),
  ('79902fc2-167c-5af2-a303-8044dbc6cff5', 'Jackson Diego Ibraim Fagundes', 'Dieguinho'),
  ('48016516-27c1-5c06-a52a-9893bfc90cf2', 'Erik Nascimento de Lima', 'Erik'),
  ('063cc04f-afd9-516a-96d7-6f27bfb0c818', 'Fabiano Cézar Viegas', 'Fabiano'),
  ('e2507d62-8cb5-5152-af56-f67464196ac6', 'Tadeu Antônio Ferreira', 'Tadeu'),
  ('828c3bc8-7e25-55c3-8468-d3cec50cd2e5', 'Walter Henrique da Silva', 'Walter'),
  ('66cd616b-9b5d-56f9-879e-1b171a8a33d0', 'Ezequiel Alves de Oliveira Vieira', 'Ezequiel'),
  ('e590ad99-16d4-52a1-88fd-2fbb064444b6', 'Murillo Carvalho Victorio', 'Murillo Victorio'),
  ('0b374c05-3edd-5cbb-9ddf-71b1b37e79ba', 'Thiago Rodrigues de Oliveira Nogueira', 'Thiago Rodrigues'),
  ('91e2722f-6fce-535e-9bd9-d2420889b1af', 'Luis Fellipe Campos Doria', 'Luisão'),
  ('36ed37b5-02be-5117-91d6-a62d5236505f', 'Lucas Ribeiro dos Santos', 'Lucas Ribeiro'),
  ('83765e63-a9f9-584e-aef1-bf11c3324b5e', 'Luiz Felipe do Nascimento dos Santos', 'Luiz Felipe'),
  ('d30dc008-4189-58bf-9823-8e8ab93dd7e0', 'Ramon Menezes Roma', 'Ramon Menezes'),
  ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae', 'Murilo Camara Saquetti Chimelo Pereira', 'Murilo Câmara'),
  ('2bd4e578-4739-5f93-b5db-8ecf6ba44393', 'Rodrigo Alves Soares', 'Rodrigo Soares'),
  ('a7ba5544-1384-5830-94a6-632f1c9e8414', 'Marcos Vinicius da Silva Santos', 'Marcos Vinicius'),
  ('54e8cc38-7ac7-5927-b7a5-ca11a372a545', 'Djalma Antônio da Silva Filho', 'Djalma'),
  ('be72ef65-0fdc-5f2a-b09a-ff8da6a279fb', 'João Paulo Ferreira Lourenço', 'Lourenço'),
  ('ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f', 'Luiz Filipe da Rosa Machado', 'Filipe Machado'),
  ('747cb968-a339-586c-94cf-583a3e0c3296', 'Guilherme Baldória de Camargo', 'Baldória'),
  ('b9d994d7-3605-5e6e-89ca-7d223f87d14a', 'Adilson dos Anjos Oliveira', 'Juninho'),
  ('af92cda1-aeba-5f69-a354-2928d8677c6f', 'Lucas Rodrigues Moreira Costa', 'Lucas Rodrigues'),
  ('88a5f4a0-ed1a-5a0f-b2d9-0294157789dd', 'Geirton Marques Aires', 'Gegê'),
  ('d58d5ae2-85c7-5336-80b6-0f4c0ed0a24b', 'Lucas Rafael Araújo Lima', 'Lucas Lima'),
  ('75723744-c847-55e8-acf2-d8ee0d75c7a1', 'Brayann Brito Batista', 'Brayann'),
  ('4dd73b43-f2ac-536a-8b22-ab4f7c125c68', 'Wellington Soares da Silva', 'Wellington Rato'),
  ('879326ba-8353-5fc8-ab0f-c6ca4646a143', 'Pedro Junqueira de Oliveira', 'Pedrinho'),
  ('e277edea-70b1-5092-ad39-48be1a5297d6', 'Anselmo Ramon Alves Herculano', 'Anselmo Ramon'),
  ('6702c943-0b4e-5041-8cd4-76991b85633d', 'Carlos Eduardo Amaral Pereira de Castro', 'Cadu'),
  ('7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4', 'Luiz Felipe Clemente de Almeida', 'Felipe Clemente'),
  ('424f8724-6855-58d6-ad36-24e2d9bdd7f6', 'Jean Carlos Alves Ferreira', 'Jean Carlos'),
  ('140ba628-c222-53a5-8621-a774092a125b', 'Halerrandrio dos Santos Feitosa', 'Halerrandrio'),
  ('10f6579f-1bc4-5b2a-ab9f-0a1a262519a1', 'Esli Samuel García Cordero', 'Esli Garcia'),
  ('6bc585a3-1b56-58c3-8ba7-6f208151ae47', 'Carlos Eduardo de Sousa Leopoldino', 'Kadu Sousa'),
  ('491bf2d0-f640-5b03-9ab1-a1772095133d', 'Fernandão', 'Fernandão'),
  ('09c38bac-99ee-5173-98f6-cc0d59ecca9c', 'Josué', 'Josué'),
  ('7587fc6d-f810-5c41-b206-0a2ffe09a96d', 'Dudu Cearense', 'Dudu Cearense'),
  ('b5d66b3b-e755-5b44-8765-3f2da953a759', 'Rafael Tolói', 'Rafael Tolói'),
  ('16d026a7-49b3-5257-9daa-30601e3ef357', 'Rafael Moura', 'Rafael Moura'),
  ('50863ba2-ea68-5ebd-9a97-fe43f3882484', 'Araújo', 'Araújo'),
  ('a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25', 'Ernando', 'Ernando'),
  ('652b4be1-ed2b-5c0e-a384-4626b9bb5920', 'Iarley', 'Iarley'),
  ('493bde6b-e169-5649-9c23-e4a5e5f5f08e', 'Paulo Baier', 'Paulo Baier'),
  ('4b153bcc-657a-5007-8c20-48c04130a484', 'Ricardo Goulart', 'Ricardo Goulart'),
  ('81a433ef-5acf-51c1-a38d-742a42ae346e', 'Rodrigo Tabata', 'Rodrigo Tabata'),
  ('6e8b3d49-4926-5b66-b7f1-8481c2c7a701', 'Egídio', 'Egídio'),
  ('66e38ffb-89f6-5c33-8f67-d9016304b564', 'Harlei', 'Harlei'),
  ('7dcb9ad0-b573-5261-aa53-736c3c9b96aa', 'Dill', 'Dill'),
  ('6416b152-ed92-52fc-8f3f-6027800dddaa', 'Amaral', 'Amaral'),
  ('d8600945-4f69-5c47-a42d-662921fa9557', 'Artur', 'Artur'),
  ('d274fa09-a83e-5526-86cd-2caf8244a4d3', 'Bruno Melo', 'Bruno Melo'),
  ('12b59f80-07bb-584d-a7eb-976739c07c6c', 'Caio Vinícius', 'Caio Vinícius'),
  ('02a0df33-8a89-5b78-8011-00868b240029', 'Carlos Alberto', 'Carlos Alberto'),
  ('dbedb80d-a764-52a6-905f-ff01f9a3cdea', 'Dadá Belmonte', 'Dadá Belmonte'),
  ('68880467-49ea-5661-8f08-2a177a060558', 'David', 'David'),
  ('9a740e1a-b0c0-53c9-9adf-f675f0cba5ca', 'Diego Caito', 'Diego Caito'),
  ('9f51dcb7-51c8-5f95-8b11-fc17e327b1f3', 'Diego Gonçalves', 'Diego Gonçalves'),
  ('e23bec2f-5da1-5544-ae02-7e97b9136bb6', 'Douglas', 'Douglas'),
  ('cd2285a5-82d6-59a5-bb5b-88b88b1afa8d', 'Eduardo Sasha', 'Eduardo Sasha'),
  ('9548aabb-4559-55f4-9bff-bd3c8b1984b9', 'Élvis', 'Élvis'),
  ('9c4d1f1b-de75-5e63-8bda-ffab87d20969', 'Everton Morelli', 'Everton Morelli'),
  ('0da8b2fc-a261-554a-a35f-4ad3ef422112', 'Fellipe Bastos', 'Fellipe Bastos'),
  ('645725d2-4a9b-596e-bfae-7436af12ff59', 'Gonzalo Freitas', 'Gonzalo Freitas'),
  ('12aff9c4-2a6e-595a-a725-cf66adc7ba88', 'Jajá', 'Jajá'),
  ('c6483fa7-ac39-52c9-9bbd-01ede638ba97', 'Julián Palacios', 'Julián Palacios'),
  ('14bbaa8e-4309-56a6-9e1c-e387dcdbfde8', 'Lucas Halter', 'Lucas Halter'),
  ('6d1615fb-9bab-5a4f-851b-7c4b74f564c7', 'Lucas Lovat', 'Lucas Lovat'),
  ('bef7397d-fe4d-5d35-ac92-46c450198b3c', 'Maguinho', 'Maguinho'),
  ('5d1b418d-b0eb-59bf-a7c3-c622a1569e57', 'Marcelo Costa', 'Marcelo Costa'),
  ('d1caad47-b1a6-5d1f-b0e3-c7fad9a8212d', 'Matheus Peixoto', 'Matheus Peixoto'),
  ('2b370606-4dd7-585c-867d-0bf3b2fcd0de', 'Messias', 'Messias'),
  ('22588c95-9663-569a-9616-e2b1d7a0cb76', 'Otacílio Neto', 'Otacílio Neto'),
  ('6f6e77e6-237d-59bf-bf01-9f2710377af3', 'Rafael Lacerda', 'Rafael Lacerda'),
  ('e8b6e0ec-2a1a-52d5-b399-aee42c146690', 'Ramón', 'Ramón'),
  ('38149930-5985-56fe-9832-cd101ea3d501', 'Renan', 'Renan'),
  ('8a55a430-aff6-5611-8ae8-d21b6c6a06ee', 'Renan Oliveira', 'Renan Oliveira'),
  ('dfc91f87-d812-54c6-b759-fe3761000752', 'Rodrigo', 'Rodrigo'),
  ('77241a5f-1e7c-5a5e-be50-495dcf1438e4', 'Rodrigo Andrade', 'Rodrigo Andrade'),
  ('662105cf-1e18-5af3-a24d-e5afb7f37b6d', 'Sander', 'Sander'),
  ('67bdde7d-fad6-516d-9a0b-ff81a3f6c765', 'Thiago Mendes', 'Thiago Mendes'),
  ('5ee54a6c-45ec-50dd-bc29-d5d3ac29d2a9', 'Titi', 'Titi'),
  ('64af0c2c-ea56-5ea9-871d-59b6a4892570', 'Valmir Lucas', 'Valmir Lucas'),
  ('3083606c-a924-5f61-8477-1381c6bf2a7e', 'Vinícius', 'Vinícius'),
  ('9a4c2c66-0936-5921-8714-95714db79daa', 'Wellington Saci', 'Wellington Saci'),
  ('c652d7a2-e1cc-51cc-b349-cb1afa86e63b', 'Willean Lepo', 'Willean Lepo'),
  ('03fca98b-17cd-5484-838d-6690bb677f70', 'William Matheus', 'William Matheus'),
  ('3390bf06-81e1-55dc-ae35-70bd3306b0ef', 'Willian Oliveira', 'Willian Oliveira'),
  ('19122a64-36c5-55d2-b734-7f682c70b5aa', 'Zé Hugo', 'Zé Hugo'),
  ('d5256bb9-5c40-5354-87d0-38d304523039', 'Zé Ricardo', 'Zé Ricardo'),
  ('ceba53d4-f785-545e-9a60-603a126c33e2', 'Douglas Pereira dos Santos', 'Douglas Pereira dos Santos')
on conflict (id) do nothing;
