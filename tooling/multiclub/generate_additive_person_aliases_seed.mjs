// Migration ADITIVA de person_aliases/person_alias_sources — mesmo padrão
// de generate_additive_people_seed.mjs: NUNCA reescreve
// 20260901030000_seed_goias_person_aliases.sql (já aplicada), só calcula o
// DELTA (linhas de Evair/Welliton, que agora existem em people) e escreve
// SÓ isso no arquivo novo.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATIONS_DIR = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files');

const OUTPUT_PATH = path.join(MIGRATIONS_DIR, '20260902010000_add_evair_welliton_aliases.sql');
const APPLIED_ALIASES_MIGRATION = path.join(MIGRATIONS_DIR, '20260901030000_seed_goias_person_aliases.sql');
const EXPECTED_NEW_PERSON_IDS = new Set([
  '6b36f211-ed18-50fb-8cfc-77f8430f1616', // Evair Aparecido Paulino
  'a6577244-2373-5e79-b65c-b9200cb2a6e9', // Welliton Soares de Morais
]);

const aliasSeed = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'person_aliases_seed.json'), 'utf8'));
const aliasSourceSeed = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'person_alias_sources_seed.json'), 'utf8'));

// person_aliases já aplicados: extrai os person_id (1º literal de cada
// linha de VALUES do INSERT em person_aliases) do SQL já rodado em prod.
const appliedSql = fs.readFileSync(APPLIED_ALIASES_MIGRATION, 'utf8');
const appliedPersonAliasBlock = appliedSql.split('insert into public.person_alias_sources')[0];
const appliedPersonIds = new Set([...appliedPersonAliasBlock.matchAll(/\(\s*'([0-9a-f-]{36})'/g)].map((m) => m[1]));

const errors = [];
const deltaAliasIndexes = [];
aliasSeed.forEach((a, idx) => {
  const isNewPerson = EXPECTED_NEW_PERSON_IDS.has(a.personId);
  const isAlreadyApplied = appliedPersonIds.has(a.personId);
  if (isNewPerson && isAlreadyApplied) errors.push(`Alias "${a.alias}" (person ${a.personId}) marcado como novo mas JÁ está na migration aplicada.`);
  if (isNewPerson) deltaAliasIndexes.push(idx);
});
const deltaPersonIdsFound = new Set(deltaAliasIndexes.map((i) => aliasSeed[i].personId));
for (const id of EXPECTED_NEW_PERSON_IDS) {
  if (!deltaPersonIdsFound.has(id)) errors.push(`person_id esperado "${id}" não apareceu em nenhuma linha do alias seed — build_person_aliases_seed.mjs rodou depois da reclassificação?`);
}
// nenhuma linha de pessoa JÁ aprovada antes deve vazar pro delta
for (const idx of deltaAliasIndexes) {
  if (appliedPersonIds.has(aliasSeed[idx].personId)) errors.push(`Vazamento: alias de person_id já aplicado entrou no delta (${aliasSeed[idx].personId}).`);
}

if (errors.length) {
  console.error('ERROS — MIGRATION ADITIVA NÃO GERADA:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

const deltaAliasIndexSet = new Set(deltaAliasIndexes);
const deltaAliases = deltaAliasIndexes.map((i) => aliasSeed[i]);
const deltaSources = aliasSourceSeed.filter((s) => deltaAliasIndexSet.has(s.aliasIndex));

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }
function sqlBool(b) { return b ? 'true' : 'false'; }

deltaAliases.sort((a, b) => a.personId.localeCompare(b.personId) || a.normalizedAlias.localeCompare(b.normalizedAlias));

const header = `-- ============================================================================
-- Migration ADITIVA de \`public.person_aliases\` + \`public.person_alias_sources\`
-- — SÓ os aliases de Evair Aparecido Paulino e Welliton Soares de Morais,
-- que agora existem em \`public.people\` (ver
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
`;

const aliasValuesLines = deltaAliases.map((a, i) => {
  const comma = i === deltaAliases.length - 1 ? '' : ',';
  return `  (${sqlString(a.personId)}, ${sqlString(a.alias)}, ${sqlString(a.normalizedAlias)}, ${sqlString(a.aliasType)}, ${sqlBool(a.isPreferred)})${comma}`;
});

const midSection = `
on conflict (person_id, normalized_alias) do nothing;

insert into public.person_alias_sources (person_alias_id, source, source_record_key)
select pa.id, v.source, v.source_record_key
from (
  values
`;

const sourceValuesLines = deltaSources.map((s, i) => {
  const a = aliasSeed[s.aliasIndex];
  const comma = i === deltaSources.length - 1 ? '' : ',';
  return `    (${sqlString(a.personId)}::uuid, ${sqlString(a.normalizedAlias)}, ${sqlString(s.source)}, ${sqlString(s.sourceRecordKey)})${comma}`;
});

const footer = `
) as v(person_id, normalized_alias, source, source_record_key)
join public.person_aliases pa
  on pa.person_id = v.person_id and pa.normalized_alias = v.normalized_alias
on conflict (person_alias_id, source, source_record_key) do nothing;
`;

const sql = header + aliasValuesLines.join('\n') + midSection + sourceValuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
fs.writeFileSync(OUTPUT_PATH, sql);

console.log(JSON.stringify({
  migrationFile: path.relative(ROOT, OUTPUT_PATH).replace(/\\/g, '/'),
  deltaAliasRows: deltaAliases.length,
  deltaSourceRows: deltaSources.length,
  distinctNewPeople: new Set(deltaAliases.map((a) => a.personId)).size,
}, null, 2));
console.log('\nSQL escrito em:', OUTPUT_PATH);
