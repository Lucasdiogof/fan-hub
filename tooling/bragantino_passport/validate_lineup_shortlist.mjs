// Validação do LINEUP_SHORTLIST_V2 — roda só contra o JSON já gerado
// (tooling/bragantino_passport/source/lineup_shortlist_v2.json), sem
// tocar em nada remoto. Uso: node validate_lineup_shortlist.mjs
//
// Duas categorias: RECENT_LINEUPS (auto-extraído, já populado) e
// HISTORICAL_LINEUPS (exige pesquisa própria, pode estar vazio/
// PENDING_RESEARCH — isso não é falha de validação, só reflete o estado
// real da pesquisa).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const jsonPath = path.join(ROOT, 'tooling/bragantino_passport/source/lineup_shortlist_v2.json');

const wrapper = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const recent = wrapper.recent_lineups?.matches ?? [];
const historical = wrapper.historical_lineups?.matches ?? [];
const allMatches = [...recent, ...historical];

let failed = 0;
function check(name, cond) {
  console.log(`${cond ? 'PASS' : 'FAIL'} — ${name}`);
  if (!cond) failed++;
}

check('JSON parseável, RECENT_LINEUPS e HISTORICAL_LINEUPS presentes', Array.isArray(recent) && Array.isArray(historical));
check('RECENT_LINEUPS tem pelo menos 1 partida', recent.length > 0);
check(
  'HISTORICAL_LINEUPS vazio vem com research_status=PENDING_RESEARCH (nunca inventado só pra preencher)',
  historical.length > 0 || wrapper.historical_lineups?.research_status === 'PENDING_RESEARCH',
);

if (allMatches.length > 0) {
  const ids = allMatches.map((c) => c.source_match_id);
  check(`source_match_id únicos entre as duas categorias (${allMatches.length})`, new Set(ids).size === ids.length);

  const requiredFields = [
    'category', 'source', 'source_match_id', 'source_url', 'date', 'competition',
    'opponent', 'club_is_home', 'score_display', 'starting_xi',
  ];
  const hasAllFields = allMatches.every((c) => requiredFields.every((f) => f in c));
  check('todo registro (recente ou histórico) tem os campos obrigatórios preservados', hasAllFields);

  const allElevenStarters = allMatches.every((c) => c.starting_xi.length === 11);
  check('todo registro tem exatamente 11 titulares', allElevenStarters);

  // Registros históricos (2026-09-07) vêm sem número de camisa na fonte —
  // `number: null` em todo o XI não é "camisa duplicada", é "desconhecida"
  // (nunca inferida). Só checa duplicata quando o registro TEM números
  // reais.
  const noShirtDuplicates = allMatches.every((c) => {
    const numbers = c.starting_xi.map((p) => p.number);
    if (numbers.every((n) => n === null)) return true;
    return new Set(numbers).size === 11;
  });
  check(
    'nenhum registro COM número de camisa conhecido tem duplicata no onze',
    noShirtDuplicates,
  );

  const noNameDuplicates = allMatches.every((c) => {
    const names = c.starting_xi.map((p) => p.name);
    return new Set(names).size === 11;
  });
  check('nenhum registro tem nome duplicado no onze', noNameDuplicates);

  // Camisa desconhecida (null) é válida — só um número FORA da faixa (ex.:
  // 0 ou negativo) é erro de dado.
  const validShirtRange = allMatches.every((c) =>
    c.starting_xi.every((p) => p.number === null || (p.number >= 1 && p.number <= 99)),
  );
  check('todas as camisas conhecidas em faixa válida (1-99)', validShirtRange);

  const validDates = allMatches.every(
    (c) => /^\d{4}-\d{2}-\d{2}$/.test(c.date) && !Number.isNaN(Date.parse(c.date)),
  );
  check('todas as datas válidas (YYYY-MM-DD parseável)', validDates);

  // Registros curados de um pacote consolidado (não de uma ficha
  // individual ao vivo) legitimamente não têm `source_url` por partida —
  // `source` + `source_match_id` continuam obrigatórios sempre.
  const hasSource = allMatches.every((c) => c.source_match_id && c.source);
  check('todo registro tem fonte rastreável (source + source_match_id)', hasSource);

  const captainsPresent = allMatches.some((c) => c.starting_xi.some((p) => p.captain));
  check('pelo menos 1 registro com capitão identificado', captainsPresent);
}

console.log(`\n${failed === 0 ? 'TODAS AS VALIDAÇÕES PASSARAM' : `${failed} VALIDAÇÃO(ÕES) FALHARAM`}`);
console.log(`\nRECENT_LINEUPS: ${JSON.stringify(wrapper.recent_lineups?.summary)}`);
console.log(`HISTORICAL_LINEUPS: status=${wrapper.historical_lineups?.research_status}, partidas=${historical.length}, alvos=${wrapper.historical_lineups?.research_targets?.length ?? 0}`);
process.exit(failed === 0 ? 0 : 1);
