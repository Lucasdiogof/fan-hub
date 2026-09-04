// Transforma player_match_appearances_seed.json + player_match_appearance_
// sources_seed.json numa migration SQL determinística.
//
// canonical_match_id agora é um UUID LITERAL (a.canonicalMatchId, já
// resolvido pelo match registry em build_matches_seed.mjs) — nenhum JOIN
// necessário via lineup_match_id, porque essa coluna não existe mais em
// `matches` (ver Etapa E v2 — identidade de fonte separada de identidade
// canônica de partida, match_source_refs). person_id e spell_id já são
// UUIDs reais conhecidos (mesma convenção da Etapa D).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATION_PATH = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902130000_seed_goias_player_match_appearances.sql');

const appearances = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_match_appearances_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_match_appearance_sources_seed.json'), 'utf8'));

const errors = [];
const validStatus = new Set(['STARTED', 'SUBSTITUTE_USED', 'UNUSED_SUBSTITUTE']);
const validVerification = new Set(['VERIFIED', 'PARTIAL']);
const validPosition = new Set(['GOL', 'ZAG', 'LD', 'LE', 'ALD', 'ALE', 'VOL', 'MC', 'MEI', 'MD', 'ME', 'PD', 'PE', 'SA', 'ATA']);
const validRole = new Set(['PRIMARY', 'CORROBORATING', 'CORRECTION']);

for (const a of appearances) {
  if (!a.canonicalMatchId) errors.push(`${a.canonicalName}/${a.lineupMatchId}: sem canonicalMatchId.`);
  if (!validStatus.has(a.participationStatus)) errors.push(`${a.canonicalName}/${a.lineupMatchId}: participation_status inválido "${a.participationStatus}".`);
  if (!validVerification.has(a.verificationStatus)) errors.push(`${a.canonicalName}/${a.lineupMatchId}: verification_status inválido "${a.verificationStatus}".`);
  if (a.positionCode != null && !validPosition.has(a.positionCode)) errors.push(`${a.canonicalName}/${a.lineupMatchId}: position_code inválido "${a.positionCode}".`);
  if (a.shirtNumber != null && !(Number.isInteger(a.shirtNumber) && a.shirtNumber > 0)) errors.push(`${a.canonicalName}/${a.lineupMatchId}: shirt_number inválido "${a.shirtNumber}".`);
}
for (const s of sources) {
  if (!validRole.has(s.sourceRole)) errors.push(`Source ${s.canonicalName || s.personId}/${s.sourceType}:${s.sourceRef}: source_role inválido "${s.sourceRole}".`);
}
const seenKey = new Set();
for (const a of appearances) {
  const key = `${a.personId}|${a.clubSlug}|${a.canonicalMatchId}`;
  if (seenKey.has(key)) errors.push(`Chave (person, club, match) duplicada: ${key}`);
  seenKey.add(key);
}
if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }
function sqlText(s) { return s === null || s === undefined ? 'null' : sqlString(s); }
function sqlInt(n) { return n === null || n === undefined ? 'null' : String(n); }
function sqlJsonb(v) { return `${sqlString(JSON.stringify(v))}::jsonb`; }
function sqlUuid(s) { return s === null || s === undefined ? 'null::uuid' : `${sqlString(s)}::uuid`; }

const sortedAppearances = [...appearances].sort((a, b) => a.canonicalName.localeCompare(b.canonicalName) || a.lineupMatchId.localeCompare(b.lineupMatchId));
const appearanceKey = (a) => `${a.personId}|${a.clubSlug}|${a.canonicalMatchId}`;
const sortedSources = [...sources].sort((a, b) => {
  const na = appearances.find((x) => appearanceKey(x) === `${a.personId}|${a.clubSlug}|${a.canonicalMatchId}`)?.canonicalName || '';
  const nb = appearances.find((x) => appearanceKey(x) === `${b.personId}|${b.clubSlug}|${b.canonicalMatchId}`)?.canonicalName || '';
  return na.localeCompare(nb) || a.sourceType.localeCompare(b.sourceType) || a.sourceRef.localeCompare(b.sourceRef);
});

const header = `-- ============================================================================
-- Seed de \`public.player_match_appearances\` +
-- \`public.player_match_appearance_sources\` — SOMENTE Goiás, SOMENTE
-- pessoas já em \`public.people\` (96 APPROVED), SOMENTE a partir de
-- lineup_matches.json (a única fonte de participação por partida — ver
-- player_match_appearances_seed_stats.json pra auditoria completa,
-- incluindo a limitação real do Worker documentada em workerLimitation).
--
-- GERADA por tooling/multiclub/generate_player_match_appearances_seed.mjs
-- a partir de tooling/multiclub/build_player_match_appearances_seed.mjs —
-- NUNCA editar à mão.
--
-- TODA linha aqui é participation_status='STARTED' — lineup_matches
-- representa SOMENTE a escalação titular (11 por partida, confirmado por
-- auditoria), nunca reserva/substituição. NÃO é uma limitação escondida:
-- é a semântica real e única desta fonte.
--
-- Este seed NÃO tenta cobrir os ~400 jogos do baseline agregado do Tadeu
-- (player_club_stats) nem de ninguém — cobertura é parcial de propósito
-- (qualidade > quantidade). O baseline snapshot continua sendo a fonte
-- pro "passado desconhecido"; estas linhas são só as partidas
-- especificamente evidenciadas por lineup_matches.
--
-- canonical_match_id é um UUID LITERAL (do match registry, resolvido em
-- build_matches_seed.mjs) — nenhum JOIN necessário. spell_id, quando
-- presente, já é um UUID real de player_club_spells — reforçado pela FK
-- composta do schema (spell_id, person_id, club_id).
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.player_match_appearances (person_id, club_id, canonical_match_id, spell_id, participation_status, position_code, shirt_number, verification_status)
select v.person_id, c.id, v.canonical_match_id, v.spell_id, v.participation_status, v.position_code, v.shirt_number, v.verification_status
from (
  values
`;

const appearanceValuesLines = sortedAppearances.map((a, i) => {
  const comma = i === sortedAppearances.length - 1 ? '' : ',';
  return `    (${sqlUuid(a.personId)}, ${sqlString(a.clubSlug)}, ${sqlUuid(a.canonicalMatchId)}, ${sqlUuid(a.spellId)}, ${sqlString(a.participationStatus)}, ${sqlText(a.positionCode)}, ${sqlInt(a.shirtNumber)}, ${sqlString(a.verificationStatus)})${comma}`;
});

const midSection = `
) as v(person_id, club_slug, canonical_match_id, spell_id, participation_status, position_code, shirt_number, verification_status)
left join public.clubs c on c.slug = v.club_slug
on conflict (person_id, club_id, canonical_match_id) do nothing;

insert into public.player_match_appearance_sources (player_match_appearance_id, source_type, source_ref, raw_value, source_role, observed_at)
select pma.id, v.source_type, v.source_ref, v.raw_value, v.source_role, v.observed_at
from (
  values
`;

const sourceValuesLines = sortedSources.map((s, i) => {
  const comma = i === sortedSources.length - 1 ? '' : ',';
  return `    (${sqlUuid(s.personId)}, ${sqlString(s.clubSlug)}, ${sqlUuid(s.canonicalMatchId)}, ${sqlString(s.sourceType)}, ${sqlString(s.sourceRef)}, ${sqlJsonb(s.rawValue)}, ${sqlString(s.sourceRole)}, ${sqlText(s.observedAt)}::date)${comma}`;
});

const footer = `
) as v(person_id, club_slug, canonical_match_id, source_type, source_ref, raw_value, source_role, observed_at)
left join public.clubs c on c.slug = v.club_slug
join public.player_match_appearances pma
  on pma.person_id = v.person_id and pma.club_id = c.id and pma.canonical_match_id = v.canonical_match_id
on conflict (player_match_appearance_id, source_type, source_ref) do nothing;
`;

const sql = header + appearanceValuesLines.join('\n') + midSection + sourceValuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

console.log(JSON.stringify({
  migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'),
  appearanceRows: sortedAppearances.length,
  sourceRows: sortedSources.length,
  distinctPeople: new Set(sortedAppearances.map((a) => a.personId)).size,
}, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
