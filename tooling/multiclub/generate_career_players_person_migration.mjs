// Gera as 2 migrations ADITIVAS da Etapa F1 a partir de
// career_players_person_mapping.json — NUNCA um `select ... where
// canonical_name ilike ...` dentro do SQL, sempre UUID literal já
// resolvido pelo mapping (mesma disciplina de todas as etapas anteriores).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCHEMA_MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902140000_add_person_id_to_career_players.sql');
const BACKFILL_MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902150000_backfill_career_players_person_id.sql');

const mapping = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'career_players_person_mapping.json'), 'utf8'));

const errors = [];
const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
for (const m of mapping) {
  if (m.status === 'RESOLVED') {
    if (!m.personId || !uuidRe.test(m.personId)) errors.push(`${m.careerPlayerKey}: RESOLVED sem personId UUID válido.`);
  } else if (m.personId) {
    errors.push(`${m.careerPlayerKey}: status=${m.status} mas personId preenchido — só RESOLVED pode ter personId.`);
  }
}
if (errors.length) {
  console.error('ERROS — MIGRATION NÃO GERADA:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }

const resolved = mapping.filter((m) => m.status === 'RESOLVED').sort((a, b) => a.careerPlayerKey.localeCompare(b.careerPlayerKey));
const unresolvedCount = mapping.length - resolved.length;

// ---------------------------------------------------------------------------
// Migration 1 — schema (coluna aditiva, nullable, FK, índice, UNIQUE)
// ---------------------------------------------------------------------------
const schemaSql = `-- ============================================================================
-- Etapa F1 — adiciona identidade canônica a `+'`public.career_players`'+` (Adivinhe
-- o Jogador), SEM remover nada do modelo atual. \`career_players\` continua
-- existindo e sendo lido normalmente pela feature — esta coluna é só a
-- ponte pra \`people\`, consumida quando fizer sentido (ex.: cross-feature,
-- futuras etapas F2+), nunca obrigatória pra a feature funcionar hoje.
--
-- person_id NULLABLE de propósito: ${unresolvedCount} de ${mapping.length} linhas ainda não
-- têm identidade canônica APROVADA o bastante pra persistir com segurança
-- (ver career_players_person_mapping_stats.json — todas classificadas
-- UNRESOLVED, nenhuma resolvida "pelo nome parecido"). NUNCA forçar NOT
-- NULL só pra fechar a migration — isso escancararia exatamente o erro que
-- a reconciliação inteira (Etapas A-E) existe pra evitar.
--
-- UNIQUE(person_id): auditado, não suposto — career_players é hoje
-- genuinamente 1 linha por jogador (id text primary key, um "elenco" de
-- 30 jogadores editorialmente selecionados pro jogo, nunca uma linha por
-- trajetória/edição) e as ${resolved.length} linhas RESOLVED desta migration têm
-- ${resolved.length} person_id distintos, sem nenhuma colisão (ver
-- career_players_person_mapping_stats.json.duplicatePersonIdIssues, vazio).
-- UNIQUE permite múltiplos NULL sem conflito (semântica padrão do
-- Postgres), então não trava as linhas UNRESOLVED.
--
-- SEM índice adicional: UNIQUE(person_id) já cria seu próprio índice
-- (btree) no Postgres — um \`create index\` extra na mesma coluna seria
-- puramente redundante, nunca usado pelo planner sobre o índice da
-- constraint.
--
-- Migration ADITIVA: não altera nenhuma linha, nenhuma RLS/policy/grant,
-- nenhuma outra tabela.
-- ============================================================================

alter table public.career_players
  add column if not exists person_id uuid references public.people(id);

alter table public.career_players
  add constraint career_players_person_id_key unique (person_id);

comment on column public.career_players.person_id is
  'Identidade canônica (Etapa F1) — aponta pra people.id quando existe
  exatamente 1 pessoa canônica APROVADA reconciliada pra este jogador
  (ver tooling/multiclub/career_players_person_mapping.json). NULL quando
  ainda não há identidade segura o bastante (nunca resolvido por nome
  parecido) — career_players.name continua a fonte de exibição enquanto
  person_id for NULL. NUNCA usar career_players.name como FK lógica pra
  decidir "é a mesma pessoa" em código novo — use person_id.';
`;

fs.mkdirSync(path.dirname(SCHEMA_MIGRATION_PATH), { recursive: true });
fs.writeFileSync(SCHEMA_MIGRATION_PATH, schemaSql);

// ---------------------------------------------------------------------------
// Migration 2 — backfill (UPDATE literal, só as RESOLVED) + validação forte
// ---------------------------------------------------------------------------
const expectedTotal = mapping.length;
const expectedResolved = resolved.length;
const expectedNull = expectedTotal - expectedResolved;

// VALUES literal (id, person_id) — a MESMA lista serve pra (a) checar que
// todo id esperado existe ANTES do backfill, (b) aplicar o UPDATE, e
// (c) checar que cada linha terminou com EXATAMENTE o person_id esperado
// DEPOIS — nunca um `select ... ilike/canonical_name`, sempre este par
// literal vindo do mapping.
const expectedValuesLines = resolved.map((m, i) => `    (${sqlString(m.careerPlayerKey)}, ${sqlString(m.personId)}::uuid)${i === resolved.length - 1 ? '' : ','} -- ${m.canonicalName}`);

const updateLines = resolved.map((m) => `  update public.career_players set person_id = ${sqlString(m.personId)}::uuid where id = ${sqlString(m.careerPlayerKey)}; -- ${m.canonicalName}`);

const backfillSql = `-- ============================================================================
-- Etapa F1 — backfill de \`career_players.person_id\` pras ${expectedResolved} linhas
-- RESOLVED (de ${expectedTotal} totais — as outras ${expectedNull} ficam NULL, nunca um
-- palpite). GERADA por tooling/multiclub/generate_career_players_person_
-- migration.mjs a partir de tooling/multiclub/build_career_players_person_
-- mapping.mjs — NUNCA editar à mão, NUNCA um \`select ... where
-- canonical_name ilike\`, sempre UUID literal já resolvido pelo mapping.
--
-- Endurecido com PRÉ e PÓS-condição — a migration FALHA (RAISE EXCEPTION,
-- rollback automático da transação inteira) se a realidade do banco não
-- bater EXATAMENTE com o que foi auditado, em vez de aplicar 21 UPDATEs
-- silenciosos e confiar que "provavelmente casou tudo":
--   PRÉ:  career_players tem exatamente ${expectedTotal} linhas; cada um dos
--         ${expectedResolved} ids esperados EXISTE na tabela antes do backfill.
--   PÓS:  cada uma das ${expectedResolved} linhas termina com o person_id
--         EXATO esperado (não só "não-nulo" — o valor literal certo);
--         contagem de person_id NOT NULL = ${expectedResolved}; contagem NULL = ${expectedNull};
--         contagem de person_id DISTINCT (não-nulo) = ${expectedResolved} (nenhuma
--         duplicata). FK de people(id) já é garantida estruturalmente pela
--         constraint da migration anterior — um person_id inexistente em
--         \`people\` já rejeitaria o UPDATE com 23503 antes de qualquer
--         checagem daqui.
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
begin
  -- PRÉ 1: total de linhas bate com o auditado
  select count(*) into v_actual_total from public.career_players;
  if v_actual_total != v_expected_total then
    raise exception 'career_players tem % linhas, esperado % — auditoria desatualizada, backfill abortado', v_actual_total, v_expected_total;
  end if;

  -- PRÉ 2: cada um dos ${expectedResolved} ids esperados EXISTE antes do backfill
  -- (nunca resolver por canonical_name/answer/ilike/alias — sempre este
  -- par literal (id, person_id) vindo do mapping).
  select string_agg(e.id, ', ') into v_missing_before
  from (
    values
${expectedValuesLines.join('\n')}
  ) as e(id, person_id)
  left join public.career_players cp on cp.id = e.id
  where cp.id is null;
  if v_missing_before is not null then
    raise exception 'career_players.id esperado(s) ausente(s) ANTES do backfill: % — auditoria desatualizada, backfill abortado', v_missing_before;
  end if;

  -- Backfill — UPDATE literal, um por linha RESOLVED, idempotente.
${updateLines.join('\n')}

  -- PÓS 1: cada linha esperada termina com o person_id EXATO esperado
  -- (não só "não-nulo" — o valor certo, nunca um match parcial/silencioso).
  select string_agg(e.id || ' esperado=' || e.person_id::text || ' obtido=' || coalesce(cp.person_id::text, 'NULL'), '; ')
  into v_mismatched_after
  from (
    values
${expectedValuesLines.join('\n')}
  ) as e(id, person_id)
  join public.career_players cp on cp.id = e.id
  where cp.person_id is distinct from e.person_id;
  if v_mismatched_after is not null then
    raise exception 'backfill não bateu EXATAMENTE com o mapping esperado: % — backfill abortado, nenhuma linha parcialmente aplicada persiste', v_mismatched_after;
  end if;

  -- PÓS 2: contagens agregadas — 21 NOT NULL, 9 NULL, 21 distintos
  -- (0 duplicata). FK de people(id) já é garantida ESTRUTURALMENTE pela
  -- constraint da migration anterior — um person_id inexistente em
  -- \`people\` já teria rejeitado o UPDATE acima com 23503, abortando a
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
`;

fs.writeFileSync(BACKFILL_MIGRATION_PATH, backfillSql);

console.log(JSON.stringify({
  schemaMigration: path.relative(ROOT, SCHEMA_MIGRATION_PATH).replace(/\\/g, '/'),
  backfillMigration: path.relative(ROOT, BACKFILL_MIGRATION_PATH).replace(/\\/g, '/'),
  resolvedRows: resolved.length,
  unresolvedRows: unresolvedCount,
}, null, 2));
console.log('\nSQL escrito em supabase/migrations/');
