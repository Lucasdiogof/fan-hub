// Transforma player_positions_seed.json + player_position_sources_seed
// .json numa migration SQL determinística.
//
// player_positions.id usa DEFAULT gen_random_uuid() — a chave natural
// (person_id, club_id, spell_id, position_code) é genuinamente estável
// (position_code é catálogo fechado, nunca refinado), então
// player_position_sources resolve por JOIN nessa chave, nunca um UUID
// pré-computado — mesma estratégia "Opção B" de person_alias_sources.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { CANONICAL_POSITIONS } from './position_catalog.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATION_PATH = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902070000_seed_goias_player_positions.sql');

const positions = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_positions_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_position_sources_seed.json'), 'utf8'));

const errors = [];
const validPositions = new Set(CANONICAL_POSITIONS);
const validVerification = new Set(['VERIFIED', 'PARTIAL']);
const validEvidence = new Set(['PRIMARY', 'CORROBORATING']);
for (const p of positions) {
  if (!validPositions.has(p.positionCode)) errors.push(`${p.canonicalName}: position_code inválido "${p.positionCode}".`);
  if (!validVerification.has(p.verificationStatus)) errors.push(`${p.canonicalName}: verification_status inválido "${p.verificationStatus}".`);
  if (!(p.positionOrder > 0)) errors.push(`${p.canonicalName}: position_order inválido "${p.positionOrder}".`);
}
for (const s of sources) {
  if (!validEvidence.has(s.evidenceType)) errors.push(`Source de ${s.personId}/${s.positionCode}: evidence_type inválido "${s.evidenceType}".`);
}
// nenhum (person_id, club_id, position_code) duplicado, nenhuma ordem duplicada
const seenCode = new Set();
const seenOrder = new Set();
for (const p of positions) {
  const codeKey = `${p.personId}|${p.clubSlug}|${p.positionCode}`;
  const orderKey = `${p.personId}|${p.clubSlug}|${p.positionOrder}`;
  if (seenCode.has(codeKey)) errors.push(`Duplicata de código: ${codeKey}`);
  if (seenOrder.has(orderKey)) errors.push(`Duplicata de position_order: ${orderKey}`);
  seenCode.add(codeKey);
  seenOrder.add(orderKey);
}
if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }
function sqlBool(b) { return b ? 'true' : 'false'; }
function sqlText(s) { return s === null || s === undefined ? 'null' : sqlString(s); }

const sortedPositions = [...positions].sort((a, b) => a.canonicalName.localeCompare(b.canonicalName) || a.positionOrder - b.positionOrder);
const sortedSources = [...sources].sort((a, b) => {
  const na = positions.find((p) => p.personId === a.personId && p.positionCode === a.positionCode)?.canonicalName || '';
  const nb = positions.find((p) => p.personId === b.personId && p.positionCode === b.positionCode)?.canonicalName || '';
  return na.localeCompare(nb) || a.positionCode.localeCompare(b.positionCode) || a.sourceType.localeCompare(b.sourceType) || a.sourceRef.localeCompare(b.sourceRef) || (a.matchId || '').localeCompare(b.matchId || '');
});

const header = `-- ============================================================================
-- Seed de \`public.player_positions\` + \`public.player_position_sources\` —
-- SOMENTE Goiás, SOMENTE pessoas já em \`public.people\` (96 APPROVED),
-- SOMENTE onde existe evidência resolvível (ver
-- player_positions_seed_stats.json pra auditoria completa — pessoas sem
-- evidência ficam de fora, nenhum lado D/E é adivinhado).
--
-- GERADA por tooling/multiclub/generate_player_positions_seed.mjs a
-- partir de tooling/multiclub/build_player_positions_seed.mjs — NUNCA
-- editar à mão.
--
-- Fonte-ouro: lib/features/crowd_lineup/domain/goias_squad.dart (lista
-- humana curada e ordenada) — onde existe, position_order reflete essa
-- ordem exatamente. Sem ela, position_order é só frequência entre fontes
-- (verification_status=PARTIAL nesses casos).
--
-- spell_id sempre NULL nesta leva — nenhuma fonte atual dá posição no
-- grão de spell.
--
-- player_position_id em player_position_sources é resolvido por JOIN na
-- chave natural (person_id, club_id, position_code), nunca um UUID
-- pré-computado.
--
-- Idempotência: ON CONFLICT DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.player_positions (person_id, club_id, spell_id, position_code, position_order, verification_status)
select v.person_id, c.id, null, v.position_code, v.position_order, v.verification_status
from (
  values
`;

const positionValuesLines = sortedPositions.map((p, i) => {
  const comma = i === sortedPositions.length - 1 ? '' : ',';
  return `    (${sqlString(p.personId)}::uuid, ${sqlString(p.clubSlug)}, ${sqlString(p.positionCode)}, ${p.positionOrder}, ${sqlString(p.verificationStatus)})${comma}`;
});

const midSection = `
) as v(person_id, club_slug, position_code, position_order, verification_status)
join public.clubs c on c.slug = v.club_slug
on conflict (person_id, club_id, spell_id, position_code) do nothing;

insert into public.player_position_sources (player_position_id, source_type, source_ref, raw_value, match_id, observed_at, evidence_type, notes)
select pp.id, v.source_type, v.source_ref, v.raw_value, v.match_id, v.observed_at, v.evidence_type, v.notes
from (
  values
`;

const sourceValuesLines = sortedSources.map((s, i) => {
  const comma = i === sortedSources.length - 1 ? '' : ',';
  return `    (${sqlString(s.personId)}::uuid, ${sqlString(s.clubSlug)}, ${sqlString(s.positionCode)}, ${sqlString(s.sourceType)}, ${sqlString(s.sourceRef)}, ${sqlString(s.rawValue)}, ${sqlText(s.matchId)}, ${sqlText(s.observedAt)}::date, ${sqlString(s.evidenceType)}, ${sqlText(s.notes)})${comma}`;
});

const footer = `
) as v(person_id, club_slug, position_code, source_type, source_ref, raw_value, match_id, observed_at, evidence_type, notes)
join public.clubs c on c.slug = v.club_slug
join public.player_positions pp
  on pp.person_id = v.person_id and pp.club_id = c.id and pp.position_code = v.position_code and pp.spell_id is null
on conflict (player_position_id, source_type, source_ref, match_id) do nothing;
`;

const sql = header + positionValuesLines.join('\n') + midSection + sourceValuesLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

console.log(JSON.stringify({
  migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'),
  positionRows: sortedPositions.length,
  sourceRows: sortedSources.length,
  distinctPeople: new Set(sortedPositions.map((p) => p.personId)).size,
}, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
