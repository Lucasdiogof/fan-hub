-- Etapa F4.5 — corrige 8 spells de player_club_spells que
-- estavam com is_ongoing=false e end_year/end_month futuros em relação a
-- hoje (2026-09-02). Causa raiz: squad_members.club_history authored o
-- término CONTRATUAL do empréstimo (data prevista de fim), não uma saída
-- já ocorrida — os 8 jogadores seguem no elenco atual (squad_members,
-- updated_at=2026-08-24). Nenhuma linha nova é criada: apenas UPDATE nas
-- spells já existentes, mesmo id/canonicalSpellKey preservados.
--
-- felipe_clemente também recebe um refinamento de start_precision
-- (MONTH -> DATE), usando uma data já presente na fonte cadastrada
-- (squad_members.club_history notes: "Chegou por empréstimo em
-- 21/08/2026"), nunca uma data pesquisada/nova.
--
-- A expiração contratual removida de end_* NÃO é apagada de verdade: ela
-- continua integralmente disponível em squad_members.club_history (fonte
-- bruta, intocada por esta migration) e referenciada pela proveniência já
-- registrada em player_club_spell_sources (source_record_key =
-- squad_members:<id>:club_history:<n>, evidence_type=PRIMARY,
-- relationship_type=LOAN, 1 linha por spell, verificado abaixo). O que
-- muda é só a leitura canônica derivada: "fim contratual previsto" !=
-- "fim real da passagem".
--
-- Nenhuma condição de negócio aqui usa now()/current_date — todos os
-- valores esperados são literais, auditados em 2026-09-02
-- (current_squad_canonical_gap_fix_plan.json). now() só aparece em
-- updated_at, que é housekeeping, nunca uma decisão de negócio.
--
-- Evidência completa: tooling/multiclub/current_squad_gap_evidence.json
-- Plano auditável: data_export/goias/player_reconciliation/current_squad_canonical_gap_fix_plan.json

do $$
declare
  v_total_spells_before int;
  v_total_spells_after int;
  v_provenance_before int;
  v_provenance_after int;
  v_bad_ongoing_count int;
  v_overlap_count int;
begin
  select count(*) into v_total_spells_before from public.player_club_spells;
  if v_total_spells_before <> 64 then
    raise exception 'PRÉ-condição falhou: esperava % linhas em player_club_spells no total (contagem auditada em 2026-09-02), achou % — estado do banco divergiu do esperado, abortando', 64, v_total_spells_before;
  end if;

  select count(*) into v_provenance_before
    from public.player_club_spell_sources
   where spell_id in ('7153d35c-3268-5d44-b119-230c51e0e18e', '51689444-28a6-557f-a5d9-02fb4b697aaa', '2bf5083c-3406-5cc0-a52f-62f7204ac01e', '34671275-a21f-5850-b5c3-6b6a7fb682c2', 'ea61834d-ecb4-5bfc-98f6-dd1b50fbca67', '9fb99be2-3301-57fc-8a90-c541fbe51271', '7888b147-6881-56cd-8c19-8bd94bc2ea20', '17202656-70b9-502e-9766-e7bd7b593eee');
  if v_provenance_before <> 8 then
    raise exception 'PRÉ-condição falhou: esperava % linhas de proveniência pros % spells alvo (a evidência do vínculo precisa já existir antes de nularmos end_*), achou %', 8, 8, v_provenance_before;
  end if;

  -- PRÉ: estado EXATO de cada um dos 8 spells alvo, auditado em 2026-09-02.
  -- Detecta qualquer drift entre a auditoria e o momento do push — se
  -- qualquer campo divergir, aborta ANTES de tocar em qualquer linha.
  -- Luis Fellipe Campos Doria (squad_members:luisao) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '7153d35c-3268-5d44-b119-230c51e0e18e'
       and person_id = '91e2722f-6fce-535e-9bd9-d2420889b1af'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2026
       and start_month = 1
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '7153d35c-3268-5d44-b119-230c51e0e18e', 'Luis Fellipe Campos Doria';
  end if;

  -- Ramon Menezes Roma (squad_members:ramon_menezes) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '51689444-28a6-557f-a5d9-02fb4b697aaa'
       and person_id = 'd30dc008-4189-58bf-9823-8e8ab93dd7e0'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2026
       and start_month = 3
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '51689444-28a6-557f-a5d9-02fb4b697aaa', 'Ramon Menezes Roma';
  end if;

  -- Luiz Filipe da Rosa Machado (squad_members:filipe_machado) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '2bf5083c-3406-5cc0-a52f-62f7204ac01e'
       and person_id = 'ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2026
       and start_month = 1
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 11
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '2bf5083c-3406-5cc0-a52f-62f7204ac01e', 'Luiz Filipe da Rosa Machado';
  end if;

  -- Geirton Marques Aires (squad_members:gege) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '34671275-a21f-5850-b5c3-6b6a7fb682c2'
       and person_id = '88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2026
       and start_month = 1
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '34671275-a21f-5850-b5c3-6b6a7fb682c2', 'Geirton Marques Aires';
  end if;

  -- Wellington Soares da Silva (squad_members:wellington_rato) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = 'ea61834d-ecb4-5bfc-98f6-dd1b50fbca67'
       and person_id = '4dd73b43-f2ac-536a-8b22-ab4f7c125c68'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2025
       and start_month = 7
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', 'ea61834d-ecb4-5bfc-98f6-dd1b50fbca67', 'Wellington Soares da Silva';
  end if;

  -- Carlos Eduardo Amaral Pereira de Castro (squad_members:cadu) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '9fb99be2-3301-57fc-8a90-c541fbe51271'
       and person_id = '6702c943-0b4e-5041-8cd4-76991b85633d'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2026
       and start_month = 2
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '9fb99be2-3301-57fc-8a90-c541fbe51271', 'Carlos Eduardo Amaral Pereira de Castro';
  end if;

  -- Luiz Felipe Clemente de Almeida (squad_members:felipe_clemente) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '7888b147-6881-56cd-8c19-8bd94bc2ea20'
       and person_id = '7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2026
       and start_month = 8
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '7888b147-6881-56cd-8c19-8bd94bc2ea20', 'Luiz Felipe Clemente de Almeida';
  end if;

  -- Carlos Eduardo de Sousa Leopoldino (squad_members:kadu_sousa) — estado exato auditado em 2026-09-02
  if not exists (
    select 1 from public.player_club_spells
     where id = '17202656-70b9-502e-9766-e7bd7b593eee'
       and person_id = '6bc585a3-1b56-58c3-8ba7-6f208151ae47'
       and club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and is_ongoing = false
       and start_year = 2025
       and start_month = 12
       and start_date is null
       and start_precision = 'MONTH'
       and end_year = 2026
       and end_month = 12
       and end_date is null
       and end_precision = 'MONTH'
       and verification_status = 'VERIFIED'
  ) then
    raise exception 'DRIFT DETECTADO no spell % (%) — estado atual diverge do estado auditado em 2026-09-02, abortando sem aplicar nada parcialmente', '17202656-70b9-502e-9766-e7bd7b593eee', 'Carlos Eduardo de Sousa Leopoldino';
  end if;

  -- Luis Fellipe Campos Doria (squad_members:luisao) — goias-app:multiclub:spell:19
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = '7153d35c-3268-5d44-b119-230c51e0e18e';

  -- Ramon Menezes Roma (squad_members:ramon_menezes) — goias-app:multiclub:spell:23
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = '51689444-28a6-557f-a5d9-02fb4b697aaa';

  -- Luiz Filipe da Rosa Machado (squad_members:filipe_machado) — goias-app:multiclub:spell:30
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = '2bf5083c-3406-5cc0-a52f-62f7204ac01e';

  -- Geirton Marques Aires (squad_members:gege) — goias-app:multiclub:spell:34
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = '34671275-a21f-5850-b5c3-6b6a7fb682c2';

  -- Wellington Soares da Silva (squad_members:wellington_rato) — goias-app:multiclub:spell:37
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = 'ea61834d-ecb4-5bfc-98f6-dd1b50fbca67';

  -- Carlos Eduardo Amaral Pereira de Castro (squad_members:cadu) — goias-app:multiclub:spell:40
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = '9fb99be2-3301-57fc-8a90-c541fbe51271';

  -- Luiz Felipe Clemente de Almeida (squad_members:felipe_clemente) — goias-app:multiclub:spell:41
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         start_date = '2026-08-21',
         start_precision = 'DATE',
         updated_at = now()
   where id = '7888b147-6881-56cd-8c19-8bd94bc2ea20';

  -- Carlos Eduardo de Sousa Leopoldino (squad_members:kadu_sousa) — goias-app:multiclub:spell:45
  update public.player_club_spells
     set is_ongoing = true,
         end_year = null,
         end_month = null,
         end_date = null,
         end_precision = null,
         updated_at = now()
   where id = '17202656-70b9-502e-9766-e7bd7b593eee';

  -- PÓS: nenhuma linha nova/removida em player_club_spells — só UPDATE.
  select count(*) into v_total_spells_after from public.player_club_spells;
  if v_total_spells_after <> v_total_spells_before then
    raise exception 'PÓS-condição falhou: player_club_spells tinha % linhas antes, tem % depois — deveria ser exatamente igual (só UPDATE, nunca INSERT/DELETE)', v_total_spells_before, v_total_spells_after;
  end if;

  -- PÓS: proveniência dos 8 spells alvo continua intocada (nada apagado).
  select count(*) into v_provenance_after
    from public.player_club_spell_sources
   where spell_id in ('7153d35c-3268-5d44-b119-230c51e0e18e', '51689444-28a6-557f-a5d9-02fb4b697aaa', '2bf5083c-3406-5cc0-a52f-62f7204ac01e', '34671275-a21f-5850-b5c3-6b6a7fb682c2', 'ea61834d-ecb4-5bfc-98f6-dd1b50fbca67', '9fb99be2-3301-57fc-8a90-c541fbe51271', '7888b147-6881-56cd-8c19-8bd94bc2ea20', '17202656-70b9-502e-9766-e7bd7b593eee');
  if v_provenance_after <> v_provenance_before then
    raise exception 'PÓS-condição falhou: proveniência dos spells alvo mudou de % pra % linhas — esta migration nunca deveria tocar player_club_spell_sources', v_provenance_before, v_provenance_after;
  end if;

  -- PÓS: invariante do ELENCO ATUAL INTEIRO (31 pessoas), não só os 8 corrigidos —
  -- exatamente 1 spell Goiás ongoing por pessoa (0 com nenhum, 0 com 2+).
  with target_people(person_id) as (
    values
    ('0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid),
    ('10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid),
    ('140ba628-c222-53a5-8621-a774092a125b'::uuid),
    ('2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid),
    ('34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid),
    ('36ed37b5-02be-5117-91d6-a62d5236505f'::uuid),
    ('424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid),
    ('4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid),
    ('54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid),
    ('66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid),
    ('6702c943-0b4e-5041-8cd4-76991b85633d'::uuid),
    ('6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid),
    ('747cb968-a339-586c-94cf-583a3e0c3296'::uuid),
    ('75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid),
    ('7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid),
    ('879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid),
    ('88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid),
    ('91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid),
    ('a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid),
    ('a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid),
    ('af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid),
    ('b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid),
    ('be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid),
    ('ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid),
    ('d30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid),
    ('d58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid),
    ('e2507d62-8cb5-5152-af56-f67464196ac6'::uuid),
    ('e277edea-70b1-5092-ad39-48be1a5297d6'::uuid),
    ('e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid)
  ),
  ongoing_counts as (
    select tp.person_id, count(s.id) as ongoing_count
      from target_people tp
      left join public.player_club_spells s
        on s.person_id = tp.person_id
       and s.club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
       and s.is_ongoing = true
     group by tp.person_id
  )
  select count(*) into v_bad_ongoing_count from ongoing_counts where ongoing_count <> 1;
  if v_bad_ongoing_count <> 0 then
    raise exception 'PÓS-condição falhou: % pessoas do elenco atual (de 31) NÃO têm exatamente 1 spell Goiás ongoing — esperava 0', v_bad_ongoing_count;
  end if;

  -- PÓS: 0 overlap entre spells Goiás da MESMA pessoa, pro elenco inteiro
  -- (granularidade de mês — ongoing tratado como fim em 9999-12, mês
  -- ausente tratado como o mais abrangente pra cada lado: 1 no início,
  -- 12 no fim — checagem conservadora, nunca deixa passar um overlap real).
  with target_people(person_id) as (
    values
    ('0b374c05-3edd-5cbb-9ddf-71b1b37e79ba'::uuid),
    ('10f6579f-1bc4-5b2a-ab9f-0a1a262519a1'::uuid),
    ('140ba628-c222-53a5-8621-a774092a125b'::uuid),
    ('2bd4e578-4739-5f93-b5db-8ecf6ba44393'::uuid),
    ('34d6fed1-6282-564a-bcb0-5be7d705760a'::uuid),
    ('36ed37b5-02be-5117-91d6-a62d5236505f'::uuid),
    ('424f8724-6855-58d6-ad36-24e2d9bdd7f6'::uuid),
    ('4dd73b43-f2ac-536a-8b22-ab4f7c125c68'::uuid),
    ('54e8cc38-7ac7-5927-b7a5-ca11a372a545'::uuid),
    ('66cd616b-9b5d-56f9-879e-1b171a8a33d0'::uuid),
    ('6702c943-0b4e-5041-8cd4-76991b85633d'::uuid),
    ('6bc585a3-1b56-58c3-8ba7-6f208151ae47'::uuid),
    ('747cb968-a339-586c-94cf-583a3e0c3296'::uuid),
    ('75723744-c847-55e8-acf2-d8ee0d75c7a1'::uuid),
    ('7e23a7b8-33ac-5c84-9b35-bfe5bc2cc5a4'::uuid),
    ('83765e63-a9f9-584e-aef1-bf11c3324b5e'::uuid),
    ('879326ba-8353-5fc8-ab0f-c6ca4646a143'::uuid),
    ('88a5f4a0-ed1a-5a0f-b2d9-0294157789dd'::uuid),
    ('91e2722f-6fce-535e-9bd9-d2420889b1af'::uuid),
    ('a2ef1bbc-c0a2-572c-9954-4c5513b07eae'::uuid),
    ('a597dae2-6ca9-5588-b1e3-a3532dd36f0e'::uuid),
    ('a7ba5544-1384-5830-94a6-632f1c9e8414'::uuid),
    ('af92cda1-aeba-5f69-a354-2928d8677c6f'::uuid),
    ('b9d994d7-3605-5e6e-89ca-7d223f87d14a'::uuid),
    ('be72ef65-0fdc-5f2a-b09a-ff8da6a279fb'::uuid),
    ('ce0c99ff-f0a3-5743-9bf6-3cfb7ecfcf5f'::uuid),
    ('d30dc008-4189-58bf-9823-8e8ab93dd7e0'::uuid),
    ('d58d5ae2-85c7-5336-80b6-0f4c0ed0a24b'::uuid),
    ('e2507d62-8cb5-5152-af56-f67464196ac6'::uuid),
    ('e277edea-70b1-5092-ad39-48be1a5297d6'::uuid),
    ('e590ad99-16d4-52a1-88fd-2fbb064444b6'::uuid)
  ),
  spells_bounds as (
    select s.id, s.person_id,
           (s.start_year * 12 + coalesce(s.start_month, 1)) as start_ord,
           case when s.is_ongoing then 999912
                else (s.end_year * 12 + coalesce(s.end_month, 12))
           end as end_ord
      from public.player_club_spells s
      join target_people tp on tp.person_id = s.person_id
     where s.club_id = '4c16340d-300c-5ab2-903f-17519db9b146'
  )
  select count(*) into v_overlap_count
    from spells_bounds a
    join spells_bounds b on a.person_id = b.person_id and a.id < b.id
   where a.start_ord <= b.end_ord and b.start_ord <= a.end_ord;
  if v_overlap_count <> 0 then
    raise exception 'PÓS-condição falhou: % par(es) de spells Goiás sobrepostos pra alguma pessoa do elenco atual — esperava 0', v_overlap_count;
  end if;
end $$;
