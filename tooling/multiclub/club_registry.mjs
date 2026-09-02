// Registro PERSISTIDO de identidade de CLUBE — mesmo princípio de
// people/spells: club_id NUNCA muda depois de atribuído, mesmo que o
// `slug`/nome do clube em `public.clubs` seja corrigido depois. O id NÃO é
// derivado do slug (uuidv5(namespace, slug)) — é derivado de um
// canonicalClubKey sequencial e imutável, exatamente como pessoas.
//
// Por que não usar o slug como base do id: slug é uma coluna de dado, pode
// ser corrigida/renomeada (ex.: erro de digitação descoberto depois) sem
// que a identidade do clube mude — se o id dependesse do slug, uma correção
// de texto trocaria o UUID e quebraria toda FK existente.
//
// `registryLookupKey` é o identificador ESTÁVEL usado só pra encontrar a
// entrada certa num run futuro do gerador — hoje coincide com o slug
// ("goias"), mas são conceitos diferentes: se o slug em `clubs.slug` for
// corrigido no futuro, o gerador continua passando o registryLookupKey
// ORIGINAL ("goias") pra achar esta mesma entrada, e só o SQL de UPDATE
// muda a coluna `slug` em si — o registry nunca precisa mudar por isso.
import fs from 'fs';
import { uuidV5 } from './person_registry.mjs';

export const CLUBS_UUID_NAMESPACE = '8c1f4e6a-2d9b-4a3c-9e7f-1b6d8a4c2f9e';

const PERMANENCE_WARNING = 'ESTE ARQUIVO É UM REGISTRY PERSISTENTE DE IDENTIDADE DE CLUBE, NÃO UM CACHE. club_id, uma vez atribuído, NUNCA muda — mesmo se slug/name/short_name forem corrigidos depois. canonicalClubKey é sequencial e NUNCA é reaproveitado.';

export function emptyClubRegistry() {
  return { version: 1, _permanenceWarning: PERMANENCE_WARNING, nextSequence: 1, entries: [] };
}

export function loadClubRegistry(filePath) {
  if (!fs.existsSync(filePath)) return emptyClubRegistry();
  const registry = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  registry._permanenceWarning = PERMANENCE_WARNING;
  validateClubRegistryIntegrity(registry);
  return registry;
}

export function saveClubRegistry(filePath, registry) {
  validateClubRegistryIntegrity(registry);
  fs.writeFileSync(filePath, JSON.stringify(registry, null, 2) + '\n');
}

export function validateClubRegistryIntegrity(registry) {
  const seenKeys = new Set();
  const seenIds = new Set();
  const seenLookup = new Set();
  for (const e of registry.entries) {
    const seq = parseInt(String(e.canonicalClubKey).split(':').pop(), 10);
    if (!Number.isInteger(seq) || seq < 1) throw new Error(`Registry de clubes corrompido: "${e.canonicalClubKey}" sem sequência válida.`);
    if (seq >= registry.nextSequence) throw new Error(`Registry de clubes corrompido: "${e.canonicalClubKey}" >= nextSequence.`);
    if (seenKeys.has(e.canonicalClubKey)) throw new Error(`Registry de clubes corrompido: canonicalClubKey duplicado "${e.canonicalClubKey}".`);
    seenKeys.add(e.canonicalClubKey);
    if (seenIds.has(e.clubId)) throw new Error(`Registry de clubes corrompido: clubId duplicado "${e.clubId}".`);
    seenIds.add(e.clubId);
    if (seenLookup.has(e.registryLookupKey)) throw new Error(`Registry de clubes corrompido: registryLookupKey duplicado "${e.registryLookupKey}".`);
    seenLookup.add(e.registryLookupKey);
  }
  return true;
}

export function resolveClubId(registry, registryLookupKey) {
  const entry = registry.entries.find((e) => e.registryLookupKey === registryLookupKey);
  if (entry) return { status: 'matched', clubId: entry.clubId, canonicalClubKey: entry.canonicalClubKey, entry };
  return { status: 'new' };
}

export function registerNewClub(registry, registryLookupKey, { registeredAt } = {}) {
  const canonicalClubKey = `goias-app:multiclub:club:${registry.nextSequence}`;
  const clubId = uuidV5(CLUBS_UUID_NAMESPACE, canonicalClubKey);
  const entry = { clubId, canonicalClubKey, registryLookupKey, registeredAt: registeredAt || new Date().toISOString().slice(0, 10) };
  registry.entries.push(entry);
  registry.nextSequence += 1;
  return entry;
}
