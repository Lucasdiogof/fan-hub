// v3.1 — funde a reconciliação automática (candidates.json) com as decisões
// humanas (player_reconciliation_overrides.json) numa ÚNICA fonte de
// verdade final: canonical_people_candidates.json. O Markdown deixa de ser
// fonte — vira uma RENDERIZAÇÃO de canonical_people_candidates.json (ver
// render_reconciliation_report.mjs). Nenhum INSERT é gerado aqui, nenhuma
// tabela é tocada, nenhum Flutter é alterado.
//
// Pipeline: automatic reconciliation (candidates.json) + human overrides
// (player_reconciliation_overrides.json) = canonical reconciliation
// (canonical_people_candidates.json + canonical_aliases.json).
//
// Cada override.target é a lista ORDENADA-POR-CONJUNTO de "source:sourceId"
// que compõem UM candidato do motor automático — casamento é por
// IGUALDADE DE CONJUNTO contra candidate.sources, nunca por nome (nomes
// mudam entre execuções do motor, a composição de fontes não).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadRegistry, saveRegistry, resolvePersonId, registerNewPerson } from './person_registry.mjs';
import { buildPrimaryNameIndex, deriveDisplayName } from './display_name.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');
const REGISTRY_PATH = path.join(TOOLING, 'people_registry.json');

const candidates = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'candidates.json'), 'utf8'));
const overridesFile = JSON.parse(fs.readFileSync(path.join(TOOLING, 'player_reconciliation_overrides.json'), 'utf8'));
const overrides = overridesFile.overrides;

function memberKey(source, sourceId) {
  return `${source}:${sourceId}`;
}

/** Chave de registro/identidade pra um membro — incorpora `matchIdFilter`
 * quando presente, senão duas pessoas de um split contextual (ex.: os dois
 * "Nicolas", cada um com um subconjunto de partidas do MESMO
 * lineup_matches:nicolas) compartilhariam a mesma chave bare
 * "lineup_matches:nicolas" e o registry não conseguiria distingui-las (bug
 * real encontrado e corrigido nesta revisão — ficava ambíguo na 2ª
 * execução do pipeline). */
function registryKey(m) {
  const base = memberKey(m.source, m.sourceId);
  return m.matchIdFilter?.length ? `${base}#${[...m.matchIdFilter].sort().join(',')}` : base;
}

function candidateKeySet(candidate) {
  return new Set(candidate.sources.map((s) => memberKey(s.source, s.sourceId)));
}

function sameSet(setA, arrB) {
  if (setA.size !== arrB.length) return false;
  return arrB.every((k) => setA.has(k));
}

function sourceRecordFor(candidate, source, sourceId) {
  return candidate.sources.find((s) => s.source === source && s.sourceId === sourceId);
}

function aliasesFor(sourceRecords, excludeName) {
  const out = new Set();
  for (const s of sourceRecords) {
    if (s.name) out.add(s.name);
    if (s.fullName) out.add(s.fullName);
    for (const a of s.aliases || []) out.add(a);
  }
  if (excludeName) out.delete(excludeName);
  return [...out];
}

const primaryNameIndex = buildPrimaryNameIndex(candidates);

// ---------------------------------------------------------------------------
// 1. Localiza, pra cada override, o(s) candidato(s) automático(s) afetado(s)
// ---------------------------------------------------------------------------

const consumedCandidateIndexes = new Set();
const warnings = [];
const appliedOverrides = [];

function findCandidateIndexByTarget(target) {
  const idx = candidates.findIndex((c) => sameSet(candidateKeySet(c), target));
  return idx;
}

for (const ov of overrides) {
  const idx = findCandidateIndexByTarget(ov.target);
  if (idx === -1) {
    warnings.push(`Override "${ov.id}": nenhum candidato automático tem exatamente o conjunto de fontes ${JSON.stringify(ov.target)} — candidates.json pode ter mudado desde que o override foi escrito. IGNORADO.`);
    continue;
  }
  if (consumedCandidateIndexes.has(idx)) {
    warnings.push(`Override "${ov.id}": candidato no índice ${idx} já foi consumido por outro override — possível overlap de target. IGNORADO.`);
    continue;
  }
  consumedCandidateIndexes.add(idx);
  appliedOverrides.push({ override: ov, candidate: candidates[idx] });
}

// ---------------------------------------------------------------------------
// 2. Aplica cada override, produzindo 1+ pessoas canônicas
// ---------------------------------------------------------------------------

const canonicalPeople = [];
// membros de splits que NÃO puderam ser atribuídos a um lado só (ex.:
// goias_players_dart:178 pro caso Nicolas) — viram alias forçadamente
// ambíguo (aponta pra TODOS os canonicalId do split), nunca fundidos.
const forcedAmbiguousAliasContributions = []; // [{ normalizedAlias, canonicalIds: [...] }]
const unassignedSourceRecords = []; // pro invariante "source records intencionalmente contextuais"

for (const { override: ov, candidate } of appliedOverrides) {
  if (ov.type === 'split') {
    const groupIndexes = [];
    for (const group of ov.resultingGroups) {
      if (!group.canonicalIdentity?.canonicalName) {
        warnings.push(`Override "${ov.id}": resultingGroup sem canonicalIdentity.canonicalName — nome de identidade humana ausente, corrigir o override.`);
      }
      const memberKeys = group.members.map((m) => registryKey(m));
      const sourceRecords = group.members.map((m) => sourceRecordFor(candidate, m.source, m.sourceId)).filter(Boolean);
      const canonicalName = group.canonicalIdentity?.canonicalName ?? '(sem nome)';
      const displayName = group.canonicalIdentity?.displayName ?? deriveDisplayName(primaryNameIndex, group.members, canonicalName);
      groupIndexes.push(canonicalPeople.length);
      canonicalPeople.push({
        _memberKeys: memberKeys,
        canonicalId: null,
        canonicalName,
        displayName,
        nameQuality: group.canonicalIdentity?.nameQuality ?? null,
        identity: group.identity,
        identityConfidence: group.identityConfidence,
        origin: 'HUMAN_VERIFIED',
        humanReviewed: true,
        overrideId: ov.id,
        overrideType: ov.type,
        reviewedAt: ov.reviewedAt,
        members: group.members,
        aliases: aliasesFor(sourceRecords, canonicalName),
        reason: ov.reason,
        evidence: ov.evidence,
        note: group.note,
        pendingVerification: ov.pendingVerification,
        futureCollisionWarning: ov.futureCollisionWarning,
      });
    }
    // valida: target inteiro precisa estar coberto por resultingGroups +
    // unassignedMembers — nunca um membro do candidato automático
    // silenciosamente esquecido.
    const assignedKeys = new Set(ov.resultingGroups.flatMap((g) => g.members.map((m) => memberKey(m.source, m.sourceId))));
    const unassigned = ov.unassignedMembers || [];
    for (const u of unassigned) assignedKeys.add(memberKey(u.source, u.sourceId));
    for (const t of ov.target) {
      if (!assignedKeys.has(t)) warnings.push(`Override "${ov.id}": membro "${t}" do target não está em NENHUM resultingGroup nem em unassignedMembers — ficaria silenciosamente perdido. Corrigir o override.`);
    }
    for (const u of unassigned) {
      const rec = sourceRecordFor(candidate, u.source, u.sourceId);
      unassignedSourceRecords.push({ source: u.source, sourceId: u.sourceId, overrideId: ov.id, reason: u.reason });
      if (!rec) continue;
      // resolvido em canonicalId de verdade DEPOIS da resolução via
      // registry — por enquanto guarda os ÍNDICES em canonicalPeople.
      for (const alias of [rec.name, rec.fullName, ...(rec.aliases || [])].filter(Boolean)) {
        forcedAmbiguousAliasContributions.push({ normalizedAlias: normalize(alias), groupIndexes });
      }
    }
  } else if (ov.type === 'reclassify') {
    if (!ov.canonicalIdentity?.canonicalName) {
      warnings.push(`Override "${ov.id}": sem canonicalIdentity.canonicalName — nome de identidade humana ausente, corrigir o override.`);
    }
    const memberKeys = ov.target;
    const members = candidate.sources.map((s) => ({ source: s.source, sourceId: s.sourceId }));
    const canonicalName = ov.canonicalIdentity?.canonicalName ?? '(sem nome)';
    const displayName = ov.canonicalIdentity?.displayName ?? deriveDisplayName(primaryNameIndex, members, canonicalName);
    canonicalPeople.push({
      _memberKeys: memberKeys,
      canonicalId: null,
      canonicalName,
      displayName,
      nameQuality: ov.canonicalIdentity?.nameQuality ?? null,
      identity: ov.newIdentity,
      identityConfidence: ov.newIdentityConfidence,
      origin: 'HUMAN_VERIFIED',
      humanReviewed: true,
      overrideId: ov.id,
      overrideType: ov.type,
      reviewedAt: ov.reviewedAt,
      members,
      aliases: aliasesFor(candidate.sources, canonicalName),
      reason: ov.reason,
      evidence: ov.evidence,
      positionModel: ov.positionModel,
      contentCorrectionNeeded: ov.contentCorrectionNeeded,
      biographicalProvenance: ov.biographicalProvenance,
      futureCollisionWarning: ov.futureCollisionWarning,
      note: ov.note,
      pendingVerification: ov.pendingVerification,
    });
  } else if (ov.type === 'annotate') {
    // Não muda identidade/membros — só anexa dado estruturado extra
    // (baseline vivo, implicação de spell) a uma classificação automática
    // que já estava correta. origin continua AUTOMATIC (a IDENTIDADE veio
    // do motor), mas humanReviewed=true e overrideId ficam registrados.
    //
    // Nome: SÓ de `ov.canonicalIdentity.canonicalName` (campo estruturado
    // explícito) — NUNCA de liveDataBaseline.personCanonicalName ou
    // spellModelImplication.personCanonicalName (esses continuam existindo
    // como documentação/evidência do baseline em si, mas o tooling não lê
    // mais neles pra decidir identidade — mudar a redação de uma nota não
    // pode mudar canonical_name). Sem canonicalIdentity, cai pro automático
    // (fullName estruturado > primaryName, nunca alias/prosa).
    const members = candidate.sources.map((s) => ({ source: s.source, sourceId: s.sourceId }));
    const canonicalName = ov.canonicalIdentity?.canonicalName ?? candidate.proposedCanonicalName;
    const displayName = ov.canonicalIdentity?.displayName ?? deriveDisplayName(primaryNameIndex, members, canonicalName);
    canonicalPeople.push({
      _memberKeys: members.map((m) => memberKey(m.source, m.sourceId)),
      canonicalId: null,
      canonicalName,
      canonicalNameSource: ov.canonicalIdentity?.canonicalName ? 'humanCanonicalIdentity' : candidate.proposedCanonicalNameSource,
      displayName,
      nameQuality: ov.canonicalIdentity?.nameQuality ?? null,
      identity: candidate.identity,
      identityConfidence: candidate.identityConfidence,
      origin: 'AUTOMATIC',
      humanReviewed: true,
      overrideId: ov.id,
      overrideType: ov.type,
      reviewedAt: ov.reviewedAt,
      members: candidate.sources.map((s) => ({ source: s.source, sourceId: s.sourceId })),
      aliases: aliasesFor(candidate.sources, canonicalName),
      reason: ov.reason,
      evidence: ov.evidence,
      liveDataBaseline: ov.liveDataBaseline,
      spellModelImplication: ov.spellModelImplication,
      primaryDataStatus: candidate.primaryDataStatus,
    });
  } else {
    warnings.push(`Override "${ov.id}": type "${ov.type}" desconhecido — ignorado.`);
  }
}

// ---------------------------------------------------------------------------
// 3. Candidatos automáticos NÃO tocados por nenhum override passam direto
// ---------------------------------------------------------------------------

let untouchedDistinctPeopleWithoutOverride = 0;

candidates.forEach((c, idx) => {
  if (consumedCandidateIndexes.has(idx)) return;
  if (c.identity === 'DISTINCT_PEOPLE') {
    untouchedDistinctPeopleWithoutOverride++;
    warnings.push(`Candidato "${c.proposedCanonicalName}" (provisionalId ${c.provisionalId}) é DISTINCT_PEOPLE mas NÃO tem override de split — mantido como 1 entrada única marcada DISTINCT_PEOPLE, NUNCA deve virar 1 linha em people sem ser desmembrado primeiro.`);
  }
  const members = c.sources.map((s) => ({ source: s.source, sourceId: s.sourceId }));
  canonicalPeople.push({
    _memberKeys: c.sources.map((s) => memberKey(s.source, s.sourceId)),
    canonicalId: null,
    canonicalName: c.proposedCanonicalName,
    canonicalNameSource: c.proposedCanonicalNameSource,
    displayName: deriveDisplayName(primaryNameIndex, members, c.proposedCanonicalName),
    nameQuality: null,
    identity: c.identity,
    identityConfidence: c.identityConfidence,
    origin: 'AUTOMATIC',
    humanReviewed: false,
    overrideId: null,
    overrideType: null,
    members,
    aliases: aliasesFor(c.sources, c.proposedCanonicalName),
    identityReason: c.identityReason,
    primaryDataStatus: c.primaryDataStatus,
    dataStatus: c.dataStatus,
  });
});

// ---------------------------------------------------------------------------
// 3.5. Resolução de person_id via REGISTRY PERSISTIDO — nunca recomputado
//    da composição de fontes. Cada pessoa canônica (já com `members`
//    finais definidos acima) procura uma entrada já registrada cujas
//    founding member keys sejam um SUBCONJUNTO dos seus membros atuais —
//    se achar, REUSA o id antigo (mesmo que membros novos tenham sido
//    somados desde então); se não achar, registra como pessoa nova
//    (canonicalPersonKey sequencial, nunca reaproveitado). Ver
//    person_registry.mjs pro porquê disso ser necessário.
// ---------------------------------------------------------------------------

const registry = loadRegistry(REGISTRY_PATH);
const preExistingEntries = [...registry.entries]; // snapshot ANTES desta execução criar pessoas novas — só entradas que já existiam podem ficar "órfãs"
const registryMatchedEntryIds = new Set();
let newPeopleRegistered = 0;
let existingPeopleMatched = 0;

for (const person of canonicalPeople) {
  const resolution = resolvePersonId(registry, person._memberKeys);
  if (resolution.status === 'matched') {
    person.canonicalId = resolution.personId;
    person.canonicalPersonKey = resolution.canonicalPersonKey;
    person.idOrigin = 'REGISTRY_MATCHED';
    registryMatchedEntryIds.add(resolution.entry);
    existingPeopleMatched++;
  } else if (resolution.status === 'new') {
    const entry = registerNewPerson(registry, person._memberKeys);
    person.canonicalId = entry.personId;
    person.canonicalPersonKey = entry.canonicalPersonKey;
    person.idOrigin = 'REGISTRY_NEW';
    newPeopleRegistered++;
  } else {
    // status === 'ambiguous' — 2+ entradas do registry casam com os mesmos
    // membros atuais. NUNCA escolhe sozinho: bloqueia com um id sentinela
    // óbvio (nunca um UUID de verdade) e grita bem alto no warning.
    person.canonicalId = 'AMBIGUOUS_REGISTRY_MATCH';
    person.idOrigin = 'REGISTRY_AMBIGUOUS';
    warnings.push(`Pessoa "${person.canonicalName}" (membros: ${person._memberKeys.join(', ')}) casa com ${resolution.matches.length} entradas JÁ REGISTRADAS ao mesmo tempo (${resolution.matches.map((m) => m.canonicalPersonKey).join(', ')}) — resolução automática recusada, precisa de decisão humana antes de gerar qualquer SQL.`);
  }
  delete person._memberKeys;
}

const unmatchedRegistryEntries = preExistingEntries.filter((e) => !registryMatchedEntryIds.has(e));
if (unmatchedRegistryEntries.length) {
  for (const e of unmatchedRegistryEntries) {
    warnings.push(`Entrada do registry "${e.canonicalPersonKey}" (person_id ${e.personId}) não foi casada por NENHUMA pessoa canônica desta execução — pode indicar que a pessoa foi dividida (split) e as founding keys originais não formam mais um subconjunto de nenhum cluster único. O id NUNCA é removido automaticamente do registry — decisão humana necessária.`);
  }
}

saveRegistry(REGISTRY_PATH, registry);

// ---------------------------------------------------------------------------
// 4. canonical_aliases.json — índice nome normalizado -> pessoa(s)
//    canônica(s). Suporta 1:N de propósito (ex.: "danilo" bare aponta pras
//    DUAS pessoas Danilo depois do split) — nunca resolve ambiguidade
//    escolhendo uma sozinho.
// ---------------------------------------------------------------------------

function normalize(str) {
  return String(str)
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const aliasIndex = new Map(); // normalized alias -> [{canonicalId, canonicalName, wordCount}]

function addAlias(norm, canonicalId, canonicalName) {
  if (!norm) return;
  if (!aliasIndex.has(norm)) aliasIndex.set(norm, []);
  const bucket = aliasIndex.get(norm);
  if (!bucket.some((b) => b.canonicalId === canonicalId)) {
    bucket.push({ canonicalId, canonicalName, wordCount: norm.split(' ').length });
  }
}

for (const person of canonicalPeople) {
  const names = new Set([person.canonicalName, ...person.aliases].filter(Boolean));
  for (const raw of names) addAlias(normalize(raw), person.canonicalId, person.canonicalName);
}

// injeta as contribuições de unassignedMembers — SEMPRE força o alias a
// apontar pra TODOS os canonicalId do split, mesmo que nenhuma outra fonte
// já causasse a ambiguidade por coincidência (não depende de sorte).
for (const contrib of forcedAmbiguousAliasContributions) {
  for (const idx of contrib.groupIndexes) {
    const p = canonicalPeople[idx];
    addAlias(contrib.normalizedAlias, p.canonicalId, p.canonicalName);
  }
}

const canonicalAliases = [...aliasIndex.entries()]
  .sort(([a], [b]) => a.localeCompare(b))
  .map(([normalizedAlias, refs]) => ({
    normalizedAlias,
    status: refs.length > 1 ? 'AMBIGUOUS_ALIAS' : 'RESOLVED',
    refs,
  }));

// ---------------------------------------------------------------------------
// 5. Estatísticas finais (pós-override)
// ---------------------------------------------------------------------------

function count(pred) { return canonicalPeople.filter(pred).length; }

const finalStats = {
  totalCanonicalPeople: canonicalPeople.length,
  originalAutomaticCandidates: candidates.length,
  byIdentity: {
    EXACT_IDENTITY: count((p) => p.identity === 'EXACT_IDENTITY'),
    PROBABLE_IDENTITY: count((p) => p.identity === 'PROBABLE_IDENTITY'),
    AMBIGUOUS_IDENTITY: count((p) => p.identity === 'AMBIGUOUS_IDENTITY'),
    DISTINCT_PEOPLE_UNRESOLVED: count((p) => p.identity === 'DISTINCT_PEOPLE'),
    SINGLE_SOURCE: count((p) => p.identity === 'SINGLE_SOURCE'),
  },
  distinctPeopleClustersResolved: appliedOverrides.filter((a) => a.override.type === 'split').length,
  distinctPeopleClustersUnresolved: untouchedDistinctPeopleWithoutOverride,
  humanVerified: count((p) => p.origin === 'HUMAN_VERIFIED'),
  humanReviewedAnnotationsOnly: count((p) => p.origin === 'AUTOMATIC' && p.humanReviewed),
  automaticUntouched: count((p) => p.origin === 'AUTOMATIC' && !p.humanReviewed),
  overridesApplied: appliedOverrides.length,
  overridesTotal: overrides.length,
  overridesIgnored: overrides.length - appliedOverrides.length,
  aliasIndexSize: canonicalAliases.length,
  ambiguousAliases: canonicalAliases.filter((a) => a.status === 'AMBIGUOUS_ALIAS').length,
  identityRegistry: {
    registryPath: 'tooling/multiclub/people_registry.json',
    totalEntriesInRegistry: registry.entries.length,
    matchedExistingThisRun: existingPeopleMatched,
    newlyRegisteredThisRun: newPeopleRegistered,
    unmatchedRegistryEntries: unmatchedRegistryEntries.length,
    ambiguousRegistryMatches: count((p) => p.idOrigin === 'REGISTRY_AMBIGUOUS'),
    nextSequence: registry.nextSequence,
  },
};

// ---------------------------------------------------------------------------
// 6. Invariantes — verificadas de verdade, não só declaradas em prosa.
// ---------------------------------------------------------------------------

const totalSourceRecordsInCandidates = candidates.reduce((sum, c) => sum + c.sources.length, 0);

// Cada key "source:sourceId" pode aparecer em 1+ pessoas canônicas. Mais de
// uma só é válido quando CADA aparição tem um matchIdFilter próprio E esses
// filtros são disjuntos entre si (split contextual por partida — ex.:
// lineup_matches:nicolas dividido por data) — isso NÃO é duplicação, é o
// mecanismo pedido explicitamente. Qualquer outra forma de aparecer 2+
// vezes É uma duplicação real.
const appearancesByKey = new Map(); // key -> [{canonicalId, matchIdFilter}]
function recordAppearance(source, sourceId, canonicalId, matchIdFilter) {
  const k = memberKey(source, sourceId);
  if (!appearancesByKey.has(k)) appearancesByKey.set(k, []);
  appearancesByKey.get(k).push({ canonicalId, matchIdFilter: matchIdFilter || null });
}
for (const person of canonicalPeople) {
  for (const m of person.members) recordAppearance(m.source, m.sourceId, person.canonicalId, m.matchIdFilter);
}
for (const u of unassignedSourceRecords) recordAppearance(u.source, u.sourceId, 'UNASSIGNED', null);

const duplicateSourceRecordMappings = [];
let sourceRecordsIntentionallyContextualSplit = 0;
for (const [key, appearances] of appearancesByKey) {
  if (appearances.length <= 1) continue;
  const allHaveDisjointFilters = appearances.every((a) => a.matchIdFilter && a.matchIdFilter.length > 0)
    && appearances.every((a, i) => appearances.every((b, j) => i === j || !a.matchIdFilter.some((id) => b.matchIdFilter.includes(id))));
  if (allHaveDisjointFilters) {
    sourceRecordsIntentionallyContextualSplit++;
  } else {
    duplicateSourceRecordMappings.push({ key, owners: appearances.map((a) => a.canonicalId) });
  }
}

const canonicalIdCounts = new Map();
for (const p of canonicalPeople) canonicalIdCounts.set(p.canonicalId, (canonicalIdCounts.get(p.canonicalId) || 0) + 1);
const duplicateCanonicalIds = [...canonicalIdCounts.entries()].filter(([, n]) => n > 1).map(([id]) => id);

const peopleWithZeroMembers = canonicalPeople.filter((p) => p.members.length === 0).map((p) => p.canonicalName);

function allSourceCounts(sourceName) {
  return candidates.reduce((sum, c) => sum + c.sources.filter((s) => s.source === sourceName).length, 0);
}
const dartRecordsInCandidates = allSourceCounts('goias_players_dart');
const dartKeysAccounted = [...appearancesByKey.keys()].filter((k) => k.startsWith('goias_players_dart:')).length;

const sourceRecordsCleanlyMapped = [...appearancesByKey.values()].filter((a) => a.length === 1 && a[0].canonicalId !== 'UNASSIGNED').length;

finalStats.invariants = {
  totalSourceRecords: totalSourceRecordsInCandidates,
  sourceRecordsMappedToExactlyOnePerson: sourceRecordsCleanlyMapped,
  sourceRecordsIntentionallyContextualSplit,
  sourceRecordsIntentionallyContextualUnassigned: unassignedSourceRecords.length,
  sourceRecordsUnaccounted: totalSourceRecordsInCandidates - appearancesByKey.size,
  everySourceRecordAccounted: totalSourceRecordsInCandidates === appearancesByKey.size,
  duplicateCanonicalIds,
  noDuplicateCanonicalIds: duplicateCanonicalIds.length === 0,
  duplicateSourceRecordMappings,
  noSourceRecordMapsToTwoPeopleUnintentionally: duplicateSourceRecordMappings.length === 0,
  peopleWithZeroSourceRecords: peopleWithZeroMembers,
  noPeopleWithZeroSourceRecords: peopleWithZeroMembers.length === 0,
  goiasPlayersDartRecordsInCandidates: dartRecordsInCandidates,
  goiasPlayersDartRecordsAccounted: dartKeysAccounted,
  all215DartEntriesAccounted: dartRecordsInCandidates === 215 && dartKeysAccounted === 215,
};

// ---------------------------------------------------------------------------
// Escreve
// ---------------------------------------------------------------------------

fs.writeFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), JSON.stringify(canonicalPeople, null, 2) + '\n');
fs.writeFileSync(path.join(IN_DIR, 'canonical_aliases.json'), JSON.stringify(canonicalAliases, null, 2) + '\n');
fs.writeFileSync(path.join(IN_DIR, 'canonical_stats.json'), JSON.stringify(finalStats, null, 2) + '\n');

console.log('Overrides aplicados:', appliedOverrides.length, '/', overrides.length);
if (warnings.length) {
  console.log('\nAVISOS:');
  for (const w of warnings) console.log(' -', w);
}
console.log('\nEstatísticas finais:', JSON.stringify(finalStats, null, 2));
console.log('\nEscrito em:', IN_DIR);
