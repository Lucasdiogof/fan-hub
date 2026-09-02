// Resolução de spell_id pra uma appearance — extraído de
// build_player_match_appearances_seed.mjs pra ser uma unidade TESTÁVEL
// isoladamente (mesmo padrão de stats_coverage.mjs: lógica pura na sua
// própria .mjs, não inline no script de build).
//
// Regra de linkage (nunca muda, independente de qualquer heurística de
// classificação/diagnóstico):
//   1 spell temporalmente compatível de forma segura -> link (spellId)
//   0                                                 -> NULL, categoria A/B/C
//   2+                                                -> NULL, categoria D
// NEAR_BOUNDARY_GRACE_MONTHS (ver classifySpellGap) é SOMENTE diagnóstico —
// nunca entra na decisão de link. resolveSpellForDate() nem importa essa
// constante.

function monthIdx(year, month, role) { const m = month != null ? month : role === 'start' ? 1 : 12; return year * 12 + (m - 1); }

function overlaps(period, spell) {
  const aS = monthIdx(period.startYear, period.startMonth, 'start');
  const aE = period.isOngoing ? Infinity : monthIdx(period.endYear, period.endMonth, 'end');
  const bS = monthIdx(spell.startYear, spell.startMonth, 'start');
  const bE = spell.isOngoing ? Infinity : monthIdx(spell.endYear, spell.endMonth, 'end');
  return aS <= bE && bS <= aE;
}

export function overlapCandidates(spellsForPerson, isoDate) {
  const [y, m] = isoDate.split('-').map(Number);
  const point = { startYear: y, startMonth: m, endYear: y, endMonth: m, isOngoing: false };
  return spellsForPerson.filter((s) => overlaps(point, s));
}

/** Resolve o spell vigente numa data — 1 match único -> spell; 0 ou 2+ ->
 * null (nunca escolhe sozinho, nunca usa "graça"/tolerância de precisão
 * pra decidir). */
export function resolveSpellForDate(spellsForPerson, isoDate) {
  const matches = overlapCandidates(spellsForPerson, isoDate);
  return matches.length === 1 ? matches[0] : null;
}

// Janela de tolerância (em meses) — SOMENTE pra classificar/diagnosticar
// POR QUE um spell_id ficou NULL (categoria B vs C no relatório), NUNCA
// pra selecionar automaticamente um spell_id. resolveSpellForDate() acima
// não referencia esta constante em nenhum caminho — a prova estrutural
// disso é que ela só é importada por classifySpellGap()/nearestBoundaryInfo(),
// nunca por resolveSpellForDate()/overlapCandidates().
export const NEAR_BOUNDARY_GRACE_MONTHS = 6;

/** Pra um candidate SEM overlap (0 matches), decide se é B (perto o
 * bastante de um boundary YEAR-precision pra ser incerteza de precisão) ou
 * C (genuinamente fora). Só chamada DEPOIS que resolveSpellForDate já
 * decidiu null — nunca influencia essa decisão. */
export function nearestBoundaryInfo(spellsForPerson, isoDate) {
  const [y, m] = isoDate.split('-').map(Number);
  const pointIdx = y * 12 + (m - 1);
  let best = { distanceMonths: Infinity, nearestIsYearPrecision: false };
  for (const s of spellsForPerson) {
    const sIdx = monthIdx(s.startYear, s.startMonth, 'start');
    const eIdx = s.isOngoing ? null : monthIdx(s.endYear, s.endMonth, 'end');
    if (pointIdx < sIdx) {
      const d = sIdx - pointIdx;
      if (d < best.distanceMonths) best = { distanceMonths: d, nearestIsYearPrecision: s.startPrecision === 'YEAR' };
    } else if (eIdx !== null && pointIdx > eIdx) {
      const d = pointIdx - eIdx;
      if (d < best.distanceMonths) best = { distanceMonths: d, nearestIsYearPrecision: s.endPrecision === 'YEAR' };
    }
  }
  return best;
}

/** Classifica POR QUE spell_id ficou NULL — 4 categorias auditáveis
 * (diagnóstico, nunca decisão de link):
 *  A) pessoa não possui NENHUM spell canônico Goiás.
 *  B) boundary mais próximo tem precisão YEAR e está a <=
 *     NEAR_BOUNDARY_GRACE_MONTHS meses — precisão insuficiente pra decidir
 *     (mas NUNCA auto-linkado por isso).
 *  C) a data cai realmente fora de todos os spells (sem overlap, não é B).
 *  D) 2+ spells candidatos se sobrepõem à MESMA data — ambiguidade real.
 */
export function classifySpellGap(spellsForPerson, isoDate) {
  if (spellsForPerson.length === 0) return 'A';
  const candidates = overlapCandidates(spellsForPerson, isoDate);
  if (candidates.length >= 2) return 'D';
  const info = nearestBoundaryInfo(spellsForPerson, isoDate);
  if (info.nearestIsYearPrecision && info.distanceMonths <= NEAR_BOUNDARY_GRACE_MONTHS) return 'B';
  return 'C';
}
