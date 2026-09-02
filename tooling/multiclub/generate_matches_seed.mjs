// Transforma matches_seed.json + match_source_refs_seed.json numa migration
// SQL determinística. matches.id é literal (do match registry) — idempotência
// via ON CONFLICT (id) DO NOTHING. match_source_refs também usa o matchId
// literal diretamente (nenhum JOIN necessário — o id já é conhecido no
// momento da geração, ao contrário do design anterior que dependia de
// gen_random_uuid() + JOIN por lineup_match_id).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { kickoffIntervalDays } from './kickoff_precision.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATION_PATH = path.join(ROOT, 'supabase', 'migrations', '20260902110000_seed_goias_matches.sql');

const matches = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'matches_seed.json'), 'utf8'));
const sourceRefs = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'match_source_refs_seed.json'), 'utf8'));

const errors = [];
const validPrecision = new Set(['YEAR', 'MONTH', 'DATE', 'DATETIME']);
const validVerification = new Set(['VERIFIED', 'PARTIAL']);
const validSourceType = new Set(['LINEUP_MATCH', 'PASSPORT_MATCH', 'PROVIDER_FIXTURE']);
for (const m of matches) {
  if (!m.matchId) errors.push(`${m.lineupMatchId}: sem matchId (registry não resolveu).`);
  if (!m.homeClubSlug && !m.awayClubSlug) errors.push(`${m.lineupMatchId}: nenhum lado é Goiás.`);
  if (!validVerification.has(m.verificationStatus)) errors.push(`${m.lineupMatchId}: verification_status inválido.`);
  if (!validPrecision.has(m.kickoffPrecision)) errors.push(`${m.lineupMatchId}: kickoff_precision inválido "${m.kickoffPrecision}".`);
  if (m.kickoffPrecision === 'DATETIME' && !m.kickoffAt) errors.push(`${m.lineupMatchId}: precision DATETIME sem kickoff_at.`);
  if (m.kickoffPrecision !== 'DATETIME' && m.kickoffAt) errors.push(`${m.lineupMatchId}: kickoff_at preenchido sem precision DATETIME.`);
  if (m.kickoffPrecision === 'YEAR' && m.kickoffMonth != null) errors.push(`${m.lineupMatchId}: precision YEAR não pode ter kickoff_month preenchido.`);
  if (m.kickoffPrecision !== 'YEAR' && m.kickoffMonth == null) errors.push(`${m.lineupMatchId}: precision ${m.kickoffPrecision} exige kickoff_month preenchido.`);
  const dateRequired = m.kickoffPrecision === 'DATE' || m.kickoffPrecision === 'DATETIME';
  if (dateRequired && !m.kickoffDate) errors.push(`${m.lineupMatchId}: precision ${m.kickoffPrecision} exige kickoff_date preenchido.`);
  if (!dateRequired && m.kickoffDate != null) errors.push(`${m.lineupMatchId}: precision ${m.kickoffPrecision} NÃO pode ter kickoff_date preenchido (nunca um sentinela).`);
}
const seenMatchIds = new Set();
for (const m of matches) {
  if (seenMatchIds.has(m.matchId)) errors.push(`matchId duplicado no seed: ${m.matchId} (${m.lineupMatchId})`);
  seenMatchIds.add(m.matchId);
}
for (const s of sourceRefs) {
  if (!validSourceType.has(s.sourceType)) errors.push(`source_type inválido "${s.sourceType}" (match ${s.matchId}).`);
  if (!s.sourceNamespace) errors.push(`source_ref sem source_namespace (match ${s.matchId}, ref ${s.sourceRef}).`);
  if (!seenMatchIds.has(s.matchId)) errors.push(`match_source_refs aponta pra matchId desconhecido no seed: ${s.matchId}.`);
}
const seenRefKey = new Set();
for (const s of sourceRefs) {
  const key = `${s.sourceNamespace}|${s.sourceRef}`;
  if (seenRefKey.has(key)) errors.push(`(source_namespace, source_ref) duplicado: ${key}`);
  seenRefKey.add(key);
}
if (errors.length) {
  console.error('ERROS — SEED NÃO GERADO:');
  for (const e of errors) console.error(' -', e);
  process.exit(1);
}

function sqlString(s) { return `'${String(s).replace(/'/g, "''")}'`; }
function sqlText(s) { return s === null || s === undefined ? 'null' : sqlString(s); }
function sqlInt(n) { return n === null || n === undefined ? 'null' : String(n); }
function sqlUuid(s) { return s === null || s === undefined ? 'null::uuid' : `${sqlString(s)}::uuid`; }
function sqlTimestamptz(s) { return s === null || s === undefined ? 'null' : `${sqlString(s)}::timestamptz`; }
function sqlDate(s) { return s === null || s === undefined ? 'null::date' : `${sqlString(s)}::date`; }

// Ordenação cronológica com precisão MISTA — nunca dependente de
// kickoff_date (agora NULL em YEAR/MONTH). Usa o INÍCIO do intervalo real
// de cada precisão (tooling/multiclub/kickoff_precision.mjs), com
// lineupMatchId como desempate estável e determinístico.
const sortedMatches = [...matches].sort((a, b) => {
  const [aStart] = kickoffIntervalDays({ precision: a.kickoffPrecision, year: a.kickoffYear, month: a.kickoffMonth, date: a.kickoffDate, at: a.kickoffAt });
  const [bStart] = kickoffIntervalDays({ precision: b.kickoffPrecision, year: b.kickoffYear, month: b.kickoffMonth, date: b.kickoffDate, at: b.kickoffAt });
  return aStart - bStart || a.lineupMatchId.localeCompare(b.lineupMatchId);
});
const matchIdOf = (m) => m.matchId;
const sortedSourceRefs = [...sourceRefs].sort((a, b) => {
  const na = matches.find((x) => matchIdOf(x) === a.matchId)?.lineupMatchId || '';
  const nb = matches.find((x) => matchIdOf(x) === b.matchId)?.lineupMatchId || '';
  return na.localeCompare(nb) || a.sourceNamespace.localeCompare(b.sourceNamespace) || a.sourceRef.localeCompare(b.sourceRef);
});

const header = `-- ============================================================================
-- Seed de \`public.matches\` + \`public.match_source_refs\` — SOMENTE as 31
-- partidas de lineup_matches.json (Adivinhe a Escalação), a única fonte
-- histórica curada de escalação que este projeto tem hoje. GERADA por
-- tooling/multiclub/generate_matches_seed.mjs a partir de
-- tooling/multiclub/build_matches_seed.mjs — NUNCA editar à mão.
--
-- matches.id é LITERAL, do match registry (tooling/multiclub/matches_
-- registry.json) — nunca gen_random_uuid(). match_source_refs também usa
-- o matchId literal direto, sem JOIN.
--
-- kickoff_date é NULL quando kickoff_precision IN ('YEAR','MONTH') — NUNCA
-- um sentinela "YYYY-01-01"/"YYYY-MM-01" persistido. Ordenação desta
-- migration usa o início do intervalo real de cada precisão (ver
-- kickoff_precision.mjs), nunca a coluna kickoff_date sozinha.
--
-- passport_match_id linkado (via match_source_refs, source_namespace=
-- 'goias_passport') só quando existe candidato ÚNICO em passport_matches
-- por (data, oponente) — ver match_identity_audit.json e matches_seed_
-- stats.json (blockedAmbiguousMatch) pros casos com 2+ candidatos, nunca
-- linkados automaticamente.
--
-- Idempotência: ON CONFLICT (id) DO NOTHING nas duas tabelas.
-- ============================================================================

insert into public.matches (
  id, home_club_id, away_club_id, home_team_name, away_team_name,
  kickoff_year, kickoff_month, kickoff_date, kickoff_at, kickoff_precision,
  competition, season, home_score, away_score, verification_status, data_notes
)
select v.id, hc.id, ac.id, v.home_team_name, v.away_team_name,
       v.kickoff_year, v.kickoff_month, v.kickoff_date, v.kickoff_at, v.kickoff_precision,
       v.competition, v.season, v.home_score, v.away_score, v.verification_status, v.data_notes
from (
  values
`;

const valuesLines = sortedMatches.map((m, i) => {
  const comma = i === sortedMatches.length - 1 ? '' : ',';
  return `    (${sqlUuid(m.matchId)}, ${sqlText(m.homeClubSlug)}, ${sqlText(m.awayClubSlug)}, ${sqlString(m.homeTeamName)}, ${sqlString(m.awayTeamName)}, ${sqlInt(m.kickoffYear)}, ${sqlInt(m.kickoffMonth)}, ${sqlDate(m.kickoffDate)}, ${sqlTimestamptz(m.kickoffAt)}, ${sqlString(m.kickoffPrecision)}, ${sqlText(m.competition)}, ${sqlText(m.season)}, ${sqlInt(m.homeScore)}, ${sqlInt(m.awayScore)}, ${sqlString(m.verificationStatus)}, ${sqlText(m.dataNotes)})${comma}`;
});

const midSection = `
) as v(id, home_club_slug, away_club_slug, home_team_name, away_team_name, kickoff_year, kickoff_month, kickoff_date, kickoff_at, kickoff_precision, competition, season, home_score, away_score, verification_status, data_notes)
left join public.clubs hc on hc.slug = v.home_club_slug
left join public.clubs ac on ac.slug = v.away_club_slug
on conflict (id) do nothing;

insert into public.match_source_refs (match_id, source_type, source_namespace, source_ref, source_club_id)
values
`;

const sourceRefLines = sortedSourceRefs.map((s, i) => {
  const comma = i === sortedSourceRefs.length - 1 ? '' : ',';
  // source_club_id já é um UUID literal resolvido pelo build script
  // (matches.id e o clube goias já são conhecidos nesse ponto — nenhum
  // JOIN necessário, ao contrário do padrão de resolução por slug usado
  // noutras tabelas).
  return `  (${sqlUuid(s.matchId)}, ${sqlString(s.sourceType)}, ${sqlString(s.sourceNamespace)}, ${sqlString(s.sourceRef)}, ${sqlUuid(s.sourceClubId)})${comma}`;
});

const footer = `
on conflict (source_namespace, source_ref) do nothing;
`;

const sql = header + valuesLines.join('\n') + midSection + sourceRefLines.join('\n') + footer;

fs.mkdirSync(path.dirname(MIGRATION_PATH), { recursive: true });
fs.writeFileSync(MIGRATION_PATH, sql);

console.log(JSON.stringify({ migrationFile: path.relative(ROOT, MIGRATION_PATH).replace(/\\/g, '/'), matchRows: sortedMatches.length, sourceRefRows: sortedSourceRefs.length }, null, 2));
console.log('\nSQL escrito em:', MIGRATION_PATH);
