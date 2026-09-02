// Modela kickoff de partida como INTERVALO temporal, nunca como uma data
// única fabricada quando a precisão real é mais grosseira. Usado tanto pelo
// resolver estrutural de partida (match_registry.mjs, etapa 2 — comparação
// por atributos) quanto pelo baseline+delta (recompute_player_club_stats.
// mjs) — os dois precisam saber se 2 kickoffs de precisão DIFERENTE podem
// ser a MESMA partida / se um está antes ou depois do outro, sem
// depender de nenhum "dia 1º de janeiro" sentinela persistido em lugar
// nenhum (isso foi removido do schema — ver matches.kickoff_date agora
// NULLABLE).
//
// Formato canônico de kickoff usado por todo o resto do código:
//   { precision: 'YEAR'|'MONTH'|'DATE'|'DATETIME', year, month, date, at }
// `date` é uma string ISO 'YYYY-MM-DD' (só quando precision é DATE/DATETIME,
// null caso contrário). `at` é uma string ISO datetime (só quando
// precision='DATETIME', null caso contrário). `month` é null quando
// precision='YEAR'.

const VALID_PRECISIONS = ['YEAR', 'MONTH', 'DATE', 'DATETIME'];

function assertValidKickoff(k) {
  if (!k || !VALID_PRECISIONS.includes(k.precision)) throw new Error(`kickoff inválido: precision "${k?.precision}"`);
  if (k.precision === 'YEAR' && (k.month != null || k.date != null || k.at != null)) throw new Error('precision=YEAR não pode ter month/date/at preenchidos');
  if (k.precision === 'MONTH' && (k.month == null || k.date != null || k.at != null)) throw new Error('precision=MONTH exige month e proíbe date/at');
  if (k.precision === 'DATE' && (k.date == null || k.at != null)) throw new Error('precision=DATE exige date e proíbe at');
  if (k.precision === 'DATETIME' && (k.date == null || k.at == null)) throw new Error('precision=DATETIME exige date E at');
  if (k.year == null) throw new Error('kickoff sem year');
}

function daysInMonth(year, month) { return new Date(Date.UTC(year, month, 0)).getUTCDate(); }
function toEpochDay(y, m, d) { return Math.floor(Date.UTC(y, m - 1, d) / 86400000); }

/** Converte um kickoff (em qualquer precisão) no MENOR intervalo [inicio,
 * fim] (em "dia desde epoch", inclusive nos dois lados) que contém todo
 * instante compatível com o que a fonte realmente sabe. YEAR -> o ano
 * inteiro. MONTH -> o mês inteiro. DATE/DATETIME -> só aquele dia (o
 * horário exato, quando existe, é usado separado pra desempate — ver
 * compareKickoffBoundary). Nunca fabrica um dia — o intervalo É a honestidade
 * sobre o que se sabe, ao contrário de um kickoff_date sentinela. */
export function kickoffIntervalDays(k) {
  assertValidKickoff(k);
  if (k.precision === 'YEAR') return [toEpochDay(k.year, 1, 1), toEpochDay(k.year, 12, 31)];
  if (k.precision === 'MONTH') return [toEpochDay(k.year, k.month, 1), toEpochDay(k.year, k.month, daysInMonth(k.year, k.month))];
  const [y, m, d] = k.date.split('-').map(Number);
  return [toEpochDay(y, m, d), toEpochDay(y, m, d)];
}

/** Dois kickoffs (precisão igual ou diferente) representam POSSIVELMENTE a
 * mesma janela de tempo se os intervalos se sobrepõem — usado pelo
 * resolver estrutural (etapa 2) pra decidir se 2 partidas de fontes
 * diferentes, sem anchor em comum, podem ser a mesma. Sobreposição não é
 * prova (por isso o resolver também exige identidade de clube batendo) —
 * só uma condição necessária, nunca suficiente sozinha. */
export function kickoffIntervalsOverlap(a, b) {
  const [aS, aE] = kickoffIntervalDays(a);
  const [bS, bE] = kickoffIntervalDays(b);
  return aS <= bE && bS <= aE;
}

/** Compara um candidate contra um boundary de referência (ex.: o
 * as_of_date/as_of_match_id de um baseline de player_club_stats) — usado
 * pelo baseline+delta (item 7). Nunca assume que toda partida tem data
 * exata; trabalha com o intervalo real de cada precisão.
 *
 * Retorna um destes 4 vereditos, nunca decide "por conta própria" quando
 * os intervalos se cruzam sem uma forma segura de desempate:
 *  - 'BEFORE'    -> intervalo do candidate termina antes do intervalo do
 *                   baseline começar — estritamente anterior, nunca soma.
 *  - 'AFTER'     -> intervalo do candidate começa depois do intervalo do
 *                   baseline terminar (OU, no caso de dia idêntico com
 *                   horário confiável dos 2 lados, o instante do candidate
 *                   é posterior) — soma.
 *  - 'AMBIGUOUS' -> os intervalos se sobrepõem (partida de precisão coarse
 *                   cruzando a fronteira do baseline, ou mesmo dia sem
 *                   horário confiável dos 2 lados) — NUNCA resolvido
 *                   sozinho, fica de fora do delta automático.
 *  - 'SAME'      -> mesmo instante/dia com horário igual (ou o próprio
 *                   match do baseline) — nunca soma de novo.
 */
export function compareKickoffBoundary(candidateKickoff, baselineKickoff) {
  const [cS, cE] = kickoffIntervalDays(candidateKickoff);
  const [bS, bE] = kickoffIntervalDays(baselineKickoff);
  if (cE < bS) return 'BEFORE';
  if (cS > bE) return 'AFTER';
  // intervalos se sobrepõem — só decide sozinho se os 2 lados forem um
  // ÚNICO dia (DATE/DATETIME, nunca YEAR/MONTH) E ambos tiverem horário
  // confiável (DATETIME) pra desempate real.
  const sameDayOnly = cS === cE && bS === bE && cS === bS;
  if (sameDayOnly && candidateKickoff.precision === 'DATETIME' && baselineKickoff.precision === 'DATETIME') {
    if (candidateKickoff.at === baselineKickoff.at) return 'SAME';
    return candidateKickoff.at > baselineKickoff.at ? 'AFTER' : 'BEFORE';
  }
  return 'AMBIGUOUS';
}
