// Transforma player_club_spells_seed.json + player_club_spell_sources_seed
// .json numa migration SQL determinística.
//
// player_club_spells.id E club_id são literais pré-computados (do spells_
// registry / clubs_registry) — nenhum dos dois é gen_random_uuid() nem
// resolvido por JOIN: toda coluna de negócio de spell é mutável (sem chave
// natural imutável pra JOIN), e club_id vem do club registry (também
// nunca derivado do slug).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902050000_seed_goias_player_club_spells.sql');

const spells = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_spells_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_spell_sources_seed.json'), 'utf8'));

const errors = [];
const validPrecision = new Set(['YEAR', 'MONTH', 'DATE', 'UNKNOWN']);
const validRelationship = new Set(['PERMANENT', 'LOAN', 'UNKNOWN']);
const validVerificationStatus = new Set(['VERIFIED', 'PARTIAL']);
const validEvidenceType = new Set(['PRIMARY', 'CORROBORATING']);
const seenIds = new Set();
for (const s of spells) {
  if (!validPrecision.has(s.startPrecision)) errors.push(`Spell ${s.spellId}: start_precision inválido "${s.startPrecision}".`);
  if (s.endPrecision !== null && !validPrecision.has(s.endPrecision)) errors.push(`Spell ${s.spellId}: end_precision inválido "${s.endPrecision}".`);
  if (s.isOngoing && s.endPrecision !== null) errors.push(`Spell ${s.spellId}: is_ongoing=true mas end_precision não é null.`);
  if (!s.isOngoing && s.endPrecision === null) errors.push(`Spell ${s.spellId}: is_ongoing=false mas end_precision é null.`);
  if (!validVerificationStatus.has(s.verificationStatus)) errors.push(`Spell ${s.spellId}: verification_status inválido "${s.verificationStatus}".`);
  if (seenIds.has(s.spellId)) errors.push(`spellId duplicado no seed: ${s.spellId}`);
  seenIds.add(s.spellId);
}
for (const s of sources) {
  if (!validRelationship.has(s.relationshipType)) errors.push(`Source de ${s.spellId}: relationship_type inválido "${s.relationshipType}".`);
  if (!validEvidenceType.has(s.evidenceType)) errors.push(`Source de ${s.spellId}: evidence_type inválido "${s.evidenceType}".`);
}
if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }
function sqlInt(n) { return n === null || n === undefined ? 'null' : String(n); }
function sqlBool(b) { return b ? 'true' : 'false'; }
function sqlText(s) { return s === null || s === undefined ? 'null' : sqlString(s); }

const sortedSpells = [...spells].sort((a, b) => parseInt(a.canonicalSpellKey.split(':').pop(), 10) - parseInt(b.canonicalSpellKey.split(':').pop(), 10));
const spellById = new Map(sortedSpells.map((s) => [s.spellId, s]));
const sortedSources = [...sources].sort((a, b) => {
  const seqA = parseInt(spellById.get(a.spellId).canonicalSpellKey.split(':').pop(), 10);
  const seqB = parseInt(spellById.get(b.spellId).canonicalSpellKey.split(':').pop(), 10);
  return seqA - seqB || a.source.localeCompare(b.source) || a.sourceRecordKey.localeCompare(b.sourceRecordKey);
});

const header = `-- ============================================================================
-- Seed de \`public.player_club_spells\` + \`public.player_club_spell_sources\`
-- — SOMENTE Goiás, SOMENTE pessoas já em \`public.people\` (96 APPROVED,
-- incluindo Evair/Welliton — ver 20260902000000_add_evair_welliton_people.
-- sql), SOMENTE onde existe evidência estruturada suficiente. NÃO cobre os
-- 96 inteiros de propósito — ver player_club_spells_seed_stats.json pra
-- pessoas bloqueadas.
--
-- GERADA por tooling/multiclub/generate_player_club_spells_seed.mjs a
-- partir de tooling/multiclub/build_player_club_spells_seed.mjs — NUNCA
-- editar à mão.
--
-- spell = período CONTÍNUO de vínculo, não contrato individual — uma
-- mudança empréstimo->compra dentro da MESMA passagem NÃO cria um 2º
-- spell (ver Tadeu, Luiz Felipe: mesclados; ver relationship_type em
-- player_club_spell_sources, não mais em player_club_spells).
--
-- id e club_id são literais pré-computados dos registries persistidos
-- (spells_registry.json / clubs_registry.json) — nunca gen_random_uuid().
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.player_club_spells (
  id, person_id, club_id, start_year, start_month, start_precision,
  end_year, end_month, end_precision, is_ongoing, spell_order, verification_status
)
values
`;

const spellValuesLines = sortedSpells.map((s, i) => {
  const comma = i === sortedSpells.length - 1 ? '' : ',';
  return `  (${sqlString(s.spellId)}::uuid, ${sqlString(s.personId)}::uuid, ${sqlString(s.clubId)}::uuid, ${sqlInt(s.startYear)}, ${sqlInt(s.startMonth)}, ${sqlString(s.startPrecision)}, ${sqlInt(s.endYear)}, ${sqlInt(s.endMonth)}, ${sqlText(s.endPrecision)}, ${sqlBool(s.isOngoing)}, ${sqlInt(s.spellOrder)}, ${sqlString(s.verificationStatus)})${comma}`;
});

const midSection = `
on conflict (id) do nothing;

insert into public.player_club_spell_sources (spell_id, source, source_record_key, evidence_type, relationship_type)
values
`;

const sourceValuesLines = sortedSources.map((s, i) => {
  const comma = i === sortedSources.length - 1 ? '' : ',';
  return `  (${sqlString(s.spellId)}::uuid, ${sqlString(s.source)}, ${sqlString(s.sourceRecordKey)}, ${sqlString(s.evidenceType)}, ${sqlString(s.relationshipType)})${comma}`;
});

const footer = `
on conflict (spell_id, source, source_record_key) do nothing;
`;

const sql = header + spellValuesLines.join('\n') + midSection + sourceValuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

console.log(JSON.stringify({
  migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'),
  spellRows: sortedSpells.length,
  sourceRows: sortedSources.length,
  distinctPeople: new Set(sortedSpells.map((s) => s.personId)).size,
}, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
