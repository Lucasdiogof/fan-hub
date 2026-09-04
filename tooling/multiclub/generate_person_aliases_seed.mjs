// Transforma person_aliases_seed.json + person_alias_sources_seed.json numa
// migration SQL determinística. NUNCA gera UUID pra person_aliases.id no
// texto da migration (fica a cargo do DEFAULT gen_random_uuid() da tabela —
// diferente de people.id, o id do alias não é referenciado por FK externa
// nenhuma, só internamente por person_alias_sources, então não precisa do
// mesmo registry persistido). person_id, esse sim, vem SEMPRE do registry,
// cross-validado antes de escrever qualquer linha.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');
const MIGRATION_PATH = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260901030000_seed_goias_person_aliases.sql');

// GUARD — esta migration JÁ FOI APLICADA em produção. person_aliases_seed
// .json/person_alias_sources_seed.json refletem o estado ATUAL de people
// (que evolui — ex.: Evair/Welliton), então rodar este gerador de novo
// sobrescreveria o arquivo aplicado com um conteúdo divergente do banco.
// Pessoas novas ganham aliases numa migration ADITIVA separada (ver
// generate_additive_person_aliases_seed.mjs). Já aconteceu por engano uma
// vez (rodado sem querer dentro de um teste de reprodutibilidade) —
// restaurado via `git checkout` a tempo.
const MIGRATION_ALREADY_APPLIED = true;
if (MIGRATION_ALREADY_APPLIED) {
  console.error(`RECUSADO: ${path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/')} já foi aplicada em produção — este gerador não roda mais. Pessoas novas vão em migration ADITIVA própria (ver generate_additive_person_aliases_seed.mjs).`);
  process.exit(1);
}

const aliasSeed = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'person_aliases_seed.json'), 'utf8'));
const aliasSourceSeed = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'person_alias_sources_seed.json'), 'utf8'));
const registry = JSON.parse(fs.readFileSync(path.join(TOOLING, 'people_registry.json'), 'utf8'));

const errors = [];
const warnings = [];

// ---------------------------------------------------------------------------
// 1. Cross-valida TODO person_id do seed contra o registry — nunca confia
//    cego no que já está no JSON.
// ---------------------------------------------------------------------------

const registryByKey = new Map(registry.entries.map((e) => [e.canonicalPersonKey, e]));
for (const a of aliasSeed) {
  const entry = registryByKey.get(a.canonicalPersonKey);
  if (!entry) { errors.push(`Alias "${a.alias}" (${a.canonicalPersonKey}): chave não encontrada no registry.`); continue; }
  if (entry.personId !== a.personId) { errors.push(`Alias "${a.alias}": person_id do seed (${a.personId}) diverge do registry (${entry.personId}).`); }
}

const validTypes = new Set(['LEGAL_NAME', 'FULL_NAME', 'DISPLAY_NAME', 'NICKNAME', 'SHORT_NAME', 'SOURCE_VARIANT', 'MISSPELLING']);
for (const a of aliasSeed) {
  if (!validTypes.has(a.aliasType)) errors.push(`Alias "${a.alias}": alias_type "${a.aliasType}" inválido.`);
}

// Determinismo: ordena por (canonicalPersonKey numérico, normalizedAlias) —
// nunca por Object.values()/Map iteration order, que já é estável aqui mas
// não deveria ser uma suposição implícita.
function seqOf(key) { return parseInt(String(key).split(':').pop(), 10); }
const sortedAliases = [...aliasSeed].sort((a, b) => seqOf(a.canonicalPersonKey) - seqOf(b.canonicalPersonKey) || a.normalizedAlias.localeCompare(b.normalizedAlias));
const sortedSources = [...aliasSourceSeed].sort((a, b) => {
  const aa = aliasSeed[a.aliasIndex];
  const ab = aliasSeed[b.aliasIndex];
  return seqOf(aa.canonicalPersonKey) - seqOf(ab.canonicalPersonKey)
    || aa.normalizedAlias.localeCompare(ab.normalizedAlias)
    || a.sourceRecordKey.localeCompare(b.sourceRecordKey);
});

if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}
if (warnings.length) {
  console.warn('AVISOS:');
  for (const w of warnings) console.warn(' -', w);
}

// ---------------------------------------------------------------------------
// 2. Gera o SQL
// ---------------------------------------------------------------------------

function sqlString(s) {
  return `'${String(s).replace(/'/g, "''")}'`;
}
function sqlBool(b) {
  return b ? 'true' : 'false';
}

const header = `-- ============================================================================
-- Seed de \`public.person_aliases\` + \`public.person_alias_sources\` — SOMENTE
-- pras ${new Set(sortedAliases.map((a) => a.personId)).size} pessoas que já existem em \`public.people\` (os 94 APPROVED
-- de 20260901010000_seed_goias_people.sql). Nomes/apelidos vindos de todas
-- as fontes reconciliadas (squad_members, career_players, guess_players,
-- lineup_matches, player_identity_references, goias_players.dart) mais
-- canonical_name/display_name da própria people.
--
-- GERADA por tooling/multiclub/generate_person_aliases_seed.mjs a partir
-- de tooling/multiclub/build_person_aliases_seed.mjs — NUNCA editar à mão.
-- Reprodutível: mesma entrada determinística (canonical_people_candidates.
-- json + people_insert_plan.json + people_registry.json + candidates.json)
-- produz este arquivo byte-a-byte idêntico.
--
-- ALIAS NÃO É IDENTIDADE — esta tabela NÃO tem unique(normalized_alias)
-- global. "nicolas" e "danilo" aparecem aqui apontando pra 2 person_id
-- DIFERENTES cada um, de propósito (ver docs/multiclub/
-- 15_player_reconciliation_report.md, seção "Aliases ambíguos"). Todo
-- consumidor precisa tratar um lookup por normalized_alias como podendo
-- devolver 0, 1 ou 2+ linhas.
--
-- person_aliases.id usa o DEFAULT gen_random_uuid() da tabela (não vem do
-- registry) — diferente de people.id, não há FK externa apontando pra um
-- alias específico, só a referência interna de person_alias_sources
-- (linkada abaixo por JOIN em person_id+normalized_alias, não por id
-- conhecido de antemão, pra funcionar mesmo se este seed for reaplicado).
--
-- person_id, esse sim, vem EXATAMENTE de tooling/multiclub/
-- people_registry.json, cross-validado antes deste arquivo ser escrito.
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas — mesmo padrão e
-- mesmo motivo do seed de people (correção futura vem em migration
-- explícita separada, nunca reaplicando este arquivo por cima).
-- ============================================================================

insert into public.person_aliases (person_id, alias, normalized_alias, alias_type, is_preferred)
values
`;

const aliasValuesLines = sortedAliases.map((a, i) => {
  const comma = i === sortedAliases.length - 1 ? '' : ',';
  return `  (${sqlString(a.personId)}, ${sqlString(a.alias)}, ${sqlString(a.normalizedAlias)}, ${sqlString(a.aliasType)}, ${sqlBool(a.isPreferred)})${comma}`;
});

const midSection = `
on conflict (person_id, normalized_alias) do nothing;

insert into public.person_alias_sources (person_alias_id, source, source_record_key)
select pa.id, v.source, v.source_record_key
from (
  values
`;

const sourceValuesLines = sortedSources.map((s, i) => {
  const a = aliasSeed[s.aliasIndex];
  const comma = i === sortedSources.length - 1 ? '' : ',';
  return `    (${sqlString(a.personId)}::uuid, ${sqlString(a.normalizedAlias)}, ${sqlString(s.source)}, ${sqlString(s.sourceRecordKey)})${comma}`;
});

const footer = `
) as v(person_id, normalized_alias, source, source_record_key)
join public.person_aliases pa
  on pa.person_id = v.person_id and pa.normalized_alias = v.normalized_alias
on conflict (person_alias_id, source, source_record_key) do nothing;
`;

const sql = header + aliasValuesLines.join('\n') + midSection + sourceValuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

// ---------------------------------------------------------------------------
// 3. Relatório
// ---------------------------------------------------------------------------

const report = {
  migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'),
  aliasRows: sortedAliases.length,
  aliasSourceRows: sortedSources.length,
  distinctPeople: new Set(sortedAliases.map((a) => a.personId)).size,
  sample: sortedAliases.slice(0, 8).map((a) => ({ personId: a.personId.slice(0, 8) + '…', alias: a.alias, normalizedAlias: a.normalizedAlias, aliasType: a.aliasType, isPreferred: a.isPreferred })),
};
console.log(JSON.stringify(report, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
