/**
 * Regra de cobertura completa pra CLUB_TOTAL derivado por soma — sem
 * efeito colateral nenhum (módulo puro), importado tanto por
 * build_player_club_stats_seed.mjs quanto pelos testes com dado
 * sintético. 3 spells canônicos com stats só pra 2 NUNCA pode derivar,
 * mesmo que a soma "pareça" razoável.
 *
 * `canonicalSpellIds`: TODOS os spell_id reais de (person_id, club_id).
 * `matchedEntries`: [{spellId, appearances, goals}] — só as entradas que
 * JÁ casaram 1:1 com um spell real (entradas sem match não entram aqui).
 * Devolve { appearancesFullyCovered, goalsFullyCovered } — cada campo
 * avaliado INDEPENDENTEMENTE (goals pode faltar cobertura mesmo com
 * appearances 100% coberto — NULL nunca vira 0).
 */
export function checkSpellCoverage(canonicalSpellIds, matchedEntries) {
  const matchedIds = new Set(matchedEntries.map((m) => m.spellId));
  const allSpellsMatched = canonicalSpellIds.length > 0 && canonicalSpellIds.every((id) => matchedIds.has(id)) && matchedIds.size === canonicalSpellIds.length;
  const appearancesFullyCovered = allSpellsMatched && matchedEntries.every((m) => m.appearances != null);
  const goalsFullyCovered = allSpellsMatched && matchedEntries.every((m) => m.goals != null);
  return { appearancesFullyCovered, goalsFullyCovered };
}

/**
 * Propagação de qualidade — o verification_status de um CLUB_TOTAL
 * DERIVADO (soma de componentes) é o PIOR entre os componentes, nunca
 * "VERIFIED só porque a cobertura é 100%". Cobertura completa e
 * confiabilidade são perguntas DIFERENTES: cobertura pergunta "temos o
 * número de toda passagem?"; verification_status pergunta "esse número em
 * si é confiável?" — as duas precisam ser verdadeiras pro total herdar
 * VERIFIED.
 */
export function worstVerificationStatus(statuses) {
  if (statuses.length === 0) throw new Error('worstVerificationStatus: lista vazia.');
  return statuses.includes('PARTIAL') ? 'PARTIAL' : 'VERIFIED';
}
