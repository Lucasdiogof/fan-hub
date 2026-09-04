// Gera uma migration ADITIVA de `people` — SÓ pra pessoas que ficaram
// APPROVED numa reclassificação POSTERIOR à migration original já aplicada
// (20260901010000_seed_goias_people.sql), sem NUNCA reescrever/regenerar
// esse arquivo original. generate_people_seed.mjs continua existindo e
// intocado — ele é o gerador do seed HISTÓRICO inicial, não deste.
//
// Funciona por DIFF: lê todos os ids já presentes nas migrations de seed de
// people já aplicadas (passadas em APPLIED_MIGRATION_PATHS abaixo), calcula
// que pessoas APPROVED em people_insert_plan.json ainda não estão em
// NENHUMA delas, e escreve SÓ essa diferença no arquivo de saída.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');
const MIGRATIONS_DIR = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files');

const OUTPUT_PATH = path.join(MIGRATIONS_DIR, '20260902000000_add_evair_welliton_people.sql');
const APPLIED_MIGRATION_PATHS = [
  path.join(MIGRATIONS_DIR, '20260901010000_seed_goias_people.sql'),
];
// Sanity check explícito pra esta rodada específica — se o delta calculado
// não bater com o esperado, o script recusa gerar (nunca gera "o que der").
const EXPECTED_NEW_CANONICAL_NAMES = ['Evair Aparecido Paulino', 'Welliton Soares de Morais'];

const plan = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'people_insert_plan.json'), 'utf8'));
const registry = JSON.parse(fs.readFileSync(path.join(TOOLING, 'people_registry.json'), 'utf8'));
const registryByKey = new Map(registry.entries.map((e) => [e.canonicalPersonKey, e]));

const alreadyAppliedIds = new Set();
for (const p of APPLIED_MIGRATION_PATHS) {
  const sql = fs.readFileSync(p, 'utf8');
  const matches = sql.matchAll(/'([0-9a-f-]{36})'/g);
  for (const m of matches) alreadyAppliedIds.add(m[1]);
}

const approved = plan.filter((p) => p.insert_status === 'APPROVED');
const delta = approved.filter((p) => !alreadyAppliedIds.has(p.canonical_person_id));

const errors = [];
if (delta.length !== EXPECTED_NEW_CANONICAL_NAMES.length) {
  errors.push(`Esperava exatamente ${EXPECTED_NEW_CANONICAL_NAMES.length} pessoa(s) nova(s) (${EXPECTED_NEW_CANONICAL_NAMES.join(', ')}), achou ${delta.length}: ${delta.map((d) => d.canonical_name).join(', ') || '(nenhuma)'}`);
}
for (const name of EXPECTED_NEW_CANONICAL_NAMES) {
  if (!delta.some((d) => d.canonical_name === name)) errors.push(`Esperava "${name}" no delta, não encontrado.`);
}

const rows = [];
for (const p of delta) {
  const regEntry = registryByKey.get(p.canonical_person_key);
  if (!regEntry) { errors.push(`"${p.canonical_name}": chave não encontrada no registry.`); continue; }
  if (regEntry.personId !== p.canonical_person_id) { errors.push(`"${p.canonical_name}": id do plano diverge do registry.`); continue; }
  if (alreadyAppliedIds.has(regEntry.personId)) { errors.push(`"${p.canonical_name}": id "${regEntry.personId}" JÁ está numa migration aplicada — não deveria estar no delta.`); continue; }
  rows.push({ id: regEntry.personId, canonicalPersonKey: p.canonical_person_key, canonicalName: p.canonical_name, displayName: p.display_name });
}
rows.sort((a, b) => parseInt(a.canonicalPersonKey.split(':').pop(), 10) - parseInt(b.canonicalPersonKey.split(':').pop(), 10));

if (errors.length) {
  console.error('ERROS — MIGRATION ADITIVA NÃO GERADA:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }

const header = `-- ============================================================================
-- Migration ADITIVA de \`public.people\` — SÓ Evair Aparecido Paulino e
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
`;

const valuesLines = rows.map((r, i) => {
  const comma = i === rows.length - 1 ? '' : ',';
  return `  (${sqlString(r.id)}, ${sqlString(r.canonicalName)}, ${sqlString(r.displayName)})${comma}`;
});
const footer = `\non conflict (id) do nothing;\n`;
const sql = header + valuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
fs.writeFileSync(OUTPUT_PATH, sql);

console.log(JSON.stringify({ migrationFile: path.relative(ROOT, OUTPUT_PATH).replace(/\\/g, '/'), newRows: rows.length, rows: rows.map((r) => r.canonicalName) }, null, 2));
console.log('\nSQL escrito em:', OUTPUT_PATH);
