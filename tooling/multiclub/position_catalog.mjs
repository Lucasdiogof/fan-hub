// Catálogo canônico de posição — NÃO inventado nesta etapa: é EXATAMENTE o
// enum `PlayerPosition` já em produção em lib/shared/domain/player_position
// .dart, usado por crowd_lineup/formation.dart/position_compatibility.dart.
// Nunca reinventar um catálogo paralelo — esta é a mesma verdade que o app
// já usa pra desenhar escalações.
export const CANONICAL_POSITIONS = ['GOL', 'ZAG', 'LD', 'LE', 'ALD', 'ALE', 'VOL', 'MC', 'MEI', 'MD', 'ME', 'PD', 'PE', 'SA', 'ATA'];

export const POSITION_FULL_NAME = {
  GOL: 'Goleiro', ZAG: 'Zagueiro', LD: 'Lateral-direito', LE: 'Lateral-esquerdo',
  ALD: 'Ala-direito', ALE: 'Ala-esquerdo', VOL: 'Volante', MC: 'Meio-campista',
  MEI: 'Meia', MD: 'Meia-direita', ME: 'Meia-esquerda', PD: 'Ponta-direita',
  PE: 'Ponta-esquerda', SA: 'Segundo atacante', ATA: 'Atacante',
};

/** Códigos ALL-CAPS/lowercase que já SÃO o próprio código canônico (GOL,
 * gol, Gol...) — cobre guess_players (lowercase) e lineup_matches
 * (UPPERCASE) num só lugar. */
export function normalizeDirectCode(raw) {
  const upper = String(raw).trim().toUpperCase();
  return CANONICAL_POSITIONS.includes(upper) ? upper : null;
}

/** squad_members.position / tokens dentro de career_players.position — só
 * palavras/frases em português que JÁ são inequívocas (batem exatamente
 * com POSITION_FULL_NAME, ou têm 1 aproximação documentada). NUNCA inventa
 * lado (D/E) quando a fonte não diz — "Ponta"/"Ala" bare ficam de fora
 * (retorna null), documentado como UNMAPPABLE no relatório, nunca uma
 * suposição. */
const PT_WORD_TO_CODE = {
  'Goleiro': 'GOL',
  'Zagueiro': 'ZAG',
  'Lateral-direito': 'LD',
  'Lateral-esquerdo': 'LE',
  'Volante': 'VOL',
  'Meia': 'MEI',
  // "Meia-atacante" resolvido EMPIRICAMENTE (não por suposição própria):
  // dos 4 jogadores do elenco atual com squad_members.position=
  // "Meia-atacante", 3 têm MEI como posição PRIMÁRIA em goias_squad.dart
  // (Lucas Lima, Brayann, Jean Carlos) e o 4º (Gegê) tem MEI como
  // secundária (primária MC) — MEI é a leitura mais consistente da fonte
  // humana curada, aplicada aqui de volta pra a mesma frase em
  // career_players.
  'Meia-atacante': 'MEI',
  'Ponta-direita': 'PD',
  'Ponta-esquerda': 'PE',
  // "Centroavante" não tem código dedicado no catálogo de 15 — ATA
  // (Atacante) é a aproximação mais próxima, documentada, nunca um código
  // novo inventado só pra este caso.
  'Centroavante': 'ATA',
  'Atacante': 'ATA',
};

const PT_WORD_TO_CODE_LOWER = Object.fromEntries(Object.entries(PT_WORD_TO_CODE).map(([k, v]) => [k.toLowerCase(), v]));

/** Resolve 1 token de texto em português — devolve o código canônico ou
 * null (UNMAPPABLE, nunca um palpite). Case-insensitive: career_players
 * escreve "Atacante / meia-atacante" (1º token capitalizado por estar no
 * início da frase, 2º em minúsculo por estar no meio) — é a MESMA palavra,
 * maiúscula/minúscula nunca deveria mudar se resolve ou não. */
export function resolvePortugueseToken(token) {
  const t = token.trim().toLowerCase();
  return PT_WORD_TO_CODE_LOWER[t] || null;
}

/**
 * Resolve uma string de career_players.position (pode ser composta,
 * "X / Y") em 0+ códigos canônicos. Caso especial documentado:
 * "Lateral-direito / ala" -> LD + ALD (o lado de "ala" é inferido do
 * "lateral-direito" adjacente na MESMA string — é o único caso onde side
 * inference é seguro, porque a própria fonte já amarrou os 2 termos).
 * "Ponta"/"Ala" isolados (sem lado) NUNCA são resolvidos.
 */
export function resolveCareerPlayersPosition(raw) {
  const tokens = raw.split('/').map((t) => t.trim());
  if (tokens.length === 2) {
    const [a, b] = tokens;
    if (a === 'Lateral-direito' && b === 'ala') return { resolved: ['LD', 'ALD'], unmapped: [] };
    if (a === 'Lateral-esquerdo' && b === 'ala') return { resolved: ['LE', 'ALE'], unmapped: [] };
  }
  const resolved = [];
  const unmapped = [];
  for (const t of tokens) {
    const code = resolvePortugueseToken(t);
    if (code) resolved.push(code);
    else unmapped.push(t);
  }
  return { resolved: [...new Set(resolved)], unmapped };
}

// Mesmo mapa de lib/features/crowd_lineup/domain/position_compatibility
// .dart#_naturalAdaptations — reproduzido aqui só pra classificar
// conflitos no relatório (COMPATIBLE_MULTI_POSITION vs PROVAVEL_CONFLITO),
// NUNCA usado pra fundir/escolher posição. Fonte da verdade continua o
// arquivo Dart; se ele mudar, atualizar aqui também.
const NATURAL_ADAPTATIONS = {
  LD: ['ALD'], LE: ['ALE'],
  ALD: ['LD', 'MD', 'PD'], ALE: ['LE', 'ME', 'PE'],
  VOL: ['MC'], MC: ['VOL', 'MEI'], MEI: ['MC', 'SA'],
  MD: ['PD', 'ALD'], ME: ['PE', 'ALE'],
  PD: ['MD'], PE: ['ME'],
  SA: ['ATA', 'MEI'], ATA: ['SA'],
  GOL: [], ZAG: [],
};

/** true se `a` e `b` são adaptações táticas conhecidas uma da outra
 * (bidirecional) — usado só pra CLASSIFICAR versatilidade sem
 * fonte-ouro no relatório, nunca pra decidir dado. */
export function arePositionsCompatible(a, b) {
  if (a === b) return true;
  return (NATURAL_ADAPTATIONS[a] || []).includes(b) || (NATURAL_ADAPTATIONS[b] || []).includes(a);
}

/** lineup_matches.lineup[].pos — pode ser composto "LD/MC" (2 observações
 * na MESMA aparição, caso real do Dieguinho). DEF/ALA são genéricos
 * (lado/tipo desconhecido) — NUNCA mapeados, sempre excluídos como
 * unmappable. */
export function resolveLineupMatchesPosition(raw) {
  const tokens = String(raw).split('/').map((t) => t.trim());
  const resolved = [];
  const unmapped = [];
  for (const t of tokens) {
    if (t === 'DEF' || t === 'ALA') { unmapped.push(t); continue; }
    const code = normalizeDirectCode(t);
    if (code) resolved.push(code);
    else unmapped.push(t);
  }
  return { resolved: [...new Set(resolved)], unmapped };
}
