// Gera as 2 migrations ADITIVAS da Etapa F4 a partir de
// squad_members_person_mapping.json — mesma disciplina endurecida de
// F1/F3 desde o início: sem índice redundante, backfill com 3
// pré-condições + pós-condição forte num DO block, RAISE EXCEPTION se a
// realidade não bater exatamente. NUNCA um `select ... where
// canonical_name ilike ...`, sempre UUID literal já resolvido pelo mapping.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCHEMA_MIGRATION_PATH = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902180000_add_person_id_to_squad_members.sql');
const BACKFILL_MIGRATION_PATH = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902190000_backfill_squad_members_person_id.sql');

const mapping = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'squad_members_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'squad_members_person_mapping_stats.json'), 'utf8'));

const errors = [];
const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
for (const m of mapping) {
  if (m.status === 'RESOLVED') {
    if (!m.personId || !uuidRe.test(m.personId)) errors.push(`${m.squadMemberId}: RESOLVED sem personId UUID válido.`);
  } else if (m.personId) {
    errors.push(`${m.squadMemberId}: status=${m.status} mas personId preenchido — só RESOLVED pode ter personId.`);
  }
}
if (stats.personIdReusedAcrossRows.length > 0) {
  errors.push(`cardinalidade: ${stats.personIdReusedAcrossRows.length} person_id reusado(s) entre linhas RESOLVED — UNIQUE(person_id) NÃO seria seguro, gerador abortado.`);
}
if (stats.reverseMultiMembership.length > 0) {
  errors.push(`cardinalidade reversa: ${stats.reverseMultiMembership.length} pessoa(s) canônica(s) com 2+ members squad_members — UNIQUE(person_id) NÃO seria seguro, gerador abortado.`);
}
if (errors.length) {
  console.error('ERROS — MIGRATION NÃO GERADA:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }

const resolved = mapping.filter((m) => m.status === 'RESOLVED').sort((a, b) => a.squadMemberId.localeCompare(b.squadMemberId));
const unresolvedCount = mapping.length - resolved.length;

// ---------------------------------------------------------------------------
// Migration 1 — schema (coluna aditiva, nullable, FK, UNIQUE quando seguro,
// sem índice redundante)
// ---------------------------------------------------------------------------
const schemaSql = `-- ============================================================================
-- Etapa F4 — adiciona identidade canônica a \`public.squad_members\` (Elenco
-- profissional ATUAL), SEM remover nada do modelo atual. \`squad_members\`
-- continua existindo e sendo lido normalmente pela feature — esta coluna é
-- só a ponte pra \`people\`, nunca obrigatória pra a feature funcionar hoje.
-- \`squad_members.id\` continua sendo a chave interna/editorial da feature
-- (usada por squadPhotoAssets e por outras features via o mesmo slug, ver
-- relatório) — NUNCA substituída por person_id em nenhum contrato
-- existente.
--
-- person_id NULLABLE — mesmo com ${resolved.length}/${mapping.length} RESOLVED nesta auditoria
-- (elenco atual, 100% já aprovado na fundação canônica), NÃO forçamos NOT
-- NULL nesta migração: é uma migração PARALELA, reversível por design —
-- NOT NULL pode ser considerado numa migração própria e futura, depois de
-- confirmar que nada mais pode inserir uma linha sem person_id resolvido.
--
-- UNIQUE(person_id): auditado nos 2 sentidos, não suposto — nenhuma das
-- ${resolved.length} linhas RESOLVED reusa um person_id já usado por outra
-- (squad_members_person_mapping_stats.json.personIdReusedAcrossRows,
-- vazio), e nenhuma pessoa canônica tem 2+ members source='squad_members'
-- (mesmo arquivo, .reverseMultiMembership, vazio). Reforçado por evidência
-- estrutural: os ${mapping.length} squad_members têm ${mapping.length} nomes completos
-- distintos (0 duplicata) — é o elenco profissional atual, 1 linha por
-- atleta, nunca uma linha por edição/temporada.
--
-- SEM índice adicional: UNIQUE(person_id) já cria seu próprio índice
-- (btree) no Postgres.
--
-- Migration ADITIVA: não altera nenhuma linha, nenhuma RLS/policy/grant,
-- nenhuma outra tabela.
-- ============================================================================

alter table public.squad_members
  add column if not exists person_id uuid references public.people(id);

alter table public.squad_members
  add constraint squad_members_person_id_key unique (person_id);

comment on column public.squad_members.person_id is
  'Identidade canônica (Etapa F4) — aponta pra people.id quando existe
  exatamente 1 pessoa canônica APROVADA reconciliada pra este atleta (ver
  tooling/multiclub/squad_members_person_mapping.json). squad_members.id
  continua a chave interna/editorial da feature (nome exibido, foto via
  squadPhotoAssets, etc.) — NUNCA usar squad_members.name/full_name como
  FK lógica pra decidir "é a mesma pessoa" em código novo, use person_id.';
`;

fs.mkdirSync(path.dirname(SCHEMA_MIGRATION_PATH), { recursive: true });
fs.writeFileSync(SCHEMA_MIGRATION_PATH, schemaSql);

// ---------------------------------------------------------------------------
// Migration 2 — backfill (UPDATE literal, só as RESOLVED) + validação forte
// ---------------------------------------------------------------------------
const expectedTotal = mapping.length;
const expectedResolved = resolved.length;
const expectedNull = expectedTotal - expectedResolved;

const expectedValuesLines = resolved.map((m, i) => `    (${sqlString(m.squadMemberId)}, ${sqlString(m.personId)}::uuid)${i === resolved.length - 1 ? '' : ','} -- ${m.canonicalName}`);
const updateLines = resolved.map((m) => `  update public.squad_members set person_id = ${sqlString(m.personId)}::uuid where id = ${sqlString(m.squadMemberId)}; -- ${m.canonicalName}`);

const backfillSql = `-- ============================================================================
-- Etapa F4 — backfill de \`squad_members.person_id\` pras ${expectedResolved} linhas
-- RESOLVED (de ${expectedTotal} totais — ${expectedNull} ficam NULL, nunca um palpite).
-- GERADA por tooling/multiclub/generate_squad_members_person_migration.mjs
-- a partir de tooling/multiclub/build_squad_members_person_mapping.mjs —
-- NUNCA editar à mão, NUNCA um \`select ... where canonical_name ilike\`,
-- sempre UUID literal já resolvido pelo mapping.
--
-- Endurecido com 3 PRÉ-condições e PÓS-condição — mesma disciplina de F1
-- (2 pré-condições) + F3 (a 3ª, adicionada na revisão daquela etapa,
-- aplicada aqui desde o início) — a migration FALHA (RAISE EXCEPTION,
-- rollback automático da transação inteira) se a realidade do banco não
-- bater EXATAMENTE com o que foi auditado:
--   PRÉ 1: squad_members tem exatamente ${expectedTotal} linhas.
--   PRÉ 2: cada um dos ${expectedResolved} ids esperados EXISTE na tabela antes do
--          backfill.
--   PRÉ 3: count(person_id IS NOT NULL) = 0 ANTES do backfill — a coluna
--          acabou de ser criada pela migration anterior, qualquer valor
--          pré-existente é inesperado, nunca sobrescrito silenciosamente.
--   PÓS:   cada uma das ${expectedResolved} linhas termina com o person_id EXATO
--          esperado (não só "não-nulo"); contagem de person_id NOT NULL =
--          ${expectedResolved}; contagem NULL = ${expectedNull}; contagem de person_id DISTINCT
--          (não-nulo) = ${expectedResolved} (nenhuma duplicata). FK de people(id) já é
--          garantida estruturalmente pela constraint da migration
--          anterior.
--
-- Idempotente por construção: cada UPDATE seta o MESMO literal toda vez
-- que rodar — reprocessar não muda o resultado, e a pós-condição continua
-- batendo.
-- ============================================================================

do $$
declare
  v_expected_total integer := ${expectedTotal};
  v_expected_resolved integer := ${expectedResolved};
  v_expected_null integer := ${expectedNull};
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

  -- PRÉ 2: cada um dos ${expectedResolved} ids esperados EXISTE antes do backfill
  -- (nunca resolver por name/full_name/ilike/alias — sempre este par
  -- literal (id, person_id) vindo do mapping).
  select string_agg(e.id, ', ') into v_missing_before
  from (
    values
${expectedValuesLines.join('\n')}
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
${updateLines.join('\n')}

  -- PÓS 1: cada linha esperada termina com o person_id EXATO esperado.
  select string_agg(e.id || ' esperado=' || e.person_id::text || ' obtido=' || coalesce(sm.person_id::text, 'NULL'), '; ')
  into v_mismatched_after
  from (
    values
${expectedValuesLines.join('\n')}
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
`;

fs.writeFileSync(BACKFILL_MIGRATION_PATH, backfillSql);

console.log(JSON.stringify({
  schemaMigration: path.relative(ROOT, SCHEMA_MIGRATION_PATH).replace(/\\/g, '/'),
  backfillMigration: path.relative(ROOT, BACKFILL_MIGRATION_PATH).replace(/\\/g, '/'),
  resolvedRows: resolved.length,
  unresolvedRows: unresolvedCount,
}, null, 2));
console.log('\nSQL escrito em supabase/migrations/ (NÃO aplicado — item 24 do pedido)');
