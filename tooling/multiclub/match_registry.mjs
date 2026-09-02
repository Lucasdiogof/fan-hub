// Registro PERSISTIDO de identidade de PARTIDA — mesmo princípio de
// people/clubs/spells: matches.id NUNCA muda depois de atribuído, mesmo
// que data/horário/nome de time/competição sejam corrigidos depois, ou que
// uma nova fonte (passport_matches, um provider futuro) seja ligada à
// mesma partida.
//
// O id NÃO é derivado de nenhum atributo mutável da partida (data,
// oponente, placar, competição) nem de nenhum id de fonte externa (isso
// seria o mesmo erro de usar slug como identidade em `people`). O id vem
// de um canonicalMatchKey SEQUENCIAL e imutável, exatamente como pessoas e
// clubes: id = uuidV5(MATCHES_UUID_NAMESPACE, canonicalMatchKey).
//
// Identidade de PARTIDA != identidade de FONTE. Cada entrada guarda um
// conjunto de "source anchors" — (sourceNamespace, sourceRef); `sourceType`
// é só classificação SEMÂNTICA (LINEUP_MATCH/PASSPORT_MATCH/
// PROVIDER_FIXTURE), NUNCA o namespace de identidade (2 clubes podem ter o
// mesmo sourceType 'PASSPORT_MATCH' com namespaces diferentes, ex.:
// 'goias_passport' vs. 'juventude_passport' — nunca colidem). Anchors são
// só PONTES pra encontrar a entrada de novo num run futuro, nunca a base
// do id.
//
// Resolução em 2 ETAPAS (nunca uma escolha sozinha em qualquer uma):
//   ETAPA 1 — resolveMatchAnchors(): exact anchor match, a evidência MAIS
//     forte. Candidate novo casa com uma entrada existente se
//     COMPARTILHAR QUALQUER anchor (mesmo sourceNamespace+sourceRef):
//       - 1 entrada casa -> reusa matchId, novos anchors do candidate que
//         a entrada ainda não tinha são ACRESCENTADOS (nunca substituídos/
//         removidos).
//       - 0 entradas casam -> passa pra ETAPA 2.
//       - 2+ entradas casam -> AMBIGUOUS, bloqueado.
//   ETAPA 2 — resolveMatchCandidate(): SÓ quando a etapa 1 não achou
//     NENHUM anchor conhecido (ex.: uma 2ª fonte de um 2º clube, sem
//     nenhum anchor em comum com a 1ª fonte, mas descrevendo a MESMA
//     partida real). Compara atributos ESTRUTURADOS — identidade de
//     clube (home/away) + sobreposição de intervalo de kickoff +
//     competição/temporada como evidência de apoio — NUNCA placar (pode
//     ser corrigido depois, não é identidade). Resultado:
//       - 0 candidatos estruturalmente compatíveis -> NEW_MATCH.
//       - 1 candidato inequívoco -> EXISTING_MATCH, acrescenta o anchor
//         novo à entrada encontrada (nunca cria um 2º matchId pra mesma
//         partida).
//       - 2+ candidatos -> BLOCKED_AMBIGUOUS_MATCH, nunca escolhido
//         sozinho (override humano estruturado resolve, quando existir).
//   resolveMatch() orquestra as 2 etapas — usar essa função no lugar de
//   chamar as 2 partes manualmente.
//
// SPLIT/MERGE (mesma filosofia de spell_registry.mjs — ACTIVE/SUPERSEDED,
// canonicalMatchKey nunca reaproveitado): não exercitado nesta etapa (só
// existe 1 fonte real ligada nesta leva), mas a capacidade fica pronta —
// ver supersedeMatch().
import fs from 'fs';
import { uuidV5 } from './person_registry.mjs';
import { kickoffIntervalsOverlap } from './kickoff_precision.mjs';

export const MATCHES_UUID_NAMESPACE = '9e4a1c7d-5f3b-4e8a-9d2c-6b1f8a3e7c5d';

const PERMANENCE_WARNING = 'ESTE ARQUIVO É UM REGISTRY PERSISTENTE DE IDENTIDADE DE PARTIDA, NÃO UM CACHE. match_id, uma vez atribuído, NUNCA muda — mesmo se data/horário/nomes de time/competição/placar forem corrigidos depois, ou se uma nova fonte (passport_matches, um provider futuro, o import de outro clube) for ligada à mesma partida (isso só ACRESCENTA um anchor à entrada existente). Matching é por SOBREPOSIÇÃO DE ANCHOR (sourceType+sourceRef), nunca por atributo de partida nenhum. canonicalMatchKey é sequencial e NUNCA é reaproveitado, mesmo em SUPERSEDED.';

export function emptyMatchRegistry() {
  return { version: 1, _permanenceWarning: PERMANENCE_WARNING, nextSequence: 1, entries: [] };
}

export function loadMatchRegistry(filePath) {
  if (!fs.existsSync(filePath)) return emptyMatchRegistry();
  const registry = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  registry._permanenceWarning = PERMANENCE_WARNING;
  validateMatchRegistryIntegrity(registry);
  return registry;
}

export function saveMatchRegistry(filePath, registry) {
  validateMatchRegistryIntegrity(registry);
  fs.writeFileSync(filePath, JSON.stringify(registry, null, 2) + '\n');
}

// Chave de identidade de fonte = (sourceNamespace, sourceRef) — mesma
// uniqueness real de match_source_refs no banco. `sourceType` NUNCA entra
// aqui (é classificação semântica, não namespace) — isso é o que permite
// 'goias_passport:abc' e 'juventude_passport:abc' coexistirem sem colidir
// mesmo os 2 tendo sourceType='PASSPORT_MATCH'.
function anchorKey(a) { return `${a.sourceNamespace}:${a.sourceRef}`; }

export function validateMatchRegistryIntegrity(registry) {
  const seenKeys = new Set();
  const seenIds = new Set();
  const anchorOwner = new Map(); // anchorKey -> canonicalMatchKey, só entre entradas ACTIVE
  for (const e of registry.entries) {
    const seq = parseInt(String(e.canonicalMatchKey).split(':').pop(), 10);
    if (!Number.isInteger(seq) || seq < 1) throw new Error(`Registry de partidas corrompido: canonicalMatchKey "${e.canonicalMatchKey}" sem sequência válida.`);
    if (seq >= registry.nextSequence) throw new Error(`Registry de partidas corrompido: "${e.canonicalMatchKey}" (seq ${seq}) é >= nextSequence (${registry.nextSequence}).`);
    if (seenKeys.has(e.canonicalMatchKey)) throw new Error(`Registry de partidas corrompido: canonicalMatchKey duplicado "${e.canonicalMatchKey}".`);
    seenKeys.add(e.canonicalMatchKey);
    if (seenIds.has(e.matchId)) throw new Error(`Registry de partidas corrompido: matchId duplicado "${e.matchId}" (em "${e.canonicalMatchKey}").`);
    seenIds.add(e.matchId);
    if (e.status && e.status !== 'ACTIVE' && e.status !== 'SUPERSEDED') throw new Error(`Registry de partidas corrompido: status inválido "${e.status}" em "${e.canonicalMatchKey}".`);
    if (e.status === 'SUPERSEDED') {
      if (!e.supersededByCanonicalMatchKey) throw new Error(`Registry de partidas corrompido: "${e.canonicalMatchKey}" está SUPERSEDED sem supersededByCanonicalMatchKey.`);
      const survivor = registry.entries.find((x) => x.canonicalMatchKey === e.supersededByCanonicalMatchKey);
      if (!survivor) throw new Error(`Registry de partidas corrompido: "${e.canonicalMatchKey}" aponta pra sobrevivente inexistente "${e.supersededByCanonicalMatchKey}".`);
      if (survivor.status === 'SUPERSEDED') throw new Error(`Registry de partidas corrompido: "${e.canonicalMatchKey}" aponta pra sobrevivente ("${e.supersededByCanonicalMatchKey}") que também está SUPERSEDED.`);
      continue; // anchors de entradas SUPERSEDED não entram na checagem de posse exclusiva
    }
    for (const a of e.sourceAnchors) {
      const k = anchorKey(a);
      const owner = anchorOwner.get(k);
      if (owner && owner !== e.canonicalMatchKey) throw new Error(`Registry de partidas corrompido: anchor "${k}" pertence a 2 entradas ACTIVE ao mesmo tempo ("${owner}" e "${e.canonicalMatchKey}") — cada anchor só pode pertencer a 1 partida canônica ativa.`);
      anchorOwner.set(k, e.canonicalMatchKey);
    }
  }
  return true;
}

/**
 * Resolve o matchId pra um conjunto de anchors ATUAIS — PURA, não grava
 * nada. `currentAnchors`: [{sourceType, sourceNamespace, sourceRef}] —
 * identidade é (sourceNamespace, sourceRef); sourceType é só metadado
 * semântico.
 *  - { status: 'matched', matchId, canonicalMatchKey, entry }
 *      quando EXATAMENTE 1 entrada ACTIVE compartilha algum anchor.
 *  - { status: 'ambiguous', matches: [...] }
 *      quando 2+ entradas ACTIVE diferentes compartilham anchors
 *      DIFERENTES do mesmo candidate — NUNCA escolhe sozinho, sinal de
 *      possível SPLIT/MERGE não resolvido, precisa decisão humana.
 *  - { status: 'new' }
 *      quando nenhuma entrada casa — quem chama deve tentar a ETAPA 2
 *      (resolveMatchCandidate) antes de considerar isso "nunca visto".
 */
export function resolveMatchAnchors(registry, currentAnchors) {
  const currentKeys = new Set(currentAnchors.map(anchorKey));
  const matched = registry.entries.filter((e) => e.status !== 'SUPERSEDED' && e.sourceAnchors.some((a) => currentKeys.has(anchorKey(a))));
  if (matched.length === 1) return { status: 'matched', matchId: matched[0].matchId, canonicalMatchKey: matched[0].canonicalMatchKey, entry: matched[0] };
  if (matched.length > 1) return { status: 'ambiguous', matches: matched };
  return { status: 'new' };
}

function normalizeTeamName(name) {
  return String(name).trim().toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
}

/** Constrói a "identidade de lado" (home ou away) usada pela ETAPA 2 —
 * `clubKey` (canonicalClubKey do club registry) quando o clube já existe
 * no catálogo, senão só o nome normalizado como evidência auxiliar (nunca
 * inventa um clubKey). */
export function sideIdentity({ clubCanonicalKey = null, teamName }) {
  return { clubKey: clubCanonicalKey, normalizedName: normalizeTeamName(teamName) };
}

function identityCompatible(a, b) {
  if (a.clubKey && b.clubKey) return a.clubKey === b.clubKey;
  return a.normalizedName === b.normalizedName;
}

const STRONG_KICKOFF_PRECISIONS = new Set(['DATE', 'DATETIME']);
/** Evidência temporal "forte" o bastante pra permitir auto-resolução
 * estrutural sozinha — DATE/DATETIME (dia real conhecido), nunca YEAR/
 * MONTH (o intervalo largo demais torna "candidato único hoje" um
 * acidente de dataset pequeno, não uma prova real de identidade — 2
 * fontes independentes podem descrever a MESMA partida ou 2 PARTIDAS
 * DIFERENTES dentro do mesmo ano/mês sem dado suficiente pra distinguir). */
function isTemporallyStrong(k) { return STRONG_KICKOFF_PRECISIONS.has(k.precision); }

/**
 * ETAPA 2 — só chamar depois que resolveMatchAnchors(...) devolveu
 * `{status:'new'}` (nenhum anchor conhecido). Compara `descriptor`
 * ({homeIdentity, awayIdentity, kickoff, competition, season}) contra o
 * `descriptor` guardado em cada entrada ACTIVE — NUNCA usa placar como
 * identidade. Conservador por design: exige identidade de AMBOS os lados
 * batendo E sobreposição de intervalo de kickoff; competição/temporada só
 * DESQUALIFICAM quando os 2 lados conhecem o valor e DISCORDAM (evidência
 * real contra), nunca exigidos quando desconhecidos.
 *
 * GATE de suficiência de evidência (revisão final antes do commit/push):
 * "1 candidato" sozinho NÃO basta pra auto-resolver — precisa ser 1
 * candidato INEQUÍVOCO. Só auto-resolve (EXISTING_MATCH) quando o único
 * candidato estrutural tem evidência temporal FORTE dos 2 lados (candidate
 * novo E entrada existente em DATE/DATETIME, nunca YEAR/MONTH). Quando
 * existe exatamente 1 candidato estrutural mas a precisão de qualquer um
 * dos lados é coarse (YEAR/MONTH), o resultado é `insufficient` — NEM
 * `matched` (não temos certeza o bastante) NEM `new` (já existe potencial
 * colisão, criar um matchId novo poderia estar duplicando uma partida já
 * conhecida) — fica bloqueado pra override humano.
 *  - { status: 'new' }          -> NEW_MATCH, nenhum candidato estrutural.
 *  - { status: 'matched' }      -> EXISTING_MATCH, 1 candidato INEQUÍVOCO
 *                                   (temporalmente forte dos 2 lados).
 *  - { status: 'insufficient' } -> BLOCKED_INSUFFICIENT_MATCH_IDENTITY, 1
 *                                   candidato estrutural mas precisão
 *                                   temporal insuficiente de algum lado.
 *  - { status: 'ambiguous' }    -> BLOCKED_AMBIGUOUS_MATCH, 2+ candidatos
 *                                   (a contagem de candidatos vem ANTES do
 *                                   gate de precisão — 2+ candidatos é
 *                                   ambiguidade real independente de
 *                                   quão forte é a evidência temporal).
 */
export function resolveMatchCandidate(registry, descriptor) {
  const candidates = registry.entries.filter((e) => {
    if (e.status === 'SUPERSEDED' || !e.descriptor) return false;
    const d = e.descriptor;
    if (!identityCompatible(d.homeIdentity, descriptor.homeIdentity)) return false;
    if (!identityCompatible(d.awayIdentity, descriptor.awayIdentity)) return false;
    if (!kickoffIntervalsOverlap(d.kickoff, descriptor.kickoff)) return false;
    if (d.competition && descriptor.competition && d.competition !== descriptor.competition) return false;
    if (d.season && descriptor.season && d.season !== descriptor.season) return false;
    return true;
  });
  if (candidates.length === 0) return { status: 'new' };
  if (candidates.length > 1) return { status: 'ambiguous', matches: candidates };
  const only = candidates[0];
  if (isTemporallyStrong(only.descriptor.kickoff) && isTemporallyStrong(descriptor.kickoff)) {
    return { status: 'matched', matchId: only.matchId, canonicalMatchKey: only.canonicalMatchKey, entry: only };
  }
  return { status: 'insufficient', matches: candidates };
}

/**
 * Orquestra as 2 etapas — usar esta função em vez de chamar
 * resolveMatchAnchors/resolveMatchCandidate manualmente. `anchors` sempre
 * obrigatório (mesmo que vazio não faz sentido — toda partida vem de
 * alguma fonte); `descriptor` obrigatório só é USADO quando a etapa 1 não
 * encontra nada.
 * Retorna um dos 4 resultados nomeados exatamente como pedido:
 *   { status:'new', resultKind:'NEW_MATCH' }
 *   { status:'matched', resultKind:'EXISTING_MATCH', matchId, canonicalMatchKey, entry, stage }
 *   { status:'insufficient', resultKind:'BLOCKED_INSUFFICIENT_MATCH_IDENTITY', matches, stage:'CANDIDATE' }
 *   { status:'ambiguous', resultKind:'BLOCKED_AMBIGUOUS_MATCH', matches, stage }
 *
 * Anchor exato (etapa 1) continua SOBERANO independente de precisão
 * temporal — a mesma identidade externa já registrada é a evidência mais
 * forte que existe, o gate de precisão (item novo desta revisão) só se
 * aplica à etapa 2 (resolução estrutural sem nenhum anchor compartilhado).
 */
export function resolveMatch(registry, { anchors, descriptor }) {
  const stage1 = resolveMatchAnchors(registry, anchors);
  if (stage1.status === 'matched') return { ...stage1, resultKind: 'EXISTING_MATCH', stage: 'ANCHOR' };
  if (stage1.status === 'ambiguous') return { ...stage1, resultKind: 'BLOCKED_AMBIGUOUS_MATCH', stage: 'ANCHOR' };

  const stage2 = resolveMatchCandidate(registry, descriptor);
  if (stage2.status === 'matched') return { ...stage2, resultKind: 'EXISTING_MATCH', stage: 'CANDIDATE' };
  if (stage2.status === 'ambiguous') return { ...stage2, resultKind: 'BLOCKED_AMBIGUOUS_MATCH', stage: 'CANDIDATE' };
  if (stage2.status === 'insufficient') return { ...stage2, resultKind: 'BLOCKED_INSUFFICIENT_MATCH_IDENTITY', stage: 'CANDIDATE' };
  return { status: 'new', resultKind: 'NEW_MATCH', stage: 'CANDIDATE' };
}

/** Registra uma partida NUNCA vista antes — só chamar depois de confirmar
 * `resolveMatch(...).status === 'new'` (ou o par anchors/candidate
 * separadamente). `descriptor` é opcional (pode ficar de fora quando a
 * fonte não dá identidade de clube nenhuma), mas sem ele a ETAPA 2 nunca
 * vai conseguir achar esta entrada no futuro — só a ETAPA 1 (anchor exato)
 * vai funcionar pra ela. */
export function registerNewMatch(registry, anchors, { registeredAt, descriptor = null } = {}) {
  const canonicalMatchKey = `goias-app:multiclub:match:${registry.nextSequence}`;
  if (registry.entries.some((e) => e.canonicalMatchKey === canonicalMatchKey)) {
    throw new Error(`Tentativa de reaproveitar canonicalMatchKey já existente: "${canonicalMatchKey}".`);
  }
  const matchId = uuidV5(MATCHES_UUID_NAMESPACE, canonicalMatchKey);
  const entry = {
    matchId,
    canonicalMatchKey,
    sourceAnchors: [...anchors].sort((a, b) => anchorKey(a).localeCompare(anchorKey(b))),
    descriptor,
    status: 'ACTIVE',
    supersededByCanonicalMatchKey: null,
    registeredAt: registeredAt || new Date().toISOString().slice(0, 10),
  };
  registry.entries.push(entry);
  registry.nextSequence += 1;
  return entry;
}

/** Acrescenta anchors NOVOS a uma entrada já casada (ex.: passport_matches
 * ligado numa 2ª rodada, ou um provider futuro). Nunca remove/substitui um
 * anchor existente — só une. Idempotente: reprocessar os mesmos anchors
 * não duplica nada. */
export function appendAnchors(entry, newAnchors) {
  const existingKeys = new Set(entry.sourceAnchors.map(anchorKey));
  for (const a of newAnchors) {
    if (!existingKeys.has(anchorKey(a))) {
      entry.sourceAnchors.push(a);
      existingKeys.add(anchorKey(a));
    }
  }
  entry.sourceAnchors.sort((a, b) => anchorKey(a).localeCompare(anchorKey(b)));
}

/** Atualiza o descriptor conhecido de uma entrada já casada — usado quando
 * um run refina dado (ex.: corrige data, resolve um clube que antes só
 * tinha nome normalizado). NUNCA muda matchId/canonicalMatchKey, só o
 * campo usado pela ETAPA 2 em runs futuros. */
export function refreshDescriptor(entry, descriptor) {
  entry.descriptor = descriptor;
}

/** MERGE — um humano decidiu que 2 entradas ACTIVE são a MESMA partida
 * (ex.: 2 imports independentes de 2 clubes diferentes criaram entradas
 * separadas antes de alguém perceber que era o mesmo jogo).
 * `survivorCanonicalMatchKey` continua ACTIVE; `supersededCanonicalMatchKey`
 * vira SUPERSEDED (nunca deletado, nunca reaproveitado) e seus anchors são
 * migrados pro sobrevivente, pra que resolveMatchAnchors() convirja
 * sozinho pro sobrevivente em runs futuros. */
export function supersedeMatch(registry, supersededCanonicalMatchKey, survivorCanonicalMatchKey) {
  const superseded = registry.entries.find((e) => e.canonicalMatchKey === supersededCanonicalMatchKey);
  const survivor = registry.entries.find((e) => e.canonicalMatchKey === survivorCanonicalMatchKey);
  if (!superseded) throw new Error(`supersedeMatch: "${supersededCanonicalMatchKey}" não existe no registry.`);
  if (!survivor) throw new Error(`supersedeMatch: sobrevivente "${survivorCanonicalMatchKey}" não existe no registry.`);
  if (superseded.status === 'SUPERSEDED') throw new Error(`supersedeMatch: "${supersededCanonicalMatchKey}" já está SUPERSEDED (por "${superseded.supersededByCanonicalMatchKey}").`);
  if (survivor.status === 'SUPERSEDED') throw new Error(`supersedeMatch: sobrevivente "${survivorCanonicalMatchKey}" está SUPERSEDED — resolva a cadeia primeiro.`);
  appendAnchors(survivor, superseded.sourceAnchors);
  superseded.status = 'SUPERSEDED';
  superseded.supersededByCanonicalMatchKey = survivorCanonicalMatchKey;
  return survivor;
}
