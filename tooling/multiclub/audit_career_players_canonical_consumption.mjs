// Etapa F2 — auditoria READ-ONLY: o que de `career_players` PODERIA
// consumir a fundação canônica sem perder informação nem mudar gameplay.
// NUNCA escreve em people/positions/spells/stats/career_players. NUNCA
// resolve os 9 UNRESOLVED (ficam BLOCKED_NO_PERSON_ID, sempre).
//
// Fontes: data_export/goias/career_players.json (export estrutural, pré-
// F1, mas club_career/position/aggregate_stats não mudaram desde então —
// só person_id foi adicionado depois, via career_players_person_mapping
// .json) + player_positions_seed.json + player_club_spells_seed.json +
// player_club_stats_seed.json (todos já aplicados, Etapas C/B/D).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { resolveCareerPlayersPosition } from './position_catalog.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const careerPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'career_players.json'), 'utf8'));
const personMapping = JSON.parse(fs.readFileSync(path.join(RECON, 'career_players_person_mapping.json'), 'utf8'));
const positions = JSON.parse(fs.readFileSync(path.join(RECON, 'player_positions_seed.json'), 'utf8'));
const spells = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_spells_seed.json'), 'utf8'));
const clubStats = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_stats_seed.json'), 'utf8'));

const mappingByKey = new Map(personMapping.map((m) => [m.careerPlayerKey, m]));
const positionsByPerson = new Map();
for (const p of positions) { if (!positionsByPerson.has(p.personId)) positionsByPerson.set(p.personId, []); positionsByPerson.get(p.personId).push(p); }
const spellsByPerson = new Map();
for (const s of spells) { if (!spellsByPerson.has(s.personId)) spellsByPerson.set(s.personId, []); spellsByPerson.get(s.personId).push(s); }
const clubTotalByPerson = new Map(clubStats.filter((s) => s.statsScope === 'CLUB_TOTAL').map((s) => [s.personId, s]));
const spellStatsByPerson = new Map();
for (const s of clubStats) { if (s.statsScope !== 'SPELL') continue; if (!spellStatsByPerson.has(s.personId)) spellStatsByPerson.set(s.personId, []); spellStatsByPerson.get(s.personId).push(s); }

function periodToYears(period) {
  // "2012-2013" -> {start:2012, end:2013}; "2019-atual"/"2026-atual" -> end=null (ongoing);
  // "2003" (ano único) -> start=end=2003.
  const m = period.match(/^(\d{4})(?:-(\d{4}|atual))?$/);
  if (!m) return null;
  const start = Number(m[1]);
  const end = m[2] === undefined ? start : m[2] === 'atual' ? null : Number(m[2]);
  return { start, end };
}

function classifyPosition(editorialRaw, canonicalList) {
  const { resolved: editorialCodes, unmapped } = resolveCareerPlayersPosition(editorialRaw);
  if (!canonicalList || canonicalList.length === 0) return { result: 'CANONICAL_MISSING', editorialCodes, unmapped, canonicalCodes: [] };
  const sorted = [...canonicalList].sort((a, b) => a.positionOrder - b.positionOrder);
  const canonicalCodes = sorted.map((p) => p.positionCode);
  const primary = sorted[0].positionCode;
  if (editorialCodes.length === 0) return { result: 'DIVERGENCE', editorialCodes, unmapped, canonicalCodes, reason: 'texto editorial não mapeável pro catálogo canônico' };
  const editorialSet = new Set(editorialCodes);
  const canonicalSet = new Set(canonicalCodes);
  const editorialIsSubsetOfCanonical = [...editorialSet].every((c) => canonicalSet.has(c));
  const hasExtraOutsideCanonical = [...editorialSet].some((c) => !canonicalSet.has(c));
  let result;
  if (editorialIsSubsetOfCanonical && editorialSet.has(primary)) result = 'MATCH_PRIMARY';
  else if (editorialIsSubsetOfCanonical && !editorialSet.has(primary)) result = 'MATCH_SECONDARY';
  else if (hasExtraOutsideCanonical) result = 'BROADER_EDITORIAL_LABEL';
  else result = 'DIVERGENCE';
  return { result, editorialCodes, unmapped, canonicalCodes };
}

function classifyGoiasSpells(editorialGoiasEntries, canonicalSpellList) {
  const canonical = (canonicalSpellList || []).slice().sort((a, b) => a.spellOrder - b.spellOrder);
  if (canonical.length === 0) return { result: editorialGoiasEntries.length ? 'MISSING_CANONICAL' : 'MATCH', detail: 'nenhum spell canônico encontrado' };
  if (editorialGoiasEntries.length === canonical.length) {
    // mesma contagem — compara ano a ano, ordem preservada
    let allYearsMatch = true;
    for (let i = 0; i < editorialGoiasEntries.length; i++) {
      const ey = periodToYears(editorialGoiasEntries[i].period);
      const cy = canonical[i];
      if (!ey) { allYearsMatch = false; continue; }
      const endMatches = cy.isOngoing ? ey.end === null : ey.end === cy.endYear;
      if (ey.start !== cy.startYear || !endMatches) allYearsMatch = false;
    }
    return { result: allYearsMatch ? 'MATCH' : 'DIVERGENCE', editorialCount: editorialGoiasEntries.length, canonicalCount: canonical.length };
  }
  if (editorialGoiasEntries.length === 1 && canonical.length > 1) return { result: 'LEGACY_COMBINED_MULTIPLE_SPELLS', editorialCount: 1, canonicalCount: canonical.length };
  if (editorialGoiasEntries.length < canonical.length) return { result: 'LEGACY_MISSING_SPELL', editorialCount: editorialGoiasEntries.length, canonicalCount: canonical.length, note: 'taxonomia estendida nesta etapa — não existia categoria pro caso "legado tem MENOS passagens que o canônico" (ex.: Walter 2019, appearances=0, ausente do clubCareer editorial)' };
  return { result: 'DIVERGENCE', editorialCount: editorialGoiasEntries.length, canonicalCount: canonical.length };
}

function classifyStat(editorialValue, canonicalValue) {
  if (editorialValue == null && canonicalValue == null) return 'MATCH';
  if (editorialValue != null && canonicalValue == null) return 'CANONICAL_NULL';
  if (editorialValue == null && canonicalValue != null) return 'LEGACY_NULL';
  return editorialValue === canonicalValue ? 'MATCH' : 'DIVERGENCE';
}

const audit = [];
for (const cp of careerPlayers) {
  const map = mappingByKey.get(cp.id);
  const base = { careerPlayerId: cp.id, currentAnswer: cp.answer };

  if (!map || map.status !== 'RESOLVED') {
    audit.push({ ...base, personId: null, canonicalConsumption: 'BLOCKED_NO_PERSON_ID', reason: map ? `status=${map.status}` : 'sem entrada no mapping' });
    continue;
  }

  const personId = map.personId;
  const canonicalPositions = positionsByPerson.get(personId) || [];
  const positionComparison = classifyPosition(cp.position || '', canonicalPositions);

  const editorialGoiasEntries = cp.club_career.filter((e) => e.is_goias);
  const canonicalSpells = spellsByPerson.get(personId) || [];
  const goiasSpellComparison = classifyGoiasSpells(editorialGoiasEntries, canonicalSpells);

  // total editorial pro Goiás: prioriza aggregate_stats (quando existe uma
  // entrada 'Goiás', é o total OFICIAL curado); senão, se só existe 1
  // entrada is_goias, usa ela como o total; senão fica indeterminado
  // (nunca somado às cegas por este script).
  const aggGoias = (cp.aggregate_stats || []).find((a) => a.club === 'Goiás');
  let editorialTotal = null;
  let editorialTotalSource = null;
  if (aggGoias) { editorialTotal = { appearances: aggGoias.appearances, goals: aggGoias.goals }; editorialTotalSource = 'aggregate_stats'; }
  else if (editorialGoiasEntries.length === 1) { editorialTotal = { appearances: editorialGoiasEntries[0].appearances, goals: editorialGoiasEntries[0].goals }; editorialTotalSource = 'single_club_career_entry'; }
  else { editorialTotalSource = 'INDETERMINATE_MULTIPLE_ENTRIES_NO_AGGREGATE'; }

  const canonicalTotal = clubTotalByPerson.get(personId) || null;
  const appearancesComparison = editorialTotal && canonicalTotal ? classifyStat(editorialTotal.appearances, canonicalTotal.appearances) : 'NOT_COMPARABLE';
  const goalsComparison = editorialTotal && canonicalTotal ? classifyStat(editorialTotal.goals, canonicalTotal.goals) : 'NOT_COMPARABLE';

  // "safeCanonicalConsumers" — só o que este script consegue PROVAR
  // seguro, nunca uma recomendação de substituição automática.
  const safeCanonicalConsumers = [];
  if (canonicalPositions.length > 0) safeCanonicalConsumers.push('identity_person_id');
  if (['MATCH_PRIMARY', 'MATCH_SECONDARY'].includes(positionComparison.result)) safeCanonicalConsumers.push('position_as_enrichment');
  if (goiasSpellComparison.result === 'MATCH') safeCanonicalConsumers.push('goias_spell_periods_as_enrichment');
  if (appearancesComparison === 'MATCH') safeCanonicalConsumers.push('goias_appearances_as_enrichment');
  if (goalsComparison === 'MATCH') safeCanonicalConsumers.push('goias_goals_as_enrichment');

  audit.push({
    ...base,
    personId,
    canonicalConsumption: 'ELIGIBLE_FOR_ANALYSIS',
    positionComparison,
    goiasSpellComparison,
    editorialGoiasEntries,
    canonicalSpells: canonicalSpells.map((s) => ({ spellId: s.spellId, spellOrder: s.spellOrder, startYear: s.startYear, endYear: s.endYear, isOngoing: s.isOngoing, verificationStatus: s.verificationStatus })),
    editorialTotal,
    editorialTotalSource,
    canonicalTotal: canonicalTotal ? { appearances: canonicalTotal.appearances, goals: canonicalTotal.goals, verificationStatus: canonicalTotal.verificationStatus, asOfDate: canonicalTotal.asOfDate, asOfMatchId: canonicalTotal.asOfMatchId } : null,
    appearancesComparison,
    goalsComparison,
    canonicalSpellStats: (spellStatsByPerson.get(personId) || []).map((s) => ({ spellId: s.spellId, spellOrder: s.spellOrder, appearances: s.appearances, goals: s.goals, verificationStatus: s.verificationStatus })),
    safeCanonicalConsumers,
  });
}

const resolved = audit.filter((a) => a.canonicalConsumption === 'ELIGIBLE_FOR_ANALYSIS');
const blocked = audit.filter((a) => a.canonicalConsumption === 'BLOCKED_NO_PERSON_ID');

function tally(list, fn) { const t = {}; for (const x of list) { const k = fn(x); t[k] = (t[k] || 0) + 1; } return t; }

const stats = {
  totalCareerPlayers: careerPlayers.length,
  resolved: resolved.length,
  blockedNoPersonId: blocked.length,
  blockedIds: blocked.map((b) => b.careerPlayerId).sort(),
  positionComparisonTally: tally(resolved, (a) => a.positionComparison.result),
  goiasSpellComparisonTally: tally(resolved, (a) => a.goiasSpellComparison.result),
  appearancesComparisonTally: tally(resolved, (a) => a.appearancesComparison),
  goalsComparisonTally: tally(resolved, (a) => a.goalsComparison),
  peopleWithMultipleGoiasSpells: resolved.filter((a) => a.canonicalSpells.length > 1).map((a) => ({ careerPlayerId: a.careerPlayerId, canonicalSpellCount: a.canonicalSpells.length, editorialGoiasEntryCount: a.editorialGoiasEntries.length, result: a.goiasSpellComparison.result })),
};

fs.writeFileSync(path.join(OUT_DIR, 'career_players_canonical_consumption_audit.json'), JSON.stringify(audit, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'career_players_canonical_consumption_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
