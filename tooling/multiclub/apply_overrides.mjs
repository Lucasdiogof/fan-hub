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
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TOOLING = path.join(ROOT, 'tooling', 'multiclub');

const candidates = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'candidates.json'), 'utf8'));
const overridesFile = JSON.parse(fs.readFileSync(path.join(TOOLING, 'player_reconciliation_overrides.json'), 'utf8'));
const overrides = overridesFile.overrides;

function memberKey(source, sourceId) {
  return `${source}:${sourceId}`;
}

function candidateKeySet(candidate) {
  return new Set(candidate.sources.map((s) => memberKey(s.source, s.sourceId)));
}

function sameSet(setA, arrB) {
  if (setA.size !== arrB.length) return false;
  return arrB.every((k) => setA.has(k));
}

function deterministicId(memberKeys) {
  const hash = crypto.createHash('sha256').update([...memberKeys].sort().join('|')).digest('hex');
  return [hash.slice(0, 8), hash.slice(8, 12), hash.slice(12, 16), hash.slice(16, 20), hash.slice(20, 32)].join('-');
}

function sourceRecordFor(candidate, source, sourceId) {
  return candidate.sources.find((s) => s.source === source && s.sourceId === sourceId);
}

function aliasesFor(sourceRecords) {
  const out = new Set();
  for (const s of sourceRecords) {
    if (s.name) out.add(s.name);
    if (s.fullName) out.add(s.fullName);
    for (const a of s.aliases || []) out.add(a);
  }
  return [...out];
}

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
    const groupIds = [];
    for (const group of ov.resultingGroups) {
      const memberKeys = group.members.map((m) => memberKey(m.source, m.sourceId));
      const sourceRecords = group.members.map((m) => sourceRecordFor(candidate, m.source, m.sourceId)).filter(Boolean);
      const canonicalId = deterministicId(memberKeys);
      groupIds.push(canonicalId);
      canonicalPeople.push({
        canonicalId,
        canonicalName: group.canonicalName,
        displayName: group.canonicalName,
        identity: group.identity,
        identityConfidence: group.identityConfidence,
        origin: 'HUMAN_VERIFIED',
        humanReviewed: true,
        overrideId: ov.id,
        overrideType: ov.type,
        reviewedAt: ov.reviewedAt,
        members: group.members,
        aliases: aliasesFor(sourceRecords),
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
      for (const alias of [rec.name, rec.fullName, ...(rec.aliases || [])].filter(Boolean)) {
        forcedAmbiguousAliasContributions.push({ normalizedAlias: normalize(alias), canonicalIds: groupIds });
      }
    }
  } else if (ov.type === 'reclassify') {
    const memberKeys = ov.target;
    canonicalPeople.push({
      canonicalId: deterministicId(memberKeys),
      canonicalName: ov.canonicalName,
      displayName: ov.canonicalName,
      identity: ov.newIdentity,
      identityConfidence: ov.newIdentityConfidence,
      origin: 'HUMAN_VERIFIED',
      humanReviewed: true,
      overrideId: ov.id,
      overrideType: ov.type,
      reviewedAt: ov.reviewedAt,
      members: candidate.sources.map((s) => ({ source: s.source, sourceId: s.sourceId })),
      aliases: aliasesFor(candidate.sources),
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
    canonicalPeople.push({
      canonicalId: deterministicId(candidate.sources.map((s) => memberKey(s.source, s.sourceId))),
      canonicalName: candidate.proposedCanonicalName,
      displayName: candidate.proposedCanonicalName,
      identity: candidate.identity,
      identityConfidence: candidate.identityConfidence,
      origin: 'AUTOMATIC',
      humanReviewed: true,
      overrideId: ov.id,
      overrideType: ov.type,
      reviewedAt: ov.reviewedAt,
      members: candidate.sources.map((s) => ({ source: s.source, sourceId: s.sourceId })),
      aliases: aliasesFor(candidate.sources),
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
  canonicalPeople.push({
    canonicalId: deterministicId(c.sources.map((s) => memberKey(s.source, s.sourceId))),
    canonicalName: c.proposedCanonicalName,
    displayName: c.proposedCanonicalName,
    identity: c.identity,
    identityConfidence: c.identityConfidence,
    origin: 'AUTOMATIC',
    humanReviewed: false,
    overrideId: null,
    overrideType: null,
    members: c.sources.map((s) => ({ source: s.source, sourceId: s.sourceId })),
    aliases: aliasesFor(c.sources),
    identityReason: c.identityReason,
    primaryDataStatus: c.primaryDataStatus,
    dataStatus: c.dataStatus,
  });
});

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
const idToName = new Map(canonicalPeople.map((p) => [p.canonicalId, p.canonicalName]));
for (const contrib of forcedAmbiguousAliasContributions) {
  for (const id of contrib.canonicalIds) addAlias(contrib.normalizedAlias, id, idToName.get(id));
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
