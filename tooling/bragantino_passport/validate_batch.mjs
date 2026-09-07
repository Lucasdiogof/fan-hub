// Validação reutilizável de um lote do Passaporte do Bragantino — roda
// contra o JSON fonte (tooling/bragantino_passport/source/) e a SQL gerada
// (supabase/), sem tocar em nada remoto. Uso: node validate_batch.mjs 2026
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const year = process.argv[2];
if (!year) {
  console.error('Uso: node validate_batch.mjs <ano>');
  process.exit(1);
}

const jsonPath = path.join(ROOT, 'tooling/bragantino_passport/source', `bragantino_passport_${year}.json`);
const sqlPath = path.join(ROOT, 'supabase', `bragantino_passport_matches_${year}_seed.sql`);

const wrapper = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const rows = wrapper.matches;
const sql = fs.readFileSync(sqlPath, 'utf8');

let failed = 0;
function check(name, cond) {
  console.log(`${cond ? 'PASS' : 'FAIL'} — ${name}`);
  if (!cond) failed++;
}

check('JSON parseável', Array.isArray(rows) && rows.length > 0);
check('SQL não vazio e termina com ";"', sql.trim().endsWith(';'));

const ids = rows.map((r) => r.id);
check(`IDs únicos (${rows.length})`, new Set(ids).size === ids.length);

const sourceMatchIds = rows.map((r) => r.source_match_id);
check('source_match_id únicos (nenhuma partida duplicada da fonte)', new Set(sourceMatchIds).size === sourceMatchIds.length);

const validDates = rows.every((r) => /^\d{4}-\d{2}-\d{2}$/.test(r.date) && !Number.isNaN(Date.parse(r.date)));
check('todas as datas válidas (YYYY-MM-DD parseável)', validDates);

const validYear = rows.every((r) => String(r.calendar_year) === String(year));
check(`todas as partidas com calendar_year=${year}`, validYear);

const scoresConsistent = rows.every((r) => {
  if (r.score_status !== 'FINISHED') return r.home_score === null && r.away_score === null;
  return (
    r.home_score !== null &&
    r.away_score !== null &&
    r.home_score >= 0 &&
    r.away_score >= 0 &&
    r.club_score === (r.club_is_home ? r.home_score : r.away_score) &&
    r.opponent_score === (r.club_is_home ? r.away_score : r.home_score)
  );
});
check('placares válidos e consistentes (club_score/opponent_score batem com mandante/visitante)', scoresConsistent);

const outcomeConsistent = rows.every((r) => {
  if (r.score_status !== 'FINISHED') return r.outcome === null;
  if (r.club_score > r.opponent_score) return r.outcome === 'WIN';
  if (r.club_score < r.opponent_score) return r.outcome === 'LOSS';
  return r.outcome === 'DRAW';
});
check('outcome (WIN/DRAW/LOSS) consistente com o placar', outcomeConsistent);

const CLUB_NAMES = ['RB Bragantino', 'Bragantino', 'Red Bull Bragantino', 'Clube Atlético Bragantino', 'Atlético Bragantino'];
const homeAwayConsistent = rows.every((r) => {
  const homeIsClub = CLUB_NAMES.includes(r.home_team);
  const awayIsClub = CLUB_NAMES.includes(r.away_team);
  return r.club_is_home ? homeIsClub && !awayIsClub : awayIsClub && !homeIsClub;
});
check('mandante/visitante consistente (o Bragantino aparece no lado certo em toda partida)', homeAwayConsistent);

// Evidência de estádio em 3 níveis, iguais aos do banco: MATCH_SPECIFIC
// (a ficha da partida diz), HISTORICAL_RECONSTRUCTION (deduzido de contexto
// histórico, com fonte, mas não confirmado na ficha) e UNKNOWN (não se sabe,
// `stadium` fica null). 'NEEDS_SOURCE' é o nome antigo de UNKNOWN.
const EVIDENCE_STATUS = ['MATCH_SPECIFIC', 'HISTORICAL_RECONSTRUCTION'];
const isUnknown = (r) => r.stadium_status === 'UNKNOWN' || r.stadium_status === 'NEEDS_SOURCE';

const stadiumRuleRespected = rows.every((r) => (r.stadium ? EVIDENCE_STATUS.includes(r.stadium_status) : isUnknown(r)));
check('regra crítica de estádio respeitada (nunca stadium preenchido sem evidência, nem evidência sem stadium)', stadiumRuleRespected);

const noInventedStadium = rows.every((r) => !EVIDENCE_STATUS.includes(r.stadium_status) || (r.source_url && r.source_match_id));
check('todo estádio com evidência tem fonte rastreável (source_url + source_match_id)', noInventedStadium);

const openParens = (sql.match(/\(/g) || []).length;
const closeParens = (sql.match(/\)/g) || []).length;
check('parênteses balanceados na SQL gerada', openParens === closeParens);

// Contrato compartilhado com o Goiás (tabela `passport_matches`, mesmo
// nome — o isolamento é o projeto Supabase, não um nome de tabela por
// clube). Ver bragantino_passport_matches.sql.
check('SQL insere em public.passport_matches (nome compartilhado com o Goiás, NÃO bragantino_passport_matches)', /insert into public\.passport_matches\b/.test(sql));
const insertedRowsCount = (sql.match(/^\s*\('pb_\w+_/gm) || []).length;
check(`SQL tem exatamente ${rows.length} linhas de INSERT (nenhuma partida perdida na regeneração)`, insertedRowsCount === rows.length);

console.log(`\n${failed === 0 ? 'TODAS AS VALIDAÇÕES PASSARAM' : `${failed} VALIDAÇÃO(ÕES) FALHARAM`}`);
process.exit(failed === 0 ? 0 : 1);
