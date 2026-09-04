-- ============================================================================
-- Etapa F3 — backfill de `guess_players.person_id` pras 92 linhas
-- RESOLVED (de 173 totais — as outras 81 ficam NULL, nunca um
-- palpite). GERADA por tooling/multiclub/generate_guess_players_person_
-- migration.mjs a partir de tooling/multiclub/build_guess_players_person_
-- mapping.mjs — NUNCA editar à mão, NUNCA um `select ... where
-- canonical_name ilike`, sempre UUID literal já resolvido pelo mapping.
--
-- Endurecido com PRÉ e PÓS-condição — mesma disciplina da Etapa F1, mais
-- 1 precondição nova pedida na revisão desta etapa — a migration FALHA
-- (RAISE EXCEPTION, rollback automático da transação inteira) se a
-- realidade do banco não bater EXATAMENTE com o que foi auditado:
--   PRÉ 1: guess_players tem exatamente 173 linhas.
--   PRÉ 2: cada um dos 92 ids esperados EXISTE na tabela antes do
--          backfill.
--   PRÉ 3: count(person_id IS NOT NULL) = 0 ANTES do backfill — person_id
--          acabou de ser criado na migration anterior, então QUALQUER
--          valor pré-existente é inesperado (indicaria a migration
--          anterior já ter sido re-executada com dado diferente, ou
--          alguém tendo escrito na coluna fora deste pipeline) — nunca
--          sobrescrever silenciosamente, aborta.
--   PÓS:   cada uma das 92 linhas termina com o person_id
--          EXATO esperado (não só "não-nulo"); contagem de person_id NOT
--          NULL = 92; contagem NULL = 81; contagem de person_id
--          DISTINCT (não-nulo) = 92 (nenhuma duplicata). FK de
--          people(id) já é garantida estruturalmente pela constraint da
--          migration anterior.
--
-- Idempotente por construção: cada UPDATE seta o MESMO literal toda vez
-- que rodar — reprocessar não muda o resultado, e a pós-condição continua
-- batendo.
-- ============================================================================

do $$
declare
  v_expected_total integer := 173;
  v_expected_resolved integer := 92;
  v_expected_null integer := 81;
  v_missing_before text;
  v_mismatched_after text;
  v_actual_total integer;
  v_actual_resolved integer;
  v_actual_null integer;
  v_actual_distinct integer;
  v_prefilled_before integer;
begin
  -- PRÉ 1: total de linhas bate com o auditado
  select count(*) into v_actual_total from public.guess_players;
  if v_actual_total != v_expected_total then
    raise exception 'guess_players tem % linhas, esperado % — auditoria desatualizada, backfill abortado', v_actual_total, v_expected_total;
  end if;

  -- PRÉ 2: cada um dos 92 ids esperados EXISTE antes do backfill
  -- (nunca resolver por name/display_name/ilike/aliases — sempre este par
  -- literal (id, person_id) vindo do mapping).
  select string_agg(e.id, ', ') into v_missing_before
  from (
    values
    ('adilson_dos_anjos_oliveira', 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid), -- Adilson dos Anjos Oliveira
    ('amaral', '6416b152-ed92-52fc-8f3f-6027800dddaa'::uuid), -- Amaral
    ('anselmo_ramon_alves_herculano', 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid), -- Anselmo Ramon Alves Herculano
    ('araujo', '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid), -- Araújo
    ('artur', 'd8600945-4f69-5c47-a42d-662921fa9557'::uuid), -- Artur
    ('brayann_brito_batista', '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid), -- Brayann Brito Batista
    ('bruno_melo', 'd274fa09-a83e-5526-86cd-2caf8244a4d3'::uuid), -- Bruno Melo
    ('caio_vinicius', '12b59f80-07bb-584d-a7eb-976739c07c6c'::uuid), -- Caio Vinícius
    ('carlos_alberto', '02a0df33-8a89-5b78-8011-00868b240029'::uuid), -- Carlos Alberto
    ('carlos_eduardo_amaral_pereira_de_castro', '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid), -- Carlos Eduardo Amaral Pereira de Castro
    ('carlos_eduardo_de_sousa_leopoldino', '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid), -- Carlos Eduardo de Sousa Leopoldino
    ('dada_belmonte', 'dbedb80d-a764-52a6-905f-ff01f9a3cdea'::uuid), -- Dadá Belmonte
    ('danilo_cunha_da_silva', '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid), -- Danilo Cunha da Silva
    ('david', '68880467-49ea-5661-8f08-2a177a060558'::uuid), -- David
    ('diego_caito', '9a740e1a-b0c0-53c9-9adf-f675f0cba5ca'::uuid), -- Diego Caito
    ('diego_goncalves', '9f51dcb7-51c8-5f95-8b11-fc17e327b1f3'::uuid), -- Diego Gonçalves
    ('dieguinho', '79902fc2-167c-5af2-a303-8044dbc6cff5'::uuid), -- Jackson Diego Ibraim Fagundes
    ('djalma_antonio_da_silva_filho', '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid), -- Djalma Antônio da Silva Filho
    ('douglas', 'e23bec2f-5da1-5544-ae02-7e97b9136bb6'::uuid), -- Douglas
    ('dudu_cearense', '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid), -- Dudu Cearense
    ('eduardo_sasha', 'cd2285a5-82d6-59a5-bb5b-88b88b1afa8d'::uuid), -- Eduardo Sasha
    ('egidio', '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid), -- Egídio
    ('elvis', '9548aabb-4559-55f4-9bff-bd3c8b1984b9'::uuid), -- Élvis
    ('erik', '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid), -- Erik Nascimento de Lima
    ('ernando', 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid), -- Ernando
    ('esli_samuel_garcia_cordero', '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid), -- Esli Samuel García Cordero
    ('evair', '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid), -- Evair Aparecido Paulino
    ('everton_morelli', '9c4d1f1b-de75-5e63-8bda-ffab87d20969'::uuid), -- Everton Morelli
    ('ezequiel_alves_de_oliveira_vieira', '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid), -- Ezequiel Alves de Oliveira Vieira
    ('fabiano', '063cc04f-afd9-516a-96d7-6f27bfb0c818'::uuid), -- Fabiano Cézar Viegas
    ('fellipe_bastos', '0da8b2fc-a261-554a-a35f-4ad3ef422112'::uuid), -- Fellipe Bastos
    ('fernandao', '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid), -- Fernandão
    ('geirton_marques_aires', '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid), -- Geirton Marques Aires
    ('gonzalo_freitas', '645725d2-4a9b-596e-bfae-7436af12ff59'::uuid), -- Gonzalo Freitas
    ('guilherme_baldoria_de_camargo', '747cb968-a339-586c-94cf-583a3e0c3296'::uuid), -- Guilherme Baldória de Camargo
    ('halerrandrio_dos_santos_feitosa', '140ba628-c222-53a5-8621-a774092a125b'::uuid), -- Halerrandrio dos Santos Feitosa
    ('harlei', '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid), -- Harlei
    ('iarley', '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid), -- Iarley
    ('jaja', '12aff9c4-2a6e-595a-a725-cf66adc7ba88'::uuid), -- Jajá
    ('jean_carlos_alves_ferreira', '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid), -- Jean Carlos Alves Ferreira
    ('joao_paulo_ferreira_lourenco', 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid), -- João Paulo Ferreira Lourenço
    ('josue', '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid), -- Josué
    ('julian_palacios', 'c6483fa7-ac39-52c9-9bbd-01ede638ba97'::uuid), -- Julián Palacios
    ('lucas_halter', '14bbaa8e-4309-56a6-9e1c-e387dcdbfde8'::uuid), -- Lucas Halter
    ('lucas_lovat', '6d1615fb-9bab-5a4f-851b-7c4b74f564c7'::uuid), -- Lucas Lovat
    ('lucas_rafael_araujo_lima', 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid), -- Lucas Rafael Araújo Lima
    ('lucas_ribeiro_dos_santos', '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid), -- Lucas Ribeiro dos Santos
    ('lucas_rodrigues_moreira_costa', 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid), -- Lucas Rodrigues Moreira Costa
    ('luis_fellipe_campos_doria', '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid), -- Luis Fellipe Campos Doria
    ('luiz_felipe_clemente_de_almeida', '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid), -- Luiz Felipe Clemente de Almeida
    ('luiz_felipe_do_nascimento_dos_santos', '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid), -- Luiz Felipe do Nascimento dos Santos
    ('luiz_filipe_da_rosa_machado', 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid), -- Luiz Filipe da Rosa Machado
    ('maguinho', 'bef7397d-fe4d-5d35-ac92-46c450198b3c'::uuid), -- Maguinho
    ('marcelo_costa', '5d1b418d-b0eb-59bf-a7c3-c622a1569e57'::uuid), -- Marcelo Costa
    ('marcos_vinicius_da_silva_santos', 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid), -- Marcos Vinicius da Silva Santos
    ('matheus_peixoto', 'd1caad47-b1a6-5d1f-b0e3-c7fad9a8212d'::uuid), -- Matheus Peixoto
    ('messias', '2b370606-4dd7-585c-867d-0bf3b2fcd0de'::uuid), -- Messias
    ('michael', '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid), -- Michael Richard Delgado de Oliveira
    ('murillo_carvalho_victorio', 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid), -- Murillo Carvalho Victorio
    ('murilo_camara_saquetti_chimelo_pereira', 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid), -- Murilo Camara Saquetti Chimelo Pereira
    ('nicolas_vichiatto_da_silva', 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid), -- Nicolas Vichiatto da Silva
    ('otacilio_neto', '22588c95-9663-569a-9616-e2b1d7a0cb76'::uuid), -- Otacílio Neto
    ('paulo_baier', '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid), -- Paulo Baier
    ('pedro_junqueira_de_oliveira', '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid), -- Pedro Junqueira de Oliveira
    ('rafael_lacerda', '6f6e77e6-237d-59bf-bf01-9f2710377af3'::uuid), -- Rafael Lacerda
    ('rafael_moura', '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid), -- Rafael Moura
    ('rafael_toloi', 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid), -- Rafael Tolói
    ('ramon', 'e8b6e0ec-2a1a-52d5-b399-aee42c146690'::uuid), -- Ramón
    ('ramon_menezes_roma', 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid), -- Ramon Menezes Roma
    ('renan', '38149930-5985-56fe-9832-cd101ea3d501'::uuid), -- Renan
    ('renan_oliveira', '8a55a430-aff6-5611-8ae8-d21b6c6a06ee'::uuid), -- Renan Oliveira
    ('ricardo_goulart', '4b153bcc-657a-5007-8c20-48c04130a484'::uuid), -- Ricardo Goulart
    ('rodrigo', 'dfc91f87-d812-54c6-b759-fe3761000752'::uuid), -- Rodrigo
    ('rodrigo_alves_soares', '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid), -- Rodrigo Alves Soares
    ('rodrigo_andrade', '77241a5f-1e7c-5a5e-be50-495dcf1438e4'::uuid), -- Rodrigo Andrade
    ('rodrigo_tabata', '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid), -- Rodrigo Tabata
    ('sander', '662105cf-1e18-5af3-a24d-e5afb7f37b6d'::uuid), -- Sander
    ('tadeu_antonio_ferreira', 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid), -- Tadeu Antônio Ferreira
    ('thiago_mendes', '67bdde7d-fad6-516d-9a0b-ff81a3f6c765'::uuid), -- Thiago Mendes
    ('thiago_rodrigues_de_oliveira_nogueira', '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid), -- Thiago Rodrigues de Oliveira Nogueira
    ('titi', '5ee54a6c-45ec-50dd-bc29-d5d3ac29d2a9'::uuid), -- Titi
    ('valmir_lucas', '64af0c2c-ea56-5ea9-871d-59b6a4892570'::uuid), -- Valmir Lucas
    ('vinicius', '3083606c-a924-5f61-8477-1381c6bf2a7e'::uuid), -- Vinícius
    ('walter', '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid), -- Walter Henrique da Silva
    ('wellington_saci', '9a4c2c66-0936-5921-8714-95714db79daa'::uuid), -- Wellington Saci
    ('wellington_soares_da_silva', '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid), -- Wellington Soares da Silva
    ('welliton_identity_review', 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid), -- Welliton Soares de Morais
    ('willean_lepo', 'c652d7a2-e1cc-51cc-b349-cb1afa86e63b'::uuid), -- Willean Lepo
    ('william_matheus', '03fca98b-17cd-5484-838d-6690bb677f70'::uuid), -- William Matheus
    ('willian_oliveira', '3390bf06-81e1-55dc-ae35-70bd3306b0ef'::uuid), -- Willian Oliveira
    ('ze_hugo', '19122a64-36c5-55d2-b734-7f682c70b5aa'::uuid), -- Zé Hugo
    ('ze_ricardo', 'd5256bb9-5c40-5354-87d0-38d304523039'::uuid) -- Zé Ricardo
  ) as e(id, person_id)
  left join public.guess_players gp on gp.id = e.id
  where gp.id is null;
  if v_missing_before is not null then
    raise exception 'guess_players.id esperado(s) ausente(s) ANTES do backfill: % — auditoria desatualizada, backfill abortado', v_missing_before;
  end if;

  -- PRÉ 3: person_id tem que estar 100% vazio ANTES do backfill — a
  -- coluna acabou de ser criada pela migration anterior, então qualquer
  -- valor não-nulo aqui é inesperado. Nunca sobrescrever silenciosamente.
  select count(*) into v_prefilled_before from public.guess_players where person_id is not null;
  if v_prefilled_before != 0 then
    raise exception 'guess_players.person_id já tem % linha(s) preenchida(s) ANTES do backfill — inesperado (a coluna acabou de ser criada), backfill abortado pra nunca sobrescrever silenciosamente', v_prefilled_before;
  end if;

  -- Backfill — UPDATE literal, um por linha RESOLVED, idempotente.
  update public.guess_players set person_id = 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid where id = 'adilson_dos_anjos_oliveira'; -- Adilson dos Anjos Oliveira
  update public.guess_players set person_id = '6416b152-ed92-52fc-8f3f-6027800dddaa'::uuid where id = 'amaral'; -- Amaral
  update public.guess_players set person_id = 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid where id = 'anselmo_ramon_alves_herculano'; -- Anselmo Ramon Alves Herculano
  update public.guess_players set person_id = '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid where id = 'araujo'; -- Araújo
  update public.guess_players set person_id = 'd8600945-4f69-5c47-a42d-662921fa9557'::uuid where id = 'artur'; -- Artur
  update public.guess_players set person_id = '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid where id = 'brayann_brito_batista'; -- Brayann Brito Batista
  update public.guess_players set person_id = 'd274fa09-a83e-5526-86cd-2caf8244a4d3'::uuid where id = 'bruno_melo'; -- Bruno Melo
  update public.guess_players set person_id = '12b59f80-07bb-584d-a7eb-976739c07c6c'::uuid where id = 'caio_vinicius'; -- Caio Vinícius
  update public.guess_players set person_id = '02a0df33-8a89-5b78-8011-00868b240029'::uuid where id = 'carlos_alberto'; -- Carlos Alberto
  update public.guess_players set person_id = '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid where id = 'carlos_eduardo_amaral_pereira_de_castro'; -- Carlos Eduardo Amaral Pereira de Castro
  update public.guess_players set person_id = '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid where id = 'carlos_eduardo_de_sousa_leopoldino'; -- Carlos Eduardo de Sousa Leopoldino
  update public.guess_players set person_id = 'dbedb80d-a764-52a6-905f-ff01f9a3cdea'::uuid where id = 'dada_belmonte'; -- Dadá Belmonte
  update public.guess_players set person_id = '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid where id = 'danilo_cunha_da_silva'; -- Danilo Cunha da Silva
  update public.guess_players set person_id = '68880467-49ea-5661-8f08-2a177a060558'::uuid where id = 'david'; -- David
  update public.guess_players set person_id = '9a740e1a-b0c0-53c9-9adf-f675f0cba5ca'::uuid where id = 'diego_caito'; -- Diego Caito
  update public.guess_players set person_id = '9f51dcb7-51c8-5f95-8b11-fc17e327b1f3'::uuid where id = 'diego_goncalves'; -- Diego Gonçalves
  update public.guess_players set person_id = '79902fc2-167c-5af2-a303-8044dbc6cff5'::uuid where id = 'dieguinho'; -- Jackson Diego Ibraim Fagundes
  update public.guess_players set person_id = '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid where id = 'djalma_antonio_da_silva_filho'; -- Djalma Antônio da Silva Filho
  update public.guess_players set person_id = 'e23bec2f-5da1-5544-ae02-7e97b9136bb6'::uuid where id = 'douglas'; -- Douglas
  update public.guess_players set person_id = '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid where id = 'dudu_cearense'; -- Dudu Cearense
  update public.guess_players set person_id = 'cd2285a5-82d6-59a5-bb5b-88b88b1afa8d'::uuid where id = 'eduardo_sasha'; -- Eduardo Sasha
  update public.guess_players set person_id = '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid where id = 'egidio'; -- Egídio
  update public.guess_players set person_id = '9548aabb-4559-55f4-9bff-bd3c8b1984b9'::uuid where id = 'elvis'; -- Élvis
  update public.guess_players set person_id = '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid where id = 'erik'; -- Erik Nascimento de Lima
  update public.guess_players set person_id = 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid where id = 'ernando'; -- Ernando
  update public.guess_players set person_id = '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid where id = 'esli_samuel_garcia_cordero'; -- Esli Samuel García Cordero
  update public.guess_players set person_id = '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid where id = 'evair'; -- Evair Aparecido Paulino
  update public.guess_players set person_id = '9c4d1f1b-de75-5e63-8bda-ffab87d20969'::uuid where id = 'everton_morelli'; -- Everton Morelli
  update public.guess_players set person_id = '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid where id = 'ezequiel_alves_de_oliveira_vieira'; -- Ezequiel Alves de Oliveira Vieira
  update public.guess_players set person_id = '063cc04f-afd9-516a-96d7-6f27bfb0c818'::uuid where id = 'fabiano'; -- Fabiano Cézar Viegas
  update public.guess_players set person_id = '0da8b2fc-a261-554a-a35f-4ad3ef422112'::uuid where id = 'fellipe_bastos'; -- Fellipe Bastos
  update public.guess_players set person_id = '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid where id = 'fernandao'; -- Fernandão
  update public.guess_players set person_id = '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid where id = 'geirton_marques_aires'; -- Geirton Marques Aires
  update public.guess_players set person_id = '645725d2-4a9b-596e-bfae-7436af12ff59'::uuid where id = 'gonzalo_freitas'; -- Gonzalo Freitas
  update public.guess_players set person_id = '747cb968-a339-586c-94cf-583a3e0c3296'::uuid where id = 'guilherme_baldoria_de_camargo'; -- Guilherme Baldória de Camargo
  update public.guess_players set person_id = '140ba628-c222-53a5-8621-a774092a125b'::uuid where id = 'halerrandrio_dos_santos_feitosa'; -- Halerrandrio dos Santos Feitosa
  update public.guess_players set person_id = '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid where id = 'harlei'; -- Harlei
  update public.guess_players set person_id = '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid where id = 'iarley'; -- Iarley
  update public.guess_players set person_id = '12aff9c4-2a6e-595a-a725-cf66adc7ba88'::uuid where id = 'jaja'; -- Jajá
  update public.guess_players set person_id = '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid where id = 'jean_carlos_alves_ferreira'; -- Jean Carlos Alves Ferreira
  update public.guess_players set person_id = 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid where id = 'joao_paulo_ferreira_lourenco'; -- João Paulo Ferreira Lourenço
  update public.guess_players set person_id = '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid where id = 'josue'; -- Josué
  update public.guess_players set person_id = 'c6483fa7-ac39-52c9-9bbd-01ede638ba97'::uuid where id = 'julian_palacios'; -- Julián Palacios
  update public.guess_players set person_id = '14bbaa8e-4309-56a6-9e1c-e387dcdbfde8'::uuid where id = 'lucas_halter'; -- Lucas Halter
  update public.guess_players set person_id = '6d1615fb-9bab-5a4f-851b-7c4b74f564c7'::uuid where id = 'lucas_lovat'; -- Lucas Lovat
  update public.guess_players set person_id = 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid where id = 'lucas_rafael_araujo_lima'; -- Lucas Rafael Araújo Lima
  update public.guess_players set person_id = '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid where id = 'lucas_ribeiro_dos_santos'; -- Lucas Ribeiro dos Santos
  update public.guess_players set person_id = 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid where id = 'lucas_rodrigues_moreira_costa'; -- Lucas Rodrigues Moreira Costa
  update public.guess_players set person_id = '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid where id = 'luis_fellipe_campos_doria'; -- Luis Fellipe Campos Doria
  update public.guess_players set person_id = '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid where id = 'luiz_felipe_clemente_de_almeida'; -- Luiz Felipe Clemente de Almeida
  update public.guess_players set person_id = '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid where id = 'luiz_felipe_do_nascimento_dos_santos'; -- Luiz Felipe do Nascimento dos Santos
  update public.guess_players set person_id = 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid where id = 'luiz_filipe_da_rosa_machado'; -- Luiz Filipe da Rosa Machado
  update public.guess_players set person_id = 'bef7397d-fe4d-5d35-ac92-46c450198b3c'::uuid where id = 'maguinho'; -- Maguinho
  update public.guess_players set person_id = '5d1b418d-b0eb-59bf-a7c3-c622a1569e57'::uuid where id = 'marcelo_costa'; -- Marcelo Costa
  update public.guess_players set person_id = 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid where id = 'marcos_vinicius_da_silva_santos'; -- Marcos Vinicius da Silva Santos
  update public.guess_players set person_id = 'd1caad47-b1a6-5d1f-b0e3-c7fad9a8212d'::uuid where id = 'matheus_peixoto'; -- Matheus Peixoto
  update public.guess_players set person_id = '2b370606-4dd7-585c-867d-0bf3b2fcd0de'::uuid where id = 'messias'; -- Messias
  update public.guess_players set person_id = '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid where id = 'michael'; -- Michael Richard Delgado de Oliveira
  update public.guess_players set person_id = 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid where id = 'murillo_carvalho_victorio'; -- Murillo Carvalho Victorio
  update public.guess_players set person_id = 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid where id = 'murilo_camara_saquetti_chimelo_pereira'; -- Murilo Camara Saquetti Chimelo Pereira
  update public.guess_players set person_id = 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid where id = 'nicolas_vichiatto_da_silva'; -- Nicolas Vichiatto da Silva
  update public.guess_players set person_id = '22588c95-9663-569a-9616-e2b1d7a0cb76'::uuid where id = 'otacilio_neto'; -- Otacílio Neto
  update public.guess_players set person_id = '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid where id = 'paulo_baier'; -- Paulo Baier
  update public.guess_players set person_id = '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid where id = 'pedro_junqueira_de_oliveira'; -- Pedro Junqueira de Oliveira
  update public.guess_players set person_id = '6f6e77e6-237d-59bf-bf01-9f2710377af3'::uuid where id = 'rafael_lacerda'; -- Rafael Lacerda
  update public.guess_players set person_id = '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid where id = 'rafael_moura'; -- Rafael Moura
  update public.guess_players set person_id = 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid where id = 'rafael_toloi'; -- Rafael Tolói
  update public.guess_players set person_id = 'e8b6e0ec-2a1a-52d5-b399-aee42c146690'::uuid where id = 'ramon'; -- Ramón
  update public.guess_players set person_id = 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid where id = 'ramon_menezes_roma'; -- Ramon Menezes Roma
  update public.guess_players set person_id = '38149930-5985-56fe-9832-cd101ea3d501'::uuid where id = 'renan'; -- Renan
  update public.guess_players set person_id = '8a55a430-aff6-5611-8ae8-d21b6c6a06ee'::uuid where id = 'renan_oliveira'; -- Renan Oliveira
  update public.guess_players set person_id = '4b153bcc-657a-5007-8c20-48c04130a484'::uuid where id = 'ricardo_goulart'; -- Ricardo Goulart
  update public.guess_players set person_id = 'dfc91f87-d812-54c6-b759-fe3761000752'::uuid where id = 'rodrigo'; -- Rodrigo
  update public.guess_players set person_id = '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid where id = 'rodrigo_alves_soares'; -- Rodrigo Alves Soares
  update public.guess_players set person_id = '77241a5f-1e7c-5a5e-be50-495dcf1438e4'::uuid where id = 'rodrigo_andrade'; -- Rodrigo Andrade
  update public.guess_players set person_id = '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid where id = 'rodrigo_tabata'; -- Rodrigo Tabata
  update public.guess_players set person_id = '662105cf-1e18-5af3-a24d-e5afb7f37b6d'::uuid where id = 'sander'; -- Sander
  update public.guess_players set person_id = 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid where id = 'tadeu_antonio_ferreira'; -- Tadeu Antônio Ferreira
  update public.guess_players set person_id = '67bdde7d-fad6-516d-9a0b-ff81a3f6c765'::uuid where id = 'thiago_mendes'; -- Thiago Mendes
  update public.guess_players set person_id = '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid where id = 'thiago_rodrigues_de_oliveira_nogueira'; -- Thiago Rodrigues de Oliveira Nogueira
  update public.guess_players set person_id = '5ee54a6c-45ec-50dd-bc29-d5d3ac29d2a9'::uuid where id = 'titi'; -- Titi
  update public.guess_players set person_id = '64af0c2c-ea56-5ea9-871d-59b6a4892570'::uuid where id = 'valmir_lucas'; -- Valmir Lucas
  update public.guess_players set person_id = '3083606c-a924-5f61-8477-1381c6bf2a7e'::uuid where id = 'vinicius'; -- Vinícius
  update public.guess_players set person_id = '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid where id = 'walter'; -- Walter Henrique da Silva
  update public.guess_players set person_id = '9a4c2c66-0936-5921-8714-95714db79daa'::uuid where id = 'wellington_saci'; -- Wellington Saci
  update public.guess_players set person_id = '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid where id = 'wellington_soares_da_silva'; -- Wellington Soares da Silva
  update public.guess_players set person_id = 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid where id = 'welliton_identity_review'; -- Welliton Soares de Morais
  update public.guess_players set person_id = 'c652d7a2-e1cc-51cc-b349-cb1afa86e63b'::uuid where id = 'willean_lepo'; -- Willean Lepo
  update public.guess_players set person_id = '03fca98b-17cd-5484-838d-6690bb677f70'::uuid where id = 'william_matheus'; -- William Matheus
  update public.guess_players set person_id = '3390bf06-81e1-55dc-ae35-70bd3306b0ef'::uuid where id = 'willian_oliveira'; -- Willian Oliveira
  update public.guess_players set person_id = '19122a64-36c5-55d2-b734-7f682c70b5aa'::uuid where id = 'ze_hugo'; -- Zé Hugo
  update public.guess_players set person_id = 'd5256bb9-5c40-5354-87d0-38d304523039'::uuid where id = 'ze_ricardo'; -- Zé Ricardo

  -- PÓS 1: cada linha esperada termina com o person_id EXATO esperado.
  select string_agg(e.id || ' esperado=' || e.person_id::text || ' obtido=' || coalesce(gp.person_id::text, 'NULL'), '; ')
  into v_mismatched_after
  from (
    values
    ('adilson_dos_anjos_oliveira', 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid), -- Adilson dos Anjos Oliveira
    ('amaral', '6416b152-ed92-52fc-8f3f-6027800dddaa'::uuid), -- Amaral
    ('anselmo_ramon_alves_herculano', 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid), -- Anselmo Ramon Alves Herculano
    ('araujo', '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid), -- Araújo
    ('artur', 'd8600945-4f69-5c47-a42d-662921fa9557'::uuid), -- Artur
    ('brayann_brito_batista', '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid), -- Brayann Brito Batista
    ('bruno_melo', 'd274fa09-a83e-5526-86cd-2caf8244a4d3'::uuid), -- Bruno Melo
    ('caio_vinicius', '12b59f80-07bb-584d-a7eb-976739c07c6c'::uuid), -- Caio Vinícius
    ('carlos_alberto', '02a0df33-8a89-5b78-8011-00868b240029'::uuid), -- Carlos Alberto
    ('carlos_eduardo_amaral_pereira_de_castro', '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid), -- Carlos Eduardo Amaral Pereira de Castro
    ('carlos_eduardo_de_sousa_leopoldino', '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid), -- Carlos Eduardo de Sousa Leopoldino
    ('dada_belmonte', 'dbedb80d-a764-52a6-905f-ff01f9a3cdea'::uuid), -- Dadá Belmonte
    ('danilo_cunha_da_silva', '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid), -- Danilo Cunha da Silva
    ('david', '68880467-49ea-5661-8f08-2a177a060558'::uuid), -- David
    ('diego_caito', '9a740e1a-b0c0-53c9-9adf-f675f0cba5ca'::uuid), -- Diego Caito
    ('diego_goncalves', '9f51dcb7-51c8-5f95-8b11-fc17e327b1f3'::uuid), -- Diego Gonçalves
    ('dieguinho', '79902fc2-167c-5af2-a303-8044dbc6cff5'::uuid), -- Jackson Diego Ibraim Fagundes
    ('djalma_antonio_da_silva_filho', '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid), -- Djalma Antônio da Silva Filho
    ('douglas', 'e23bec2f-5da1-5544-ae02-7e97b9136bb6'::uuid), -- Douglas
    ('dudu_cearense', '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid), -- Dudu Cearense
    ('eduardo_sasha', 'cd2285a5-82d6-59a5-bb5b-88b88b1afa8d'::uuid), -- Eduardo Sasha
    ('egidio', '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid), -- Egídio
    ('elvis', '9548aabb-4559-55f4-9bff-bd3c8b1984b9'::uuid), -- Élvis
    ('erik', '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid), -- Erik Nascimento de Lima
    ('ernando', 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid), -- Ernando
    ('esli_samuel_garcia_cordero', '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid), -- Esli Samuel García Cordero
    ('evair', '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid), -- Evair Aparecido Paulino
    ('everton_morelli', '9c4d1f1b-de75-5e63-8bda-ffab87d20969'::uuid), -- Everton Morelli
    ('ezequiel_alves_de_oliveira_vieira', '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid), -- Ezequiel Alves de Oliveira Vieira
    ('fabiano', '063cc04f-afd9-516a-96d7-6f27bfb0c818'::uuid), -- Fabiano Cézar Viegas
    ('fellipe_bastos', '0da8b2fc-a261-554a-a35f-4ad3ef422112'::uuid), -- Fellipe Bastos
    ('fernandao', '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid), -- Fernandão
    ('geirton_marques_aires', '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid), -- Geirton Marques Aires
    ('gonzalo_freitas', '645725d2-4a9b-596e-bfae-7436af12ff59'::uuid), -- Gonzalo Freitas
    ('guilherme_baldoria_de_camargo', '747cb968-a339-586c-94cf-583a3e0c3296'::uuid), -- Guilherme Baldória de Camargo
    ('halerrandrio_dos_santos_feitosa', '140ba628-c222-53a5-8621-a774092a125b'::uuid), -- Halerrandrio dos Santos Feitosa
    ('harlei', '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid), -- Harlei
    ('iarley', '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid), -- Iarley
    ('jaja', '12aff9c4-2a6e-595a-a725-cf66adc7ba88'::uuid), -- Jajá
    ('jean_carlos_alves_ferreira', '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid), -- Jean Carlos Alves Ferreira
    ('joao_paulo_ferreira_lourenco', 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid), -- João Paulo Ferreira Lourenço
    ('josue', '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid), -- Josué
    ('julian_palacios', 'c6483fa7-ac39-52c9-9bbd-01ede638ba97'::uuid), -- Julián Palacios
    ('lucas_halter', '14bbaa8e-4309-56a6-9e1c-e387dcdbfde8'::uuid), -- Lucas Halter
    ('lucas_lovat', '6d1615fb-9bab-5a4f-851b-7c4b74f564c7'::uuid), -- Lucas Lovat
    ('lucas_rafael_araujo_lima', 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid), -- Lucas Rafael Araújo Lima
    ('lucas_ribeiro_dos_santos', '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid), -- Lucas Ribeiro dos Santos
    ('lucas_rodrigues_moreira_costa', 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid), -- Lucas Rodrigues Moreira Costa
    ('luis_fellipe_campos_doria', '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid), -- Luis Fellipe Campos Doria
    ('luiz_felipe_clemente_de_almeida', '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid), -- Luiz Felipe Clemente de Almeida
    ('luiz_felipe_do_nascimento_dos_santos', '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid), -- Luiz Felipe do Nascimento dos Santos
    ('luiz_filipe_da_rosa_machado', 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid), -- Luiz Filipe da Rosa Machado
    ('maguinho', 'bef7397d-fe4d-5d35-ac92-46c450198b3c'::uuid), -- Maguinho
    ('marcelo_costa', '5d1b418d-b0eb-59bf-a7c3-c622a1569e57'::uuid), -- Marcelo Costa
    ('marcos_vinicius_da_silva_santos', 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid), -- Marcos Vinicius da Silva Santos
    ('matheus_peixoto', 'd1caad47-b1a6-5d1f-b0e3-c7fad9a8212d'::uuid), -- Matheus Peixoto
    ('messias', '2b370606-4dd7-585c-867d-0bf3b2fcd0de'::uuid), -- Messias
    ('michael', '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid), -- Michael Richard Delgado de Oliveira
    ('murillo_carvalho_victorio', 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid), -- Murillo Carvalho Victorio
    ('murilo_camara_saquetti_chimelo_pereira', 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid), -- Murilo Camara Saquetti Chimelo Pereira
    ('nicolas_vichiatto_da_silva', 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid), -- Nicolas Vichiatto da Silva
    ('otacilio_neto', '22588c95-9663-569a-9616-e2b1d7a0cb76'::uuid), -- Otacílio Neto
    ('paulo_baier', '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid), -- Paulo Baier
    ('pedro_junqueira_de_oliveira', '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid), -- Pedro Junqueira de Oliveira
    ('rafael_lacerda', '6f6e77e6-237d-59bf-bf01-9f2710377af3'::uuid), -- Rafael Lacerda
    ('rafael_moura', '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid), -- Rafael Moura
    ('rafael_toloi', 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid), -- Rafael Tolói
    ('ramon', 'e8b6e0ec-2a1a-52d5-b399-aee42c146690'::uuid), -- Ramón
    ('ramon_menezes_roma', 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid), -- Ramon Menezes Roma
    ('renan', '38149930-5985-56fe-9832-cd101ea3d501'::uuid), -- Renan
    ('renan_oliveira', '8a55a430-aff6-5611-8ae8-d21b6c6a06ee'::uuid), -- Renan Oliveira
    ('ricardo_goulart', '4b153bcc-657a-5007-8c20-48c04130a484'::uuid), -- Ricardo Goulart
    ('rodrigo', 'dfc91f87-d812-54c6-b759-fe3761000752'::uuid), -- Rodrigo
    ('rodrigo_alves_soares', '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid), -- Rodrigo Alves Soares
    ('rodrigo_andrade', '77241a5f-1e7c-5a5e-be50-495dcf1438e4'::uuid), -- Rodrigo Andrade
    ('rodrigo_tabata', '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid), -- Rodrigo Tabata
    ('sander', '662105cf-1e18-5af3-a24d-e5afb7f37b6d'::uuid), -- Sander
    ('tadeu_antonio_ferreira', 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid), -- Tadeu Antônio Ferreira
    ('thiago_mendes', '67bdde7d-fad6-516d-9a0b-ff81a3f6c765'::uuid), -- Thiago Mendes
    ('thiago_rodrigues_de_oliveira_nogueira', '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid), -- Thiago Rodrigues de Oliveira Nogueira
    ('titi', '5ee54a6c-45ec-50dd-bc29-d5d3ac29d2a9'::uuid), -- Titi
    ('valmir_lucas', '64af0c2c-ea56-5ea9-871d-59b6a4892570'::uuid), -- Valmir Lucas
    ('vinicius', '3083606c-a924-5f61-8477-1381c6bf2a7e'::uuid), -- Vinícius
    ('walter', '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid), -- Walter Henrique da Silva
    ('wellington_saci', '9a4c2c66-0936-5921-8714-95714db79daa'::uuid), -- Wellington Saci
    ('wellington_soares_da_silva', '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid), -- Wellington Soares da Silva
    ('welliton_identity_review', 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid), -- Welliton Soares de Morais
    ('willean_lepo', 'c652d7a2-e1cc-51cc-b349-cb1afa86e63b'::uuid), -- Willean Lepo
    ('william_matheus', '03fca98b-17cd-5484-838d-6690bb677f70'::uuid), -- William Matheus
    ('willian_oliveira', '3390bf06-81e1-55dc-ae35-70bd3306b0ef'::uuid), -- Willian Oliveira
    ('ze_hugo', '19122a64-36c5-55d2-b734-7f682c70b5aa'::uuid), -- Zé Hugo
    ('ze_ricardo', 'd5256bb9-5c40-5354-87d0-38d304523039'::uuid) -- Zé Ricardo
  ) as e(id, person_id)
  join public.guess_players gp on gp.id = e.id
  where gp.person_id is distinct from e.person_id;
  if v_mismatched_after is not null then
    raise exception 'backfill não bateu EXATAMENTE com o mapping esperado: % — backfill abortado, nenhuma linha parcialmente aplicada persiste', v_mismatched_after;
  end if;

  -- PÓS 2: contagens agregadas.
  select
    count(*) filter (where person_id is not null),
    count(*) filter (where person_id is null),
    count(distinct person_id) filter (where person_id is not null)
  into v_actual_resolved, v_actual_null, v_actual_distinct
  from public.guess_players;

  if v_actual_resolved != v_expected_resolved then
    raise exception 'person_id NOT NULL = %, esperado % — backfill abortado', v_actual_resolved, v_expected_resolved;
  end if;
  if v_actual_null != v_expected_null then
    raise exception 'person_id NULL = %, esperado % — backfill abortado', v_actual_null, v_expected_null;
  end if;
  if v_actual_distinct != v_expected_resolved then
    raise exception 'person_id distintos (não-nulos) = %, esperado % — indica duplicata, backfill abortado', v_actual_distinct, v_expected_resolved;
  end if;

  raise notice 'Etapa F3 backfill validado: % total, % resolved, % null, % distinct person_id — tudo bate exatamente com o mapping auditado.', v_actual_total, v_actual_resolved, v_actual_null, v_actual_distinct;
end $$;
