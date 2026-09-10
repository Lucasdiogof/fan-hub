/**
 * Normalização de nomes de fase do OneFootball — camada isolada e testável
 * (spec item 5), construída a partir de strings REAIS observadas ao vivo
 * (2026-09-10/11) em 3 competições diferentes:
 *   - Copa do Brasil (`competicao/copa-betano-do-brasil-137/{jogos,resultados}`):
 *     "Semifinais - Jogo de ida", "Semifinais - Jogo de volta", "Final",
 *     "Quartas de final - Jogo de ida/volta", "Oitavas de final - Jogo de
 *     ida/volta".
 *   - CONMEBOL Sudamericana (`competicao/conmebol-sudamericana-102/{jogos,
 *     resultados}`): "Oitavas de final - Jogo de ida/volta", "Quartas de
 *     final - Jogo de ida/volta", "Semifinais - Jogo de ida/volta",
 *     "Repescagem - Ida/Volta".
 *   - UEFA Champions League (`competicao/uefa-liga-dos-campeoes-5/{jogos,
 *     resultados}`): "Fase de liga" (SEM traço/perna — é a fase de tabela
 *     atual, não mata-mata), "Repescagem - Ida/Volta", "3a Fase - volta"
 *     (fases classificatórias ANTERIORES à fase de liga atual — mesmo nome
 *     "Repescagem" da Sudamericana, posição cronológica OPOSTA: aqui vem
 *     ANTES da fase de tabela, na Sudamericana vem DEPOIS da fase de
 *     grupos — por isso o filtro cronológico em `knockout.ts` é a
 *     autoridade final, não o nome sozinho).
 */

export type LegType = 'SINGLE' | 'FIRST' | 'SECOND';

/** "Jogo de ida"/"Ida" -> FIRST, "Jogo de volta"/"Volta" -> SECOND. Nunca
 * depende de igualdade exata única — aceita as duas variantes encontradas
 * (com e sem "Jogo de"). */
export function normalizeLegLabel(raw: string): LegType | null {
  const normalized = raw.trim().toLowerCase();
  if (normalized === 'jogo de ida' || normalized === 'ida') return 'FIRST';
  if (normalized === 'jogo de volta' || normalized === 'volta') return 'SECOND';
  return null;
}

/**
 * Vocabulário CONTROLADO de nomes de rodada de mata-mata — cada padrão foi
 * conferido contra uma string real (ver cabeçalho do arquivo), nunca uma
 * regex permissiva genérica que aceitaria qualquer "Fase X". `\d+a Fase`
 * cobre "3a Fase" (fases classificatórias numeradas da Champions) sem
 * confundir com "Fase de Liga"/"Fase de Grupos" (sem dígito na frente).
 */
const KNOCKOUT_ROUND_PATTERNS: RegExp[] = [
  /^playoffs?$/i,
  /^play-offs?$/i,
  /^repescagem$/i,
  /^oitavas( de final)?$/i,
  /^quartas( de final)?$/i,
  /^(semifinal|semifinais)$/i,
  /^final$/i,
  /^\d+a fase$/i,
];

/** `true` só quando [roundLabel] bate com o vocabulário controlado acima —
 * nunca decide sozinho se a rodada É a fase eliminatória atual da
 * temporada (isso depende também da janela cronológica, ver
 * `selectKnockoutSections` em `knockout.ts`). */
export function isKnockoutRoundLabel(roundLabel: string): boolean {
  const normalized = roundLabel.trim();
  return KNOCKOUT_ROUND_PATTERNS.some((pattern) => pattern.test(normalized));
}

export interface ParsedSection {
  round: string;
  leg: LegType;
}

/** `"<Fase>"` ou `"<Fase> - <perna>"`. `null` só quando o subtitle está
 * vazio — o round em si pode ser qualquer texto (mata-mata ou não), quem
 * decide se É mata-mata é `isKnockoutRoundLabel`/a perna presente. */
export function parseSectionSubtitle(subtitle: string | undefined): ParsedSection | null {
  if (!subtitle) return null;
  const parts = subtitle.split(' - ');
  const round = parts[0]?.trim();
  if (!round) return null;
  const leg = parts[1] ? (normalizeLegLabel(parts[1]) ?? 'SINGLE') : 'SINGLE';
  return { round, leg };
}

/**
 * Uma seção de jogos é "de mata-mata" quando tem uma perna explícita
 * (ida/volta só existe pra confronto eliminatório) OU o nome da fase bate
 * com o vocabulário controlado (cobre rodadas de jogo único, tipo "Final"
 * sem traço nenhum). Uma "Fase de liga"/"Fase de Grupos"/"Rodada 12" nunca
 * bate nem um nem outro — são fases de tabela, não de chaveamento.
 */
export function isKnockoutSection(parsed: ParsedSection): boolean {
  return parsed.leg !== 'SINGLE' || isKnockoutRoundLabel(parsed.round);
}
