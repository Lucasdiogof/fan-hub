// CONCEITUAL — prova o algoritmo baseline+delta descrito na Etapa E.
// NÃO é chamado por nenhuma migration, seed ou app — não escreve em
// lugar nenhum. Existe só pra deixar a fórmula testável e revisável
// antes de qualquer sincronização viva real ser implementada.
//
// Fórmula (conforme especificado):
//   total = baseline.appearances
//         + count(DISTINCT canonical_match_id WHERE
//             participation_status IN ('STARTED', 'SUBSTITUTE_USED')
//             AND match é ESTRITAMENTE posterior ao baseline)
//
// "Estritamente posterior" NUNCA presume que toda partida tem data exata
// — usa compareKickoffBoundary() (tooling/multiclub/kickoff_precision.mjs)
// pra comparar INTERVALOS, não datas string. Casos:
//   1. candidate.kickoff estritamente ANTES do intervalo do baseline
//      -> nunca soma (backfill não aumenta o total, mesmo com precisão
//         YEAR/MONTH coarse).
//   2. canonicalMatchId do candidato === baseline.asOfMatchId
//      -> é o próprio match do snapshot, já incluído, nunca soma de novo.
//   3. intervalos SE CRUZAM sem desempate seguro (partida de precisão
//      coarse cruzando a fronteira do baseline, OU mesmo dia sem horário
//      DATETIME confiável dos 2 lados) -> AMBIGUOUS_BOUNDARY, nunca
//      resolvida silenciosamente, fica de fora do delta automático.
//      Partidas históricas YEAR/MONTH seguem úteis como appearances
//      (player_match_appearances) — só não entram no delta automático do
//      baseline quando cruzam essa fronteira; longe da fronteira (caso 1)
//      elas somam normalmente como "antes", sem ambiguidade.
//   4. candidate.kickoff estritamente DEPOIS do intervalo do baseline (ou,
//      no caso de dia idêntico com DATETIME confiável nos 2 lados, o
//      instante do candidate é posterior)
//      -> conta (uma vez só por canonicalMatchId, dedup garante
//         idempotência mesmo processando a mesma partida N vezes).
//   Pra partidas AO VIVO (esperado: sempre DATETIME), isso nunca vira
//   AMBIGUOUS_BOUNDARY na prática — só os casos históricos coarse
//   (YEAR/MONTH) usam esse caminho, e eles ficam "presos" antes do
//   baseline por construção (baseline é sempre >= a última partida
//   sincronizada, que é sempre mais recente que qualquer histórico
//   YEAR/MONTH já conhecido).
import { compareKickoffBoundary } from './kickoff_precision.mjs';

export function countsAsAppearance(participationStatus) {
  return participationStatus === 'STARTED' || participationStatus === 'SUBSTITUTE_USED';
}

/**
 * @param {{appearances:number, asOfMatchId:string, asOfKickoff: object}} baseline
 *   `asOfKickoff` no formato canônico de kickoff_precision.mjs:
 *   {precision, year, month, date, at}.
 * @param {{canonicalMatchId:string, participationStatus:string, kickoff: object}[]} candidateAppearances
 */
export function computeDelta(baseline, candidateAppearances) {
  const seenMatchIds = new Set();
  const includedMatchIds = [];
  const ambiguousBoundary = [];

  for (const a of candidateAppearances) {
    if (!countsAsAppearance(a.participationStatus)) continue;
    if (a.canonicalMatchId === baseline.asOfMatchId) continue;
    const verdict = compareKickoffBoundary(a.kickoff, baseline.asOfKickoff);
    if (verdict === 'BEFORE' || verdict === 'SAME') continue;
    if (verdict === 'AMBIGUOUS') { ambiguousBoundary.push(a); continue; }
    // 'AFTER'
    if (seenMatchIds.has(a.canonicalMatchId)) continue;
    seenMatchIds.add(a.canonicalMatchId);
    includedMatchIds.push(a.canonicalMatchId);
  }

  return { delta: includedMatchIds.length, includedMatchIds, ambiguousBoundary };
}

/**
 * @param {{appearances:number, asOfMatchId:string, asOfKickoff: object}} baseline
 * @param {{canonicalMatchId:string, participationStatus:string, kickoff: object}[]} candidateAppearances
 */
export function recomputeTotal(baseline, candidateAppearances) {
  const { delta, includedMatchIds, ambiguousBoundary } = computeDelta(baseline, candidateAppearances);
  return { total: baseline.appearances + delta, delta, includedMatchIds, ambiguousBoundary };
}
