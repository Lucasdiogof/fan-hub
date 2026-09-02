// Parsers de período — NUNCA inventam precisão maior do que a fonte
// realmente tem. career_players usa "YYYY" / "YYYY-YYYY" / "YYYY-atual"
// (hífen ASCII, sem mês) -> precisão YEAR. squad_members usa
// "mmm/YYYY–mmm/YYYY" / "mmm/YYYY–atual" (en dash U+2013, mês abreviado
// em português) -> precisão MONTH. Nenhum dos dois parser aqui produz
// start_date/end_date (precisão DATE) — essa fonte não existe ainda no
// dataset, o campo só existe no schema pra evolução futura.
const PT_MONTHS = { jan: 1, fev: 2, mar: 3, abr: 4, mai: 5, jun: 6, jul: 7, ago: 8, set: 9, out: 10, nov: 11, dez: 12 };

/** "2000" | "2004-2005" | "2019-atual" -> {startYear,startMonth:null,endYear,endMonth:null,isOngoing,precision:'YEAR'} */
export function parseYearPeriod(period) {
  const s = String(period).trim();
  const ongoingMatch = s.match(/^(\d{4})-atual$/);
  if (ongoingMatch) {
    return { startYear: parseInt(ongoingMatch[1], 10), startMonth: null, endYear: null, endMonth: null, isOngoing: true, precision: 'YEAR' };
  }
  const rangeMatch = s.match(/^(\d{4})-(\d{4})$/);
  if (rangeMatch) {
    return { startYear: parseInt(rangeMatch[1], 10), startMonth: null, endYear: parseInt(rangeMatch[2], 10), endMonth: null, isOngoing: false, precision: 'YEAR' };
  }
  const singleMatch = s.match(/^(\d{4})$/);
  if (singleMatch) {
    const y = parseInt(singleMatch[1], 10);
    return { startYear: y, startMonth: null, endYear: y, endMonth: null, isOngoing: false, precision: 'YEAR' };
  }
  throw new Error(`parseYearPeriod: formato não reconhecido: "${period}"`);
}

/** "abr/2019–dez/2019" | "jan/2020–atual" -> {...,precision:'MONTH'} */
export function parseMonthPeriod(period) {
  const s = String(period).trim();
  const parts = s.split('–');
  if (parts.length !== 2) throw new Error(`parseMonthPeriod: esperava exatamente 1 en-dash (U+2013): "${period}"`);
  const [startRaw, endRaw] = parts;
  const startMatch = startRaw.match(/^([a-z]{3})\/(\d{4})$/i);
  if (!startMatch) throw new Error(`parseMonthPeriod: início não reconhecido: "${startRaw}"`);
  const startMonth = PT_MONTHS[startMatch[1].toLowerCase()];
  if (!startMonth) throw new Error(`parseMonthPeriod: mês não reconhecido: "${startMatch[1]}"`);
  const startYear = parseInt(startMatch[2], 10);

  if (endRaw.trim() === 'atual') {
    return { startYear, startMonth, endYear: null, endMonth: null, isOngoing: true, precision: 'MONTH' };
  }
  const endMatch = endRaw.match(/^([a-z]{3})\/(\d{4})$/i);
  if (!endMatch) throw new Error(`parseMonthPeriod: fim não reconhecido: "${endRaw}"`);
  const endMonth = PT_MONTHS[endMatch[1].toLowerCase()];
  if (!endMonth) throw new Error(`parseMonthPeriod: mês não reconhecido: "${endMatch[1]}"`);
  const endYear = parseInt(endMatch[2], 10);
  return { startYear, startMonth, endYear, endMonth, isOngoing: false, precision: 'MONTH' };
}

/** Deriva um período YEAR-precision a partir de datas ISO de partidas
 * (lineup_matches.match_date) — SEMPRE o menor invólucro possível (min/max
 * ano), nunca estende além do que as datas realmente cobrem. */
export function yearRangeFromDates(isoDates) {
  const years = isoDates.map((d) => parseInt(String(d).slice(0, 4), 10)).filter((y) => Number.isInteger(y));
  if (years.length === 0) throw new Error('yearRangeFromDates: nenhuma data válida');
  const startYear = Math.min(...years);
  const endYear = Math.max(...years);
  return { startYear, startMonth: null, endYear, endMonth: null, isOngoing: false, precision: 'YEAR' };
}
