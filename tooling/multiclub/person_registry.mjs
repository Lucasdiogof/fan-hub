// Registro PERSISTIDO de identidade de pessoa — o `person_id` de uma pessoa
// NUNCA é recalculado a partir dos dados atuais (nome, aliases, quantidade/
// composição de fontes). Ele nasce UMA VEZ, quando a pessoa é vista pela
// primeira vez, fica gravado aqui, e todo run futuro do pipeline PROCURA
// esse registro e REUSA o id — nunca recomputa.
//
// Por que isso existe: a v1 desta preparação usava
// `uuidV5(namespace, sorted(memberKeys).join('|'))` — determinístico
// enquanto a composição de fontes não mudasse, mas QUEBRA no primeiro dia
// em que alguém adiciona uma fonte nova (ex.: `cbf`, `official_site`) a uma
// pessoa já existente: o conjunto de member keys muda, o hash muda, o UUID
// muda — inaceitável depois de existir FK apontando pro id antigo.
//
// Como funciona a partir de agora:
// - cada pessoa canônica tem um conjunto de "founding member keys"
//   (source:sourceId) — CONGELADO no momento em que ela foi registrada;
// - um run futuro casa uma pessoa NOVA (do motor+overrides) com uma entrada
//   já registrada se as founding keys da entrada forem um SUBCONJUNTO do
//   conjunto de membros atual dessa pessoa — ou seja, "toda evidência
//   original ainda está presente, não importa quanta evidência nova foi
//   somada";
// - só quando NENHUMA entrada já registrada casa é que uma pessoa nova de
//   verdade é criada (canonicalPersonKey sequencial, nunca reaproveitado).
import fs from 'fs';
import crypto from 'crypto';

// Namespace FIXO (RFC4122 UUIDv5) — gerado uma única vez, nunca deve mudar.
export const PEOPLE_UUID_NAMESPACE = '6f2b6f6e-9b3e-4f2b-8b7a-2f6e9c3d1a4b';

export function uuidV5(namespace, name) {
  const nsBytes = Buffer.from(namespace.replace(/-/g, ''), 'hex');
  const nameBytes = Buffer.from(name, 'utf8');
  const hash = crypto.createHash('sha1').update(Buffer.concat([nsBytes, nameBytes])).digest();
  const bytes = hash.subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50; // versão 5
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC4122
  const hex = bytes.toString('hex');
  return [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20, 32)].join('-');
}

// Aviso gravado DENTRO do próprio arquivo — não é só um comentário de
// código, é o campo que qualquer humano abrindo people_registry.json no
// GitHub/editor vê primeiro. Este arquivo NÃO é cache: depois que um
// person_id for usado em qualquer INSERT no Supabase, apagar/regenerar este
// arquivo do zero corrompe a FK — o pipeline recriaria pessoas com UUIDs
// NOVOS pra quem já tem linha no banco.
const PERMANENCE_WARNING = 'ESTE ARQUIVO É UM REGISTRY PERSISTENTE DE IDENTIDADE, NÃO UM CACHE. NÃO APAGAR NEM REGENERAR DO ZERO depois que qualquer person_id daqui for usado em INSERT no Supabase — isso trocaria o UUID de pessoas que já têm linha no banco e quebraria toda FK existente. person_id, uma vez atribuído, NUNCA muda (mesmo se nome/alias/fonte/posição/período mudar depois). canonicalPersonKey é sequencial e NUNCA é reaproveitado — mesmo que uma pessoa seja removida do universo canônico, o número dela fica aposentado pra sempre, nextSequence nunca volta atrás.';

export function emptyRegistry() {
  return { version: 1, _permanenceWarning: PERMANENCE_WARNING, nextSequence: 1, entries: [] };
}

export function loadRegistry(filePath) {
  if (!fs.existsSync(filePath)) return emptyRegistry();
  const registry = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  registry._permanenceWarning = PERMANENCE_WARNING; // sempre presente, mesmo em arquivos antigos
  validateRegistryIntegrity(registry);
  return registry;
}

export function saveRegistry(filePath, registry) {
  validateRegistryIntegrity(registry);
  fs.writeFileSync(filePath, JSON.stringify(registry, null, 2) + '\n');
}

/** Verifica de verdade (não só declara) as invariantes de permanência:
 * nenhum canonicalPersonKey duplicado, nenhum personId duplicado, nenhuma
 * chave >= nextSequence (o que indicaria uma renumeração/edição manual
 * inválida), nenhuma chave <= 0. Lança erro — quem chama decide como tratar,
 * mas o registry NUNCA deve ser salvo/usado num estado inconsistente. */
export function validateRegistryIntegrity(registry) {
  const seenKeys = new Set();
  const seenIds = new Set();
  for (const e of registry.entries) {
    const seq = parseInt(String(e.canonicalPersonKey).split(':').pop(), 10);
    if (!Number.isInteger(seq) || seq < 1) {
      throw new Error(`Registry corrompido: canonicalPersonKey "${e.canonicalPersonKey}" não tem sequência numérica válida.`);
    }
    if (seq >= registry.nextSequence) {
      throw new Error(`Registry corrompido: "${e.canonicalPersonKey}" (seq ${seq}) é >= nextSequence (${registry.nextSequence}) — indica edição manual ou renumeração inválida.`);
    }
    if (seenKeys.has(e.canonicalPersonKey)) {
      throw new Error(`Registry corrompido: canonicalPersonKey "${e.canonicalPersonKey}" duplicado — chaves NUNCA podem ser reaproveitadas.`);
    }
    seenKeys.add(e.canonicalPersonKey);
    if (seenIds.has(e.personId)) {
      throw new Error(`Registry corrompido: personId "${e.personId}" duplicado (em "${e.canonicalPersonKey}").`);
    }
    seenIds.add(e.personId);
  }
  return true;
}

/**
 * Resolve o person_id pra um conjunto de member keys ATUAL — PURA, não
 * grava nada. Devolve:
 *  - { status: 'matched', personId, canonicalPersonKey, entry }
 *      quando uma entrada já registrada casa (founding keys ⊆ currentKeys).
 *  - { status: 'ambiguous', matches: [...] }
 *      quando 2+ entradas casam ao mesmo tempo — NUNCA escolhe sozinho,
 *      quem chama precisa tratar isso como erro/bloqueio.
 *  - { status: 'new' }
 *      quando nenhuma entrada casa — quem chama decide criar (via
 *      `registerNewPerson`).
 */
export function resolvePersonId(registry, currentMemberKeys) {
  const currentSet = new Set(currentMemberKeys);
  const matches = registry.entries.filter((e) => e.foundingMemberKeys.every((k) => currentSet.has(k)));
  if (matches.length === 1) {
    return { status: 'matched', personId: matches[0].personId, canonicalPersonKey: matches[0].canonicalPersonKey, entry: matches[0] };
  }
  if (matches.length > 1) {
    return { status: 'ambiguous', matches };
  }
  return { status: 'new' };
}

/** Registra uma pessoa NUNCA vista antes — só chamar depois de confirmar
 * `resolvePersonId(...).status === 'new'`. `foundingMemberKeys` fica
 * CONGELADO daqui em diante — runs futuros só podem CASAR contra ele
 * (superset), nunca reescrevê-lo. Muta `registry` in-place (increments
 * `nextSequence`, push em `entries`) — quem chama é responsável por
 * `saveRegistry` no final. */
export function registerNewPerson(registry, currentMemberKeys, { registeredAt } = {}) {
  const canonicalPersonKey = `goias-app:multiclub:person:${registry.nextSequence}`;
  if (registry.entries.some((e) => e.canonicalPersonKey === canonicalPersonKey)) {
    throw new Error(`Tentativa de reaproveitar canonicalPersonKey já existente: "${canonicalPersonKey}" — nextSequence está incoerente com entries, corrigir o registry manualmente antes de continuar.`);
  }
  const personId = uuidV5(PEOPLE_UUID_NAMESPACE, canonicalPersonKey);
  const entry = {
    personId,
    canonicalPersonKey,
    foundingMemberKeys: [...currentMemberKeys].sort(),
    registeredAt: registeredAt || new Date().toISOString().slice(0, 10),
  };
  registry.entries.push(entry);
  registry.nextSequence += 1;
  return entry;
}
