-- ============================================================================
-- Etapa F1 — backfill de `career_players.person_id` pras 21 linhas
-- RESOLVED (de 30 totais — as outras 9 ficam NULL, nunca um
-- palpite). GERADA por tooling/multiclub/generate_career_players_person_
-- migration.mjs a partir de tooling/multiclub/build_career_players_person_
-- mapping.mjs — NUNCA editar à mão, NUNCA um `select ... where
-- canonical_name ilike`, sempre UUID literal já resolvido pelo mapping.
--
-- Endurecido com PRÉ e PÓS-condição — a migration FALHA (RAISE EXCEPTION,
-- rollback automático da transação inteira) se a realidade do banco não
-- bater EXATAMENTE com o que foi auditado, em vez de aplicar 21 UPDATEs
-- silenciosos e confiar que "provavelmente casou tudo":
--   PRÉ:  career_players tem exatamente 30 linhas; cada um dos
--         21 ids esperados EXISTE na tabela antes do backfill.
--   PÓS:  cada uma das 21 linhas termina com o person_id
--         EXATO esperado (não só "não-nulo" — o valor literal certo);
--         contagem de person_id NOT NULL = 21; contagem NULL = 9;
--         contagem de person_id DISTINCT (não-nulo) = 21 (nenhuma
--         duplicata). FK de people(id) já é garantida estruturalmente pela
--         constraint da migration anterior — um person_id inexistente em
--         `people` já rejeitaria o UPDATE com 23503 antes de qualquer
--         checagem daqui.
--
-- Idempotente por construção: cada UPDATE seta o MESMO literal toda vez
-- que rodar — reprocessar não muda o resultado, e a pós-condição continua
-- batendo.
-- ============================================================================

do $$
declare
  v_expected_total integer := 30;
  v_expected_resolved integer := 21;
  v_expected_null integer := 9;
  v_missing_before text;
  v_mismatched_after text;
  v_actual_total integer;
  v_actual_resolved integer;
  v_actual_null integer;
  v_actual_distinct integer;
begin
  -- PRÉ 1: total de linhas bate com o auditado
  select count(*) into v_actual_total from public.career_players;
  if v_actual_total != v_expected_total then
    raise exception 'career_players tem % linhas, esperado % — auditoria desatualizada, backfill abortado', v_actual_total, v_expected_total;
  end if;

  -- PRÉ 2: cada um dos 21 ids esperados EXISTE antes do backfill
  -- (nunca resolver por canonical_name/answer/ilike/alias — sempre este
  -- par literal (id, person_id) vindo do mapping).
  select string_agg(e.id, ', ') into v_missing_before
  from (
    values
    ('araujo', '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid), -- Araújo
    ('danilo', 'c628f9d8-6719-5506-acbd-adfb683fcf9b'::uuid), -- Danilo Gabriel de Andrade
    ('dill', '7dcb9ad0-b573-5261-aa53-736c3c9b96aa'::uuid), -- Dill
    ('dudu_cearense', '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid), -- Dudu Cearense
    ('egidio', '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid), -- Egídio
    ('erik', '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid), -- Erik Nascimento de Lima
    ('ernando', 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid), -- Ernando
    ('evair', '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid), -- Evair Aparecido Paulino
    ('fernandao', '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid), -- Fernandão
    ('harlei', '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid), -- Harlei
    ('iarley', '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid), -- Iarley
    ('josue', '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid), -- Josué
    ('michael', '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid), -- Michael Richard Delgado de Oliveira
    ('paulo_baier', '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid), -- Paulo Baier
    ('rafael_moura', '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid), -- Rafael Moura
    ('rafael_toloi', 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid), -- Rafael Tolói
    ('ricardo_goulart', '4b153bcc-657a-5007-8c20-48c04130a484'::uuid), -- Ricardo Goulart
    ('rodrigo_tabata', '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid), -- Rodrigo Tabata
    ('tadeu', 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid), -- Tadeu Antônio Ferreira
    ('walter', '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid), -- Walter Henrique da Silva
    ('welliton', 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid) -- Welliton Soares de Morais
  ) as e(id, person_id)
  left join public.career_players cp on cp.id = e.id
  where cp.id is null;
  if v_missing_before is not null then
    raise exception 'career_players.id esperado(s) ausente(s) ANTES do backfill: % — auditoria desatualizada, backfill abortado', v_missing_before;
  end if;

  -- Backfill — UPDATE literal, um por linha RESOLVED, idempotente.
  update public.career_players set person_id = '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid where id = 'araujo'; -- Araújo
  update public.career_players set person_id = 'c628f9d8-6719-5506-acbd-adfb683fcf9b'::uuid where id = 'danilo'; -- Danilo Gabriel de Andrade
  update public.career_players set person_id = '7dcb9ad0-b573-5261-aa53-736c3c9b96aa'::uuid where id = 'dill'; -- Dill
  update public.career_players set person_id = '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid where id = 'dudu_cearense'; -- Dudu Cearense
  update public.career_players set person_id = '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid where id = 'egidio'; -- Egídio
  update public.career_players set person_id = '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid where id = 'erik'; -- Erik Nascimento de Lima
  update public.career_players set person_id = 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid where id = 'ernando'; -- Ernando
  update public.career_players set person_id = '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid where id = 'evair'; -- Evair Aparecido Paulino
  update public.career_players set person_id = '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid where id = 'fernandao'; -- Fernandão
  update public.career_players set person_id = '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid where id = 'harlei'; -- Harlei
  update public.career_players set person_id = '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid where id = 'iarley'; -- Iarley
  update public.career_players set person_id = '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid where id = 'josue'; -- Josué
  update public.career_players set person_id = '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid where id = 'michael'; -- Michael Richard Delgado de Oliveira
  update public.career_players set person_id = '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid where id = 'paulo_baier'; -- Paulo Baier
  update public.career_players set person_id = '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid where id = 'rafael_moura'; -- Rafael Moura
  update public.career_players set person_id = 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid where id = 'rafael_toloi'; -- Rafael Tolói
  update public.career_players set person_id = '4b153bcc-657a-5007-8c20-48c04130a484'::uuid where id = 'ricardo_goulart'; -- Ricardo Goulart
  update public.career_players set person_id = '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid where id = 'rodrigo_tabata'; -- Rodrigo Tabata
  update public.career_players set person_id = 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid where id = 'tadeu'; -- Tadeu Antônio Ferreira
  update public.career_players set person_id = '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid where id = 'walter'; -- Walter Henrique da Silva
  update public.career_players set person_id = 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid where id = 'welliton'; -- Welliton Soares de Morais

  -- PÓS 1: cada linha esperada termina com o person_id EXATO esperado
  -- (não só "não-nulo" — o valor certo, nunca um match parcial/silencioso).
  select string_agg(e.id || ' esperado=' || e.person_id::text || ' obtido=' || coalesce(cp.person_id::text, 'NULL'), '; ')
  into v_mismatched_after
  from (
    values
    ('araujo', '50863ba2-ea68-5ebd-9a97-fe43f3882484'::uuid), -- Araújo
    ('danilo', 'c628f9d8-6719-5506-acbd-adfb683fcf9b'::uuid), -- Danilo Gabriel de Andrade
    ('dill', '7dcb9ad0-b573-5261-aa53-736c3c9b96aa'::uuid), -- Dill
    ('dudu_cearense', '7587fc6d-f810-5c41-b206-0a2ffe09a96d'::uuid), -- Dudu Cearense
    ('egidio', '6e8b3d49-4926-5b66-b7f1-8481c2c7a701'::uuid), -- Egídio
    ('erik', '48016516-27c1-5c06-a52a-9893bfc90cf2'::uuid), -- Erik Nascimento de Lima
    ('ernando', 'a79a75b3-6b9c-5dfb-9afd-cb2fe1a1fe25'::uuid), -- Ernando
    ('evair', '6b36f211-ed18-50fb-8cfc-77f8430f1616'::uuid), -- Evair Aparecido Paulino
    ('fernandao', '491bf2d0-f640-5b03-9ab1-a1772095133d'::uuid), -- Fernandão
    ('harlei', '66e38ffb-89f6-5c33-8f67-d9016304b564'::uuid), -- Harlei
    ('iarley', '652b4be1-ed2b-5c0e-a384-4626b9bb5920'::uuid), -- Iarley
    ('josue', '09c38bac-99ee-5173-98f6-cc0d59ecca9c'::uuid), -- Josué
    ('michael', '13c239d9-de5a-51de-b9ce-b4c42aa88d57'::uuid), -- Michael Richard Delgado de Oliveira
    ('paulo_baier', '493bde6b-e169-5649-9c23-e4a5e5f5f08e'::uuid), -- Paulo Baier
    ('rafael_moura', '16d026a7-49b3-5257-9daa-30601e3ef357'::uuid), -- Rafael Moura
    ('rafael_toloi', 'b5d66b3b-e755-5b44-8765-3f2da953a759'::uuid), -- Rafael Tolói
    ('ricardo_goulart', '4b153bcc-657a-5007-8c20-48c04130a484'::uuid), -- Ricardo Goulart
    ('rodrigo_tabata', '81a433ef-5acf-51c1-a38d-742a42ae346e'::uuid), -- Rodrigo Tabata
    ('tadeu', 'e2507d62-8cb5-5152-af56-f67464196ac6'::uuid), -- Tadeu Antônio Ferreira
    ('walter', '828c3bc8-7e25-55c3-8468-d3cec50cd2e5'::uuid), -- Walter Henrique da Silva
    ('welliton', 'a6577244-2373-5e79-b65c-b9200cb2a6e9'::uuid) -- Welliton Soares de Morais
  ) as e(id, person_id)
  join public.career_players cp on cp.id = e.id
  where cp.person_id is distinct from e.person_id;
  if v_mismatched_after is not null then
    raise exception 'backfill não bateu EXATAMENTE com o mapping esperado: % — backfill abortado, nenhuma linha parcialmente aplicada persiste', v_mismatched_after;
  end if;

  -- PÓS 2: contagens agregadas — 21 NOT NULL, 9 NULL, 21 distintos
  -- (0 duplicata). FK de people(id) já é garantida ESTRUTURALMENTE pela
  -- constraint da migration anterior — um person_id inexistente em
  -- `people` já teria rejeitado o UPDATE acima com 23503, abortando a
  -- transação inteira antes de chegar aqui.
  select
    count(*) filter (where person_id is not null),
    count(*) filter (where person_id is null),
    count(distinct person_id) filter (where person_id is not null)
  into v_actual_resolved, v_actual_null, v_actual_distinct
  from public.career_players;

  if v_actual_resolved != v_expected_resolved then
    raise exception 'person_id NOT NULL = %, esperado % — backfill abortado', v_actual_resolved, v_expected_resolved;
  end if;
  if v_actual_null != v_expected_null then
    raise exception 'person_id NULL = %, esperado % — backfill abortado', v_actual_null, v_expected_null;
  end if;
  if v_actual_distinct != v_expected_resolved then
    raise exception 'person_id distintos (não-nulos) = %, esperado % — indica duplicata, backfill abortado', v_actual_distinct, v_expected_resolved;
  end if;

  raise notice 'Etapa F1 backfill validado: % total, % resolved, % null, % distinct person_id — tudo bate exatamente com o mapping auditado.', v_actual_total, v_actual_resolved, v_actual_null, v_actual_distinct;
end $$;
