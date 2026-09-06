// Validação do LINEUP_SHORTLIST_V2 — roda só contra o JSON já gerado
// (tooling/bragantino_passport/source/lineup_shortlist_v2.json), sem
// tocar em nada remoto. Uso: node validate_lineup_shortlist.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const jsonPath = path.join(ROOT, 'tooling/bragantino_passport/source/lineup_shortlist_v2.json');

const wrapper = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const candidates = wrapper.candidates;

let failed = 0;
function check(name, cond) {
  console.log(`${cond ? 'PASS' : 'FAIL'} — ${name}`);
  if (!cond) failed++;
}

check('JSON parseável e com candidatos', Array.isArray(candidates) && candidates.length > 0);

const ids = candidates.map((c) => c.source_match_id);
check(`source_match_id únicos (${candidates.length})`, new Set(ids).size === ids.length);

const allElevenStarters = candidates.every((c) => c.starting_xi.length === 11);
check('todo candidato tem exatamente 11 titulares', allElevenStarters);

const noShirtDuplicates = candidates.every((c) => {
  const numbers = c.starting_xi.map((p) => p.number);
  return new Set(numbers).size === 11;
});
check('nenhum candidato tem camisa duplicada no onze', noShirtDuplicates);

const noNameDuplicates = candidates.every((c) => {
  const names = c.starting_xi.map((p) => p.name);
  return new Set(names).size === 11;
});
check('nenhum candidato tem nome duplicado no onze', noNameDuplicates);

const validShirtRange = candidates.every((c) =>
  c.starting_xi.every((p) => p.number >= 1 && p.number <= 99),
);
check('todas as camisas em faixa válida (1-99)', validShirtRange);

const validDates = candidates.every(
  (c) => /^\d{4}-\d{2}-\d{2}$/.test(c.date) && !Number.isNaN(Date.parse(c.date)),
);
check('todas as datas válidas (YYYY-MM-DD parseável)', validDates);

const hasSource = candidates.every((c) => c.source_url && c.source_match_id);
check('todo candidato tem fonte rastreável (source_url + source_match_id)', hasSource);

const captainsPresent = candidates.some((c) => c.starting_xi.some((p) => p.captain));
check('pelo menos 1 candidato com capitão identificado', captainsPresent);

console.log(`\n${failed === 0 ? 'TODAS AS VALIDAÇÕES PASSARAM' : `${failed} VALIDAÇÃO(ÕES) FALHARAM`}`);
console.log(`\nResumo: ${JSON.stringify(wrapper.summary)}`);
process.exit(failed === 0 ? 0 : 1);
