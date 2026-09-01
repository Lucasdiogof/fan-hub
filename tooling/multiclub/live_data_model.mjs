// Implementação de REFERÊNCIA (não é o schema real, não toca Supabase) das
// regras centrais de docs/multiclub/16_live_data_architecture.md — existe
// pra provar em código, antes do INSERT/migration real, que o desenho
// aguenta os casos que motivaram ele (Tadeu 398×400, Walter 0 jogos,
// Dieguinho polivalente, sync repetido). Cada função aqui tem uma
// contrapartida direta no schema SQL proposto — ver os comentários "SQL:".
//
// Nada disso é chamado pelo app. É só o pré-requisito de design que a v3.1
// pediu antes do INSERT final.

/** SQL: player_match_appearances.started / veio_do_banco / não_utilizado.
 * Deriva o status de comparecimento a partir de dado de escalação bruto —
 * NUNCA conta reserva não utilizado como aparição. */
export function classifyAppearance({ started, cameInMinute, wasInSquad }) {
  if (started) return 'STARTED';
  if (cameInMinute != null) return 'SUBSTITUTE_USED';
  if (wasInSquad) return 'UNUSED_SUBSTITUTE';
  throw new Error('classifyAppearance: dado insuficiente pra classificar (nem started, nem cameInMinute, nem wasInSquad).');
}

/** Só STARTED e SUBSTITUTE_USED contam como "jogou" — regra central do
 * pedido: "Apenas quem efetivamente entrou em campo conta como appearance." */
export function countsAsAppearance(status) {
  return status === 'STARTED' || status === 'SUBSTITUTE_USED';
}

/** SQL: unique index em player_match_appearances(person_id, club_id,
 * canonical_match_id) + UPSERT. Simulação em memória do ledger idempotente —
 * processar a mesma partida N vezes produz exatamente 1 linha por pessoa. */
export class AppearanceLedger {
  constructor() {
    this.rows = new Map(); // key `${personId}|${clubId}|${canonicalMatchId}` -> row
  }

  key(personId, clubId, canonicalMatchId) {
    return `${personId}|${clubId}|${canonicalMatchId}`;
  }

  /** UPSERT — chamar 1x, 2x ou 10x com o mesmo (personId, clubId,
   * canonicalMatchId, appearance) precisa deixar exatamente a MESMA linha
   * (mesmo se os campos de evento vierem re-sincronizados). */
  upsert(personId, clubId, canonicalMatchId, appearanceData) {
    const k = this.key(personId, clubId, canonicalMatchId);
    this.rows.set(k, { personId, clubId, canonicalMatchId, ...appearanceData, syncedAt: appearanceData.syncedAt ?? this.rows.get(k)?.syncedAt ?? 0 });
    return this.rows.get(k);
  }

  count() {
    return this.rows.size;
  }

  countForPerson(personId, clubId) {
    return [...this.rows.values()].filter((r) => r.personId === personId && r.clubId === clubId && countsAsAppearance(r.status)).length;
  }
}

/** SQL: player_club_stats.appearances = baseline + COUNT(appearances
 * posteriores a as_of_date/as_of_match_id). Nunca "appearances += 1" cego —
 * o delta é sempre CONTADO a partir de aparições reais e únicas, nunca
 * incrementado imperativamente por evento de sync. */
export function resolveLiveAppearances(baseline, ledger, personId, clubId, { excludeMatchIds = new Set() } = {}) {
  const deltaAppearances = [...ledger.rows.values()].filter(
    (r) => r.personId === personId && r.clubId === clubId && countsAsAppearance(r.status) && !excludeMatchIds.has(r.canonicalMatchId),
  ).length;
  return baseline.appearances + deltaAppearances;
}

/** SQL: player_club_spells.appearances_known / spell sem nenhuma partida —
 * uma passagem é válida com 0 jogos (Walter/2019). Nunca rejeitar isso como
 * "dado incompleto". */
export function validateSpell(spell) {
  const errors = [];
  if (!spell.personId) errors.push('spell sem personId');
  if (!spell.clubId) errors.push('spell sem clubId');
  if (!spell.registrationType) errors.push('spell sem registrationType');
  if (spell.appearances != null && spell.appearances < 0) errors.push('appearances negativo');
  // 0 jogos é EXPLICITAMENTE válido — não entra na lista de erros.
  return { valid: errors.length === 0, errors };
}

/** SQL: player_positions(person_id, club_id, position_code, is_primary,
 * valid_from, valid_to, source) — uma pessoa pode ter várias posições
 * concorrentes/sequenciais (Dieguinho: volante + lateral-direito + meia). */
export function addPosition(positions, personId, clubId, positionCode, { isPrimary = false, source = 'manual_verified' } = {}) {
  if (isPrimary) {
    for (const p of positions) if (p.personId === personId && p.clubId === clubId) p.isPrimary = false;
  }
  positions.push({ personId, clubId, positionCode, isPrimary, source });
  return positions;
}

export function primaryPosition(positions, personId, clubId) {
  return positions.find((p) => p.personId === personId && p.clubId === clubId && p.isPrimary) ?? null;
}

export function allPositions(positions, personId, clubId) {
  return positions.filter((p) => p.personId === personId && p.clubId === clubId).map((p) => p.positionCode);
}

/** SQL: passport_matches.date_precision / date_original vs. effective_date
 * (mesmo padrão já usado na auditoria de estádios, ver
 * project_goias_app_passport_trajectory_polish) — aplicado aqui a
 * joined_at/left_at de player_club_spells. Nunca inventa dia/mês quando só
 * o ano é conhecido. */
export const TEMPORAL_PRECISION = ['YEAR', 'MONTH', 'DAY'];

export function temporalValue(precision, { year, month, day }) {
  if (!TEMPORAL_PRECISION.includes(precision)) throw new Error(`precisão temporal inválida: ${precision}`);
  if (precision === 'YEAR' && year == null) throw new Error('precision=YEAR exige year');
  if (precision === 'MONTH' && (year == null || month == null)) throw new Error('precision=MONTH exige year+month');
  if (precision === 'DAY' && (year == null || month == null || day == null)) throw new Error('precision=DAY exige year+month+day');
  return { precision, year, month: precision === 'YEAR' ? null : month, day: precision === 'DAY' ? day : null };
}

/** SQL: matches.club_id / passport_match_id / (match_source,
 * match_external_id) — nunca um `match_id text` ambíguo entre origens.
 * Namespace explícito por fonte. */
export function canonicalMatchId({ source, externalId }) {
  if (!source || !externalId) throw new Error('canonicalMatchId exige source e externalId');
  return `${source}:${externalId}`;
}
