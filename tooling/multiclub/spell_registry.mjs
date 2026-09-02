// Registro PERSISTIDO de identidade de SPELL (passagem pessoa↔clube).
//
// v2 — NUNCA mais usa índice de array de nenhuma fonte como âncora de
// identidade (v1 usava "career_players:paulo_baier:club_career:11" — se o
// array club_career fosse reordenado, index:11 viraria index:12 e o
// matching quebraria, mesmo a passagem futebolística sendo exatamente a
// mesma). O motivo de existir desta camada é justamente sobreviver a esse
// tipo de mudança estrutural na fonte.
//
// Como funciona agora: cada entrada do registry guarda um "match anchor" —
// (personCanonicalPersonKey, clubCanonicalKey, lastKnownBoundary) — e o
// match de um candidate NOVO contra o registry é por SOBREPOSIÇÃO TEMPORAL
// dentro do mesmo (pessoa, clube), nunca por qual registro-fonte originou
// o spell. `lastKnownBoundary` é atualizado a cada run pro boundary mais
// recente conhecido (permite refinar YEAR->MONTH->DATE sem trocar id: o
// boundary refinado ainda SOBREPÕE o boundary anterior, então ainda casa).
//
// Regra: 1 entrada casa -> reusa id. 0 entradas casam -> candidate novo.
// 2+ entradas casam -> AMBIGUOUS_MATCH, bloqueado — nunca escolhido
// sozinho, precisa de decisão humana (mesmo princípio de resolvePersonId).
//
// SPLIT (uma passagem que achávamos ser 1 spell descobrimos depois que
// eram 2): cada entrada guarda `foundingBoundary` (o boundary de QUANDO
// foi registrada, IMUTÁVEL — nunca atualizado, diferente de
// `lastKnownBoundary`). Se um run futuro produz 2+ candidates que TODOS
// se sobrepõem ao MESMO foundingBoundary de uma entrada existente, isso é
// a assinatura de um split — resolveSpellGroupMatches() detecta essa
// colisão ANTES de decidir qualquer coisa (nunca deixa o primeiro
// candidate processado "vencer" silenciosamente por ordem de
// processamento) e devolve 'ambiguous' pros dois. Só um override humano
// resolve: um candidate herda o spell_id existente (o que contém a
// foundingBoundary original), o outro vira um spell_id NOVO — a chave
// antiga nunca é reaproveitada, nunca há um 3º id inventado.
//
// MERGE (2 spells que achávamos distintos descobrimos depois que eram a
// mesma passagem contínua): NUNCA apaga/reaproveita silenciosamente um
// id. Um humano chama supersedeSpell() explicitamente — o id sobrevivente
// continua ativo, o outro vira `status: 'SUPERSEDED'` +
// `supersededByCanonicalSpellKey`, e resolveSpellMatch()/
// resolveSpellGroupMatches() nunca mais casam contra entradas SUPERSEDED
// (só ACTIVE) — runs futuros convergem sozinhos pro sobrevivente.
// canonicalSpellKey da entrada superseded fica queimado pra sempre, nunca
// reaproveitado (nextSequence nunca volta atrás).
import fs from 'fs';
import { uuidV5 } from './person_registry.mjs';

export const SPELLS_UUID_NAMESPACE = '3a7d5e2b-9c1f-4a6e-b2d4-7f8e1c9a0d3b';

const PERMANENCE_WARNING = 'ESTE ARQUIVO É UM REGISTRY PERSISTENTE DE IDENTIDADE DE SPELL, NÃO UM CACHE. spell_id, uma vez atribuído, NUNCA muda — mesmo se datas forem refinadas (YEAR->MONTH->DATE), spell_order for renumerado, a fonte-registro for reordenada/trocada, ou provenance nova for adicionada. Matching é por SOBREPOSIÇÃO TEMPORAL (pessoa+clube+boundary), nunca por índice de array de fonte nenhuma. canonicalSpellKey é sequencial, global entre todos os clubes, e NUNCA é reaproveitado.';

export function emptySpellRegistry() {
  return { version: 2, _permanenceWarning: PERMANENCE_WARNING, nextSequence: 1, entries: [] };
}

export function loadSpellRegistry(filePath) {
  if (!fs.existsSync(filePath)) return emptySpellRegistry();
  const registry = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  registry._permanenceWarning = PERMANENCE_WARNING;
  validateSpellRegistryIntegrity(registry);
  return registry;
}

export function saveSpellRegistry(filePath, registry) {
  validateSpellRegistryIntegrity(registry);
  fs.writeFileSync(filePath, JSON.stringify(registry, null, 2) + '\n');
}

export function validateSpellRegistryIntegrity(registry) {
  const seenKeys = new Set();
  const seenIds = new Set();
  for (const e of registry.entries) {
    const seq = parseInt(String(e.canonicalSpellKey).split(':').pop(), 10);
    if (!Number.isInteger(seq) || seq < 1) throw new Error(`Registry de spells corrompido: canonicalSpellKey "${e.canonicalSpellKey}" sem sequência válida.`);
    if (seq >= registry.nextSequence) throw new Error(`Registry de spells corrompido: "${e.canonicalSpellKey}" (seq ${seq}) é >= nextSequence (${registry.nextSequence}).`);
    if (seenKeys.has(e.canonicalSpellKey)) throw new Error(`Registry de spells corrompido: canonicalSpellKey "${e.canonicalSpellKey}" duplicado.`);
    seenKeys.add(e.canonicalSpellKey);
    if (seenIds.has(e.spellId)) throw new Error(`Registry de spells corrompido: spellId "${e.spellId}" duplicado (em "${e.canonicalSpellKey}").`);
    seenIds.add(e.spellId);
    if (e.status && e.status !== 'ACTIVE' && e.status !== 'SUPERSEDED') throw new Error(`Registry de spells corrompido: status inválido "${e.status}" em "${e.canonicalSpellKey}".`);
    if (e.status === 'SUPERSEDED') {
      if (!e.supersededByCanonicalSpellKey) throw new Error(`Registry de spells corrompido: "${e.canonicalSpellKey}" está SUPERSEDED sem supersededByCanonicalSpellKey.`);
      const survivor = registry.entries.find((x) => x.canonicalSpellKey === e.supersededByCanonicalSpellKey);
      if (!survivor) throw new Error(`Registry de spells corrompido: "${e.canonicalSpellKey}" aponta pra sobrevivente inexistente "${e.supersededByCanonicalSpellKey}".`);
      if (survivor.status === 'SUPERSEDED') throw new Error(`Registry de spells corrompido: "${e.canonicalSpellKey}" aponta pra um sobrevivente ("${e.supersededByCanonicalSpellKey}") que também está SUPERSEDED — cadeia inválida, deve apontar sempre pro ACTIVE final.`);
    }
  }
  return true;
}

/** índice comparável mês-a-mês. boundaryRole 'start' assume mês 1 quando só
 * o ano é conhecido (o mais cedo possível); 'end' assume mês 12 (o mais
 * tarde possível) — deliberadamente CONSERVADOR pra sobreposição: preferir
 * achar overlap a preferir não achar, já que um "não achar" nunca corrompe
 * nada (vira `new`, nunca apaga histórico), enquanto um overlap perdido
 * criaria um 2º spell_id indevido pro mesmo período. */
function monthIndex(year, month, boundaryRole) {
  const m = month != null ? month : boundaryRole === 'start' ? 1 : 12;
  return year * 12 + (m - 1);
}

const ONGOING_SENTINEL_MONTH_INDEX = 9999 * 12;

function boundaryRange(boundary) {
  const startIdx = monthIndex(boundary.startYear, boundary.startMonth, 'start');
  const endIdx = boundary.isOngoing ? ONGOING_SENTINEL_MONTH_INDEX : monthIndex(boundary.endYear, boundary.endMonth, 'end');
  return [startIdx, endIdx];
}

export function boundariesOverlap(a, b) {
  const [aStart, aEnd] = boundaryRange(a);
  const [bStart, bEnd] = boundaryRange(b);
  return aStart <= bEnd && bStart <= aEnd;
}

function activeEntriesScopedTo(registry, personCanonicalPersonKey, clubCanonicalKey) {
  return registry.entries.filter((e) => e.status !== 'SUPERSEDED' && e.personCanonicalPersonKey === personCanonicalPersonKey && e.clubCanonicalKey === clubCanonicalKey);
}

/**
 * Resolve o spell_id pra UM candidate isolado — match por SOBREPOSIÇÃO
 * TEMPORAL (lastKnownBoundary) contra entradas ACTIVE do MESMO
 * (personCanonicalPersonKey, clubCanonicalKey).
 *  - 1 match -> { status: 'matched', spellId, entry }
 *  - 0 matches -> { status: 'new' }
 *  - 2+ matches -> { status: 'ambiguous', matches: [...] } — NUNCA escolhe
 *    sozinho, quem chama trata como bloqueio.
 *
 * Prefira resolveSpellGroupMatches() quando resolver TODOS os candidates
 * de um (pessoa, clube) de uma vez — só ela detecta split (2+ candidates
 * do MESMO run competindo pela MESMA entrada existente).
 */
export function resolveSpellMatch(registry, { personCanonicalPersonKey, clubCanonicalKey, boundary }) {
  const scoped = activeEntriesScopedTo(registry, personCanonicalPersonKey, clubCanonicalKey);
  const matches = scoped.filter((e) => boundariesOverlap(e.lastKnownBoundary, boundary));
  if (matches.length === 1) return { status: 'matched', spellId: matches[0].spellId, canonicalSpellKey: matches[0].canonicalSpellKey, entry: matches[0] };
  if (matches.length > 1) return { status: 'ambiguous', matches };
  return { status: 'new' };
}

/**
 * Resolve TODOS os candidates de um (pessoa, clube) de uma vez, detectando
 * SPLIT: se 2+ candidates DESTE run se sobrepõem à MESMA entrada
 * existente (via foundingBoundary, imutável — não lastKnownBoundary, que
 * já pode ter sido refinado por um candidate anterior no mesmo run e
 * mascarar a colisão), NENHUM dos dois é resolvido sozinho — os dois
 * voltam com status 'ambiguous_split', bloqueados até um
 * spellSplitOverride humano decidir qual herda o id.
 *
 * Devolve um array paralelo a `candidates`, cada item:
 *   { status: 'matched'|'new'|'ambiguous'|'ambiguous_split', ... }
 */
export function resolveSpellGroupMatches(registry, personCanonicalPersonKey, clubCanonicalKey, candidates) {
  const scoped = activeEntriesScopedTo(registry, personCanonicalPersonKey, clubCanonicalKey);
  // 1ª passada: pra cada entrada existente, quantos candidates DESTE run
  // se sobrepõem à sua foundingBoundary?
  const candidatesOverlappingEntry = scoped.map((entry) => ({
    entry,
    overlappingCandidateIndexes: candidates.map((c, i) => (boundariesOverlap(entry.foundingBoundary, c.boundary) ? i : -1)).filter((i) => i >= 0),
  }));
  const splitEntries = candidatesOverlappingEntry.filter((x) => x.overlappingCandidateIndexes.length > 1);
  const splitCandidateIndexes = new Set(splitEntries.flatMap((x) => x.overlappingCandidateIndexes));

  return candidates.map((candidate, i) => {
    if (splitCandidateIndexes.has(i)) {
      const involvedEntries = splitEntries.filter((x) => x.overlappingCandidateIndexes.includes(i)).map((x) => x.entry);
      return { status: 'ambiguous_split', matches: involvedEntries };
    }
    return resolveSpellMatch(registry, { personCanonicalPersonKey, clubCanonicalKey, boundary: candidate.boundary });
  });
}

export function registerNewSpell(registry, { personCanonicalPersonKey, clubCanonicalKey, boundary, registeredAt } = {}) {
  const canonicalSpellKey = `goias-app:multiclub:spell:${registry.nextSequence}`;
  if (registry.entries.some((e) => e.canonicalSpellKey === canonicalSpellKey)) {
    throw new Error(`Tentativa de reaproveitar canonicalSpellKey já existente: "${canonicalSpellKey}".`);
  }
  const spellId = uuidV5(SPELLS_UUID_NAMESPACE, canonicalSpellKey);
  const entry = {
    spellId,
    canonicalSpellKey,
    personCanonicalPersonKey,
    clubCanonicalKey,
    foundingBoundary: boundary,
    lastKnownBoundary: boundary,
    status: 'ACTIVE',
    supersededByCanonicalSpellKey: null,
    registeredAt: registeredAt || new Date().toISOString().slice(0, 10),
  };
  registry.entries.push(entry);
  registry.nextSequence += 1;
  return entry;
}

/** Atualiza o boundary conhecido de uma entrada já casada — usado quando um
 * run refina a precisão (YEAR->MONTH->DATE). NUNCA muda spellId,
 * canonicalSpellKey nem foundingBoundary, só o campo de matching pra runs
 * futuros. */
export function refreshKnownBoundary(entry, boundary) {
  entry.lastKnownBoundary = boundary;
}

/** MERGE — um humano decidiu que 2 entradas ACTIVE são a mesma passagem
 * contínua. `survivorCanonicalSpellKey` continua ACTIVE (seu spell_id é o
 * que sobrevive); `supersededCanonicalSpellKey` vira SUPERSEDED — nunca
 * deletado, nunca reaproveitado, e passa a ser ignorado por
 * resolveSpellMatch()/resolveSpellGroupMatches() dali em diante (runs
 * futuros convergem sozinhos pro sobrevivente, sem risco de "ambiguous"
 * eterno). Lança erro se qualquer uma das chaves não existir ou já
 * estiver SUPERSEDED — nunca sobrescreve um merge já feito. */
export function supersedeSpell(registry, supersededCanonicalSpellKey, survivorCanonicalSpellKey) {
  const superseded = registry.entries.find((e) => e.canonicalSpellKey === supersededCanonicalSpellKey);
  const survivor = registry.entries.find((e) => e.canonicalSpellKey === survivorCanonicalSpellKey);
  if (!superseded) throw new Error(`supersedeSpell: "${supersededCanonicalSpellKey}" não existe no registry.`);
  if (!survivor) throw new Error(`supersedeSpell: sobrevivente "${survivorCanonicalSpellKey}" não existe no registry.`);
  if (superseded.status === 'SUPERSEDED') throw new Error(`supersedeSpell: "${supersededCanonicalSpellKey}" já está SUPERSEDED (por "${superseded.supersededByCanonicalSpellKey}") — merge já foi feito, não repetir.`);
  if (survivor.status === 'SUPERSEDED') throw new Error(`supersedeSpell: sobrevivente "${survivorCanonicalSpellKey}" está SUPERSEDED — não pode ser alvo de merge, resolva a cadeia primeiro.`);
  superseded.status = 'SUPERSEDED';
  superseded.supersededByCanonicalSpellKey = survivorCanonicalSpellKey;
  return survivor;
}
