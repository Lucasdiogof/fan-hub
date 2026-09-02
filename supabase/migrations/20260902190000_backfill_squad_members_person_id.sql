-- ============================================================================
-- Etapa F4 — backfill de `squad_members.person_id` pras 31 linhas
-- RESOLVED (de 31 totais — 0 ficam NULL, nunca um palpite).
-- GERADA por tooling/multiclub/generate_squad_members_person_migration.mjs
-- a partir de tooling/multiclub/build_squad_members_person_mapping.mjs —
-- NUNCA editar à mão, NUNCA um `select ... where canonical_name ilike`,
-- sempre UUID literal já resolvido pelo mapping.
--
-- Endurecido com 3 PRÉ-condições e PÓS-condição — mesma disciplina de F1
-- (2 pré-condições) + F3 (a 3ª, adicionada na revisão daquela etapa,
-- aplicada aqui desde o início) — a migration FALHA (RAISE EXCEPTION,
-- rollback automático da transação inteira) se a realidade do banco não
-- bater EXATAMENTE com o que foi auditado:
--   PRÉ 1: squad_members tem exatamente 31 linhas.
--   PRÉ 2: cada um dos 31 ids esperados EXISTE na tabela antes do
--          backfill.
--   PRÉ 3: count(person_id IS NOT NULL) = 0 ANTES do backfill — a coluna
--          acabou de ser criada pela migration anterior, qualquer valor
--          pré-existente é inesperado, nunca sobrescrito silenciosamente.
--   PÓS:   cada uma das 31 linhas termina com o person_id EXATO
--          esperado (não só "não-nulo"); contagem de person_id NOT NULL =
--          31; contagem NULL = 0; contagem de person_id DISTINCT
--          (não-nulo) = 31 (nenhuma duplicata). FK de people(id) já é
--          garantida estruturalmente pela constraint da migration
--          anterior.
--
-- Idempotente por construção: cada UPDATE seta o MESMO literal toda vez
-- que rodar — reprocessar não muda o resultado, e a pós-condição continua
-- batendo.
-- ============================================================================

do $$
declare
  v_expected_total integer := 31;
  v_expected_resolved integer := 31;
  v_expected_null integer := 0;
  v_missing_before text;
  v_mismatched_after text;
  v_actual_total integer;
  v_actual_resolved integer;
  v_actual_null integer;
  v_actual_distinct integer;
  v_prefilled_before integer;
begin
  -- PRÉ 1: total de linhas bate com o auditado
  select count(*) into v_actual_total from public.squad_members;
  if v_actual_total != v_expected_total then
    raise exception 'squad_members tem % linhas, esperado % — auditoria desatualizada, backfill abortado', v_actual_total, v_expected_total;
  end if;

  -- PRÉ 2: cada um dos 31 ids esperados EXISTE antes do backfill
  -- (nunca resolver por name/full_name/ilike/alias — sempre este par
  -- literal (id, person_id) vindo do mapping).
  select string_agg(e.id, ', ') into v_missing_before
  from (
    values
    ('anselmo_ramon', 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid), -- Anselmo Ramon Alves Herculano
    ('baldoria', '747cb968-a339-586c-94cf-583a3e0c3296'::uuid), -- Guilherme Baldória de Camargo
    ('brayann', '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid), -- Brayann Brito Batista
    ('cadu', '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid), -- Carlos Eduardo Amaral Pereira de Castro
    ('danilo', '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid), -- Danilo Cunha da Silva
    ('djalma', '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid), -- Djalma Antônio da Silva Filho
    ('esli_garcia', '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid), -- Esli Samuel García Cordero
    ('ezequiel', '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid), -- Ezequiel Alves de Oliveira Vieira
    ('felipe_clemente', '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid), -- Luiz Felipe Clemente de Almeida
    ('filipe_machado', 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid), -- Luiz Filipe da Rosa Machado
    ('gege', '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid), -- Geirton Marques Aires
    ('halerrandrio', '140ba628-c222-53a5-8621-a774092a125b'::uuid), -- Halerrandrio dos Santos Feitosa
    ('jean_carlos', '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid), -- Jean Carlos Alves Ferreira
    ('juninho', 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid), -- Adilson dos Anjos Oliveira
    ('kadu_sousa', '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid), -- Carlos Eduardo de Sousa Leopoldino
    ('lourenco', 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid), -- João Paulo Ferreira Lourenço
    ('lucas_lima', 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid), -- Lucas Rafael Araújo Lima
    ('lucas_ribeiro', '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid), -- Lucas Ribeiro dos Santos
    ('lucas_rodrigues', 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid), -- Lucas Rodrigues Moreira Costa
    ('luisao', '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid), -- Luis Fellipe Campos Doria
    ('luiz_felipe', '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid), -- Luiz Felipe do Nascimento dos Santos
    ('marcos_vinicius', 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid), -- Marcos Vinicius da Silva Santos
    ('murillo_victorio', 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid), -- Murillo Carvalho Victorio
    ('murilo_camara', 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid), -- Murilo Camara Saquetti Chimelo Pereira
    ('nicolas', 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid), -- Nicolas Vichiatto da Silva
    ('pedrinho', '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid), -- Pedro Junqueira de Oliveira
    ('ramon_menezes', 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid), -- Ramon Menezes Roma
    ('rodrigo_soares', '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid), -- Rodrigo Alves Soares
    ('tadeu', 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid), -- Tadeu Antônio Ferreira
    ('thiago_rodrigues', '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid), -- Thiago Rodrigues de Oliveira Nogueira
    ('wellington_rato', '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid) -- Wellington Soares da Silva
  ) as e(id, person_id)
  left join public.squad_members sm on sm.id = e.id
  where sm.id is null;
  if v_missing_before is not null then
    raise exception 'squad_members.id esperado(s) ausente(s) ANTES do backfill: % — auditoria desatualizada, backfill abortado', v_missing_before;
  end if;

  -- PRÉ 3: person_id tem que estar 100% vazio ANTES do backfill.
  select count(*) into v_prefilled_before from public.squad_members where person_id is not null;
  if v_prefilled_before != 0 then
    raise exception 'squad_members.person_id já tem % linha(s) preenchida(s) ANTES do backfill — inesperado (a coluna acabou de ser criada), backfill abortado pra nunca sobrescrever silenciosamente', v_prefilled_before;
  end if;

  -- Backfill — UPDATE literal, um por linha RESOLVED, idempotente.
  update public.squad_members set person_id = 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid where id = 'anselmo_ramon'; -- Anselmo Ramon Alves Herculano
  update public.squad_members set person_id = '747cb968-a339-586c-94cf-583a3e0c3296'::uuid where id = 'baldoria'; -- Guilherme Baldória de Camargo
  update public.squad_members set person_id = '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid where id = 'brayann'; -- Brayann Brito Batista
  update public.squad_members set person_id = '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid where id = 'cadu'; -- Carlos Eduardo Amaral Pereira de Castro
  update public.squad_members set person_id = '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid where id = 'danilo'; -- Danilo Cunha da Silva
  update public.squad_members set person_id = '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid where id = 'djalma'; -- Djalma Antônio da Silva Filho
  update public.squad_members set person_id = '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid where id = 'esli_garcia'; -- Esli Samuel García Cordero
  update public.squad_members set person_id = '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid where id = 'ezequiel'; -- Ezequiel Alves de Oliveira Vieira
  update public.squad_members set person_id = '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid where id = 'felipe_clemente'; -- Luiz Felipe Clemente de Almeida
  update public.squad_members set person_id = 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid where id = 'filipe_machado'; -- Luiz Filipe da Rosa Machado
  update public.squad_members set person_id = '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid where id = 'gege'; -- Geirton Marques Aires
  update public.squad_members set person_id = '140ba628-c222-53a5-8621-a774092a125b'::uuid where id = 'halerrandrio'; -- Halerrandrio dos Santos Feitosa
  update public.squad_members set person_id = '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid where id = 'jean_carlos'; -- Jean Carlos Alves Ferreira
  update public.squad_members set person_id = 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid where id = 'juninho'; -- Adilson dos Anjos Oliveira
  update public.squad_members set person_id = '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid where id = 'kadu_sousa'; -- Carlos Eduardo de Sousa Leopoldino
  update public.squad_members set person_id = 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid where id = 'lourenco'; -- João Paulo Ferreira Lourenço
  update public.squad_members set person_id = 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid where id = 'lucas_lima'; -- Lucas Rafael Araújo Lima
  update public.squad_members set person_id = '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid where id = 'lucas_ribeiro'; -- Lucas Ribeiro dos Santos
  update public.squad_members set person_id = 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid where id = 'lucas_rodrigues'; -- Lucas Rodrigues Moreira Costa
  update public.squad_members set person_id = '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid where id = 'luisao'; -- Luis Fellipe Campos Doria
  update public.squad_members set person_id = '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid where id = 'luiz_felipe'; -- Luiz Felipe do Nascimento dos Santos
  update public.squad_members set person_id = 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid where id = 'marcos_vinicius'; -- Marcos Vinicius da Silva Santos
  update public.squad_members set person_id = 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid where id = 'murillo_victorio'; -- Murillo Carvalho Victorio
  update public.squad_members set person_id = 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid where id = 'murilo_camara'; -- Murilo Camara Saquetti Chimelo Pereira
  update public.squad_members set person_id = 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid where id = 'nicolas'; -- Nicolas Vichiatto da Silva
  update public.squad_members set person_id = '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid where id = 'pedrinho'; -- Pedro Junqueira de Oliveira
  update public.squad_members set person_id = 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid where id = 'ramon_menezes'; -- Ramon Menezes Roma
  update public.squad_members set person_id = '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid where id = 'rodrigo_soares'; -- Rodrigo Alves Soares
  update public.squad_members set person_id = 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid where id = 'tadeu'; -- Tadeu Antônio Ferreira
  update public.squad_members set person_id = '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid where id = 'thiago_rodrigues'; -- Thiago Rodrigues de Oliveira Nogueira
  update public.squad_members set person_id = '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid where id = 'wellington_rato'; -- Wellington Soares da Silva

  -- PÓS 1: cada linha esperada termina com o person_id EXATO esperado.
  select string_agg(e.id || ' esperado=' || e.person_id::text || ' obtido=' || coalesce(sm.person_id::text, 'NULL'), '; ')
  into v_mismatched_after
  from (
    values
    ('anselmo_ramon', 'e277edea-70b1-5092-ad39-48be1a5297d6'::uuid), -- Anselmo Ramon Alves Herculano
    ('baldoria', '747cb968-a339-586c-94cf-583a3e0c3296'::uuid), -- Guilherme Baldória de Camargo
    ('brayann', '75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid), -- Brayann Brito Batista
    ('cadu', '6702c943-0b4e-5041-8cd4-76991b85633d'::uuid), -- Carlos Eduardo Amaral Pereira de Castro
    ('danilo', '34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid), -- Danilo Cunha da Silva
    ('djalma', '54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid), -- Djalma Antônio da Silva Filho
    ('esli_garcia', '10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid), -- Esli Samuel García Cordero
    ('ezequiel', '66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid), -- Ezequiel Alves de Oliveira Vieira
    ('felipe_clemente', '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid), -- Luiz Felipe Clemente de Almeida
    ('filipe_machado', 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid), -- Luiz Filipe da Rosa Machado
    ('gege', '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid), -- Geirton Marques Aires
    ('halerrandrio', '140ba628-c222-53a5-8621-a774092a125b'::uuid), -- Halerrandrio dos Santos Feitosa
    ('jean_carlos', '424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid), -- Jean Carlos Alves Ferreira
    ('juninho', 'b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid), -- Adilson dos Anjos Oliveira
    ('kadu_sousa', '6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid), -- Carlos Eduardo de Sousa Leopoldino
    ('lourenco', 'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid), -- João Paulo Ferreira Lourenço
    ('lucas_lima', 'd58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid), -- Lucas Rafael Araújo Lima
    ('lucas_ribeiro', '36ed37b5-02be-5117-91d6-a62d5236505f'::uuid), -- Lucas Ribeiro dos Santos
    ('lucas_rodrigues', 'af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid), -- Lucas Rodrigues Moreira Costa
    ('luisao', '91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid), -- Luis Fellipe Campos Doria
    ('luiz_felipe', '83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid), -- Luiz Felipe do Nascimento dos Santos
    ('marcos_vinicius', 'a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid), -- Marcos Vinicius da Silva Santos
    ('murillo_victorio', 'e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid), -- Murillo Carvalho Victorio
    ('murilo_camara', 'a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid), -- Murilo Camara Saquetti Chimelo Pereira
    ('nicolas', 'a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid), -- Nicolas Vichiatto da Silva
    ('pedrinho', '879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid), -- Pedro Junqueira de Oliveira
    ('ramon_menezes', 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid), -- Ramon Menezes Roma
    ('rodrigo_soares', '2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid), -- Rodrigo Alves Soares
    ('tadeu', 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid), -- Tadeu Antônio Ferreira
    ('thiago_rodrigues', '0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid), -- Thiago Rodrigues de Oliveira Nogueira
    ('wellington_rato', '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid) -- Wellington Soares da Silva
  ) as e(id, person_id)
  join public.squad_members sm on sm.id = e.id
  where sm.person_id is distinct from e.person_id;
  if v_mismatched_after is not null then
    raise exception 'backfill não bateu EXATAMENTE com o mapping esperado: % — backfill abortado, nenhuma linha parcialmente aplicada persiste', v_mismatched_after;
  end if;

  -- PÓS 2: contagens agregadas.
  select
    count(*) filter (where person_id is not null),
    count(*) filter (where person_id is null),
    count(distinct person_id) filter (where person_id is not null)
  into v_actual_resolved, v_actual_null, v_actual_distinct
  from public.squad_members;

  if v_actual_resolved != v_expected_resolved then
    raise exception 'person_id NOT NULL = %, esperado % — backfill abortado', v_actual_resolved, v_expected_resolved;
  end if;
  if v_actual_null != v_expected_null then
    raise exception 'person_id NULL = %, esperado % — backfill abortado', v_actual_null, v_expected_null;
  end if;
  if v_actual_distinct != v_expected_resolved then
    raise exception 'person_id distintos (não-nulos) = %, esperado % — indica duplicata, backfill abortado', v_actual_distinct, v_expected_resolved;
  end if;

  raise notice 'Etapa F4 backfill validado: % total, % resolved, % null, % distinct person_id — tudo bate exatamente com o mapping auditado.', v_actual_total, v_actual_resolved, v_actual_null, v_actual_distinct;
end $$;
