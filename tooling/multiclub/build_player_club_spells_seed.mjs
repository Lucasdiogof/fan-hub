// Constrói o seed de player_club_spells (+ sources) SOMENTE pro Goiás,
// SOMENTE pra pessoas já APPROVED em people, e SOMENTE onde existe
// evidência estruturada suficientemente clara de período.
//
// spell = período CONTÍNUO de vínculo, NÃO um contrato individual. Duas
// entradas estruturadas (ex.: squad_members.club_history) que descrevem a
// MESMA passagem vista em 2 momentos contratuais diferentes (empréstimo
// -> compra definitiva, renovação, troca administrativa) são MESCLADAS
// numa linha só — relationship_type vira dado de PROVENANCE (por
// registro-fonte), nunca de identidade do spell.
//
// Regra de mesclagem — SÓ 3 condições, nunca uma heurística de "gap
// pequeno + mudou o tipo de contrato" (essa combinação já produziu 1 falso
// positivo real: Luiz Felipe teria mesclado por LOAN->PERMANENT com 1 mês
// de gap, mas é exatamente o padrão "empréstimo termina, saiu, foi
// recontratado depois" que não dá pra distinguir de uma saída real sem
// evidência extra — a heurística foi REMOVIDA):
//   A) segmentos se SOBREPÕEM;
//   B) são CONTÍGUOS SEM LACUNA REAL na precisão disponível (só quando
//      AMBOS os segmentos têm precisão MONTH/DATE — YEAR nunca é preciso
//      o bastante pra provar ausência de lacuna);
//   C) existe `continuousSpellOverride` humano estruturado pro (pessoa,
//      clube) — ver Tadeu (tadeu_annotation), continuidade confirmada
//      apesar do gap detectável seria zero de qualquer forma (case B já
//      cobre, o override fica como confirmação humana registrada).
// Ver mergeSegmentsIntoSpells() pra implementação exata.
//
// Fontes Tier 1 (APPROVED): career_players.club_career (is_goias),
// squad_members.club_history (is_goias), override.spellModelImplication
// (substitui, não soma, as 2 anteriores quando presente). Tier 2
// (PROVISIONAL): lineup_matches com matchIdFilter curado, só quando não há
// Tier 1.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parseYearPeriod, parseMonthPeriod, yearRangeFromDates } from './parse_period.mjs';
import { loadSpellRegistry, saveSpellRegistry, resolveSpellGroupMatches, registerNewSpell, refreshKnownBoundary } from './spell_registry.mjs';
import { loadClubRegistry, resolveClubId } from './club_registry.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;
const SPELL_REGISTRY_PATH = path.join(__dirname, 'spells_registry.json');
const CLUB_REGISTRY_PATH = path.join(__dirname, 'clubs_registry.json');

const CLUB_LOOKUP_KEY = 'goias';

const careerPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'career_players.json'), 'utf8'));
const squadMembers = JSON.parse(fs.readFileSync(path.join(DATA, 'squad_members.json'), 'utf8'));
const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));

const careerById = new Map(careerPlayers.map((p) => [p.id, p]));
const squadById = new Map(squadMembers.map((p) => [p.id, p]));
const matchById = new Map(lineupMatches.map((m) => [m.id, m]));

const approvedIds = new Set(insertPlan.filter((p) => p.insert_status === 'APPROVED').map((p) => p.canonical_person_id));
const canonicalPersonKeyById = new Map(insertPlan.map((p) => [p.canonical_person_id, p.canonical_person_key]));

const clubRegistry = loadClubRegistry(CLUB_REGISTRY_PATH);
const clubResolved = resolveClubId(clubRegistry, CLUB_LOOKUP_KEY);
if (clubResolved.status !== 'matched') throw new Error(`Clube "${CLUB_LOOKUP_KEY}" não está no club registry — rode generate_clubs_seed.mjs primeiro.`);
const CLUB_ID = clubResolved.clubId;
const CLUB_CANONICAL_KEY = clubResolved.canonicalClubKey;

// --- helpers de tempo ---
function monthIdx(year, month, boundaryRole) {
  const m = month != null ? month : boundaryRole === 'start' ? 1 : 12;
  return year * 12 + (m - 1);
}
function endIdx(period) {
  return period.isOngoing ? Infinity : monthIdx(period.endYear, period.endMonth, 'end');
}
function startIdx(period) {
  return monthIdx(period.startYear, period.startMonth, 'start');
}
function overlapsOrTouches(a, b, graceMonths = 0) {
  return startIdx(a) <= endIdx(b) + graceMonths && startIdx(b) <= endIdx(a) + graceMonths;
}
/** Escolhe o valor de fronteira (start ou end) mais ESPECÍFICO entre um
 * grupo de períodos — nunca deixa um YEAR-only "vencer" um MONTH-precision
 * do MESMO ano só porque o índice-mês conservador (usado só pra detectar
 * sobreposição) assumiu mês 1/12. Só um ANO estritamente mais
 * extremo (mais cedo pro start, mais tarde pro end) é informação real o
 * bastante pra vencer um valor mais preciso. */
function pickBoundaryValue(periods, role) {
  const ongoingOnes = role === 'end' ? periods.filter((p) => p.isOngoing) : [];
  if (ongoingOnes.length) return { year: null, month: null, precision: null };
  const yearOf = (p) => (role === 'start' ? p.startYear : p.endYear);
  const monthOf = (p) => (role === 'start' ? p.startMonth : p.endMonth);
  const extremeYear = role === 'start' ? Math.min(...periods.map(yearOf)) : Math.max(...periods.map(yearOf));
  const atExtremeYear = periods.filter((p) => yearOf(p) === extremeYear);
  const withMonth = atExtremeYear.filter((p) => monthOf(p) != null);
  if (withMonth.length) {
    const best = withMonth.reduce((a, b) => {
      const better = role === 'start' ? monthOf(b) < monthOf(a) : monthOf(b) > monthOf(a);
      return better ? b : a;
    });
    return { year: extremeYear, month: monthOf(best), precision: best.precision };
  }
  return { year: extremeYear, month: null, precision: atExtremeYear[0].precision };
}

function isContainedIn(inner, outerUnionPeriods) {
  const innerStart = startIdx(inner);
  const innerEnd = endIdx(inner);
  const sorted = [...outerUnionPeriods].sort((a, b) => startIdx(a) - startIdx(b));
  let covered = innerStart;
  for (const o of sorted) {
    if (startIdx(o) > covered + 1) break;
    if (endIdx(o) >= covered) covered = Math.max(covered, endIdx(o));
    if (covered >= innerEnd) return true;
  }
  return covered >= innerEnd;
}

// --- coleta de segmentos Tier 1 ---
function careerSegments(person) {
  const out = [];
  for (const m of person.members) {
    if (m.source !== 'career_players') continue;
    const cp = careerById.get(m.sourceId);
    if (!cp) continue;
    cp.club_career.forEach((c, index) => {
      if (!c.is_goias) return;
      out.push({
        source: 'career_players', sourceId: m.sourceId, index,
        period: parseYearPeriod(c.period),
        relationshipType: c.loan === true ? 'LOAN' : c.loan === false ? 'PERMANENT' : 'UNKNOWN',
        verificationStatus: 'VERIFIED',
        sourceRecordKey: `career_players:${m.sourceId}:club_career:${index}`,
      });
    });
  }
  return out;
}
function squadSegments(person) {
  const out = [];
  for (const m of person.members) {
    if (m.source !== 'squad_members') continue;
    const sq = squadById.get(m.sourceId);
    if (!sq) continue;
    sq.club_history.forEach((c, index) => {
      if (!c.is_goias) return;
      out.push({
        source: 'squad_members', sourceId: m.sourceId, index,
        period: parseMonthPeriod(c.period),
        relationshipType: c.loan === true ? 'LOAN' : c.loan === false ? 'PERMANENT' : 'UNKNOWN',
        verificationStatus: c.data_quality === 'partial' ? 'PARTIAL' : 'VERIFIED',
        sourceRecordKey: `squad_members:${m.sourceId}:club_history:${index}`,
      });
    });
  }
  return out;
}
function overrideSegments(person) {
  if (!person.spellModelImplication) return [];
  return person.spellModelImplication.spells.map((s, index) => ({
    source: 'override', sourceId: person.overrideId, index,
    period: parseYearPeriod(s.period),
    relationshipType: s.registrationType === 'loan' ? 'LOAN' : s.registrationType === 'permanent' ? 'PERMANENT' : 'UNKNOWN',
    verificationStatus: 'VERIFIED',
    sourceRecordKey: `override:${person.overrideId}:spell_model_implication:${index}`,
    note: s.note,
  }));
}

// --- mescla segmentos em spells — SÓ 3 condições, nunca uma heurística
//     combinada de gap+relationship_type (isso já produziu 1 falso
//     positivo real: Luiz Felipe teria mesclado por "gap pequeno + LOAN->
//     PERMANENT", mas é EXATAMENTE o padrão "empréstimo termina, jogador
//     sai, é recontratado depois" que não podemos distinguir de uma saída
//     real sem evidência adicional — por isso não existe mais).
//
//   A) segmentos se SOBREPÕEM;
//   B) são CONTÍGUOS SEM LACUNA REAL na precisão disponível — só quando
//      AMBOS os segmentos têm precisão MONTH/DATE (nunca YEAR: um "2001"
//      seguido de um "2002" não prova ausência de lacuna, YEAR não tem
//      resolução pra afirmar isso) E o índice-mês mostra 0 meses
//      realmente pulados;
//   C) existe `continuousSpellOverride` humano pro (pessoa, clube) —
//      força mesclar TODOS os segmentos Tier 1 daquele clube, disponível
//      via `forceMergeClubSlugs` (um Set passado pelo chamador).
function mergeSegmentsIntoSpells(segments, forceMergeClubSlugs) {
  if (!segments.length) return [];
  if (forceMergeClubSlugs && forceMergeClubSlugs.size) {
    // Caso C — mescla tudo numa mesma passagem, sem checar contiguidade.
    const sorted = [...segments].sort((a, b) => startIdx(a.period) - startIdx(b.period));
    return finalizeGroups([sorted]);
  }
  const sorted = [...segments].sort((a, b) => startIdx(a.period) - startIdx(b.period));
  const groups = [[sorted[0]]];
  for (let i = 1; i < sorted.length; i++) {
    const seg = sorted[i];
    const currentGroup = groups[groups.length - 1];
    const groupEndSeg = currentGroup.reduce((acc, s) => (endIdx(s.period) > endIdx(acc) ? s : acc), currentGroup[0]);
    const groupEndPeriod = groupEndSeg.period;
    const overlaps = overlapsOrTouches(groupEndPeriod, seg.period, 0); // caso A: sobreposição real (grace=0 já exclui "encostar" sem sobrepor de verdade)
    const bothPreciseEnough = groupEndPeriod.precision !== 'YEAR' && seg.period.precision !== 'YEAR';
    // diff==1 => 0 meses pulados (dez termina, jan começa é o mínimo
    // possível dado o índice-mês ser 0-based dentro do ano); diff>1 => há
    // lacuna real na precisão disponível.
    const zeroGapAtPrecision = bothPreciseEnough && (startIdx(seg.period) - endIdx(groupEndPeriod) === 1);
    if (overlaps || zeroGapAtPrecision) {
      currentGroup.push(seg);
    } else {
      groups.push([seg]);
    }
  }
  return finalizeGroups(groups);
}

function finalizeGroups(groups) {
  return groups.map((group) => {
    // Escolhe a fronteira do grupo por ESPECIFICIDADE, não pelo índice-mês
    // conservador usado só pra detectar sobreposição — um segmento
    // YEAR-only ("2019") não "começa em janeiro" de verdade, só não sabe o
    // mês. Se outro segmento do MESMO grupo souber o mês daquele ano, o
    // mês real vence; YEAR-only só domina quando seu ANO é estritamente
    // anterior a todo mundo (aí é informação real, não suposição).
    const isOngoing = group.some((s) => s.period.isOngoing);
    const start = pickBoundaryValue(group.map((s) => s.period), 'start');
    const end = pickBoundaryValue(group.map((s) => s.period), 'end');
    const boundary = {
      startYear: start.year, startMonth: start.month,
      endYear: isOngoing ? null : end.year, endMonth: isOngoing ? null : end.month,
      isOngoing,
      startPrecision: start.precision,
      endPrecision: isOngoing ? null : end.precision,
    };
    const otherPeriods = (excl) => group.filter((s) => s !== excl).map((s) => s.period);
    const segmentsWithRole = group.map((s) => ({
      ...s,
      evidenceType: isContainedIn(s.period, otherPeriods(s)) ? 'CORROBORATING' : 'PRIMARY',
    }));
    return { boundary, segments: segmentsWithRole };
  });
}

const spellRegistry = loadSpellRegistry(SPELL_REGISTRY_PATH);

const spells = [];
const sources = [];
const blocked = [];
const ambiguousMatches = [];
const mergeDecisions = [];

for (const person of canonicalPeople) {
  if (!approvedIds.has(person.canonicalId)) continue;
  const canonicalPersonKey = canonicalPersonKeyById.get(person.canonicalId);
  if (!canonicalPersonKey) throw new Error(`Sem canonicalPersonKey pra ${person.canonicalName}.`);

  const override = overrideSegments(person);
  const tier1Raw = override.length ? override : [...careerSegments(person), ...squadSegments(person)];

  const forceMergeClubSlugs = new Set();
  if (person.continuousSpellOverride && person.continuousSpellOverride.clubSlug === CLUB_LOOKUP_KEY) {
    forceMergeClubSlugs.add(CLUB_LOOKUP_KEY);
  }

  let mergedGroups = mergeSegmentsIntoSpells(tier1Raw, forceMergeClubSlugs);
  let tierUsed = mergedGroups.length ? 'TIER1' : null;

  if (mergedGroups.length > 1 || (mergedGroups.length === 1 && mergedGroups[0].segments.length > 1)) {
    mergeDecisions.push({
      canonicalName: person.canonicalName,
      rawSegmentCount: tier1Raw.length,
      mergedSpellCount: mergedGroups.length,
      groups: mergedGroups.map((g) => ({
        boundary: `${g.boundary.startYear}${g.boundary.startMonth ? '/' + g.boundary.startMonth : ''}-${g.boundary.isOngoing ? 'atual' : (g.boundary.endYear + (g.boundary.endMonth ? '/' + g.boundary.endMonth : ''))}`,
        segments: g.segments.map((s) => `${s.sourceRecordKey} [${s.relationshipType}] ${s.evidenceType}`),
      })),
    });
  }

  if (!mergedGroups.length) {
    const tier2 = [];
    for (const m of person.members) {
      if (m.source !== 'lineup_matches' || !m.matchIdFilter) continue;
      const dates = m.matchIdFilter.map((id) => matchById.get(id)?.match_date).filter(Boolean);
      if (!dates.length) continue;
      const period = yearRangeFromDates(dates);
      tier2.push({
        boundary: { startYear: period.startYear, startMonth: null, endYear: period.endYear, endMonth: null, isOngoing: false, startPrecision: 'YEAR', endPrecision: 'YEAR' },
        segments: m.matchIdFilter.map((id) => ({ source: 'lineup_matches', sourceId: id, relationshipType: 'UNKNOWN', verificationStatus: 'PARTIAL', sourceRecordKey: `lineup_matches:${id}`, evidenceType: 'PRIMARY' })),
      });
    }
    if (tier2.length) { mergedGroups = tier2; tierUsed = 'TIER2'; }
  }

  if (!mergedGroups.length) {
    const hasAnyLineupEvidence = person.members.some((mm) => mm.source === 'lineup_matches');
    blocked.push({ canonicalName: person.canonicalName, canonicalId: person.canonicalId, reason: hasAnyLineupEvidence ? 'ONLY_UNFILTERED_LINEUP_MATCHES' : 'NO_STRUCTURED_EVIDENCE' });
    continue;
  }

  mergedGroups.sort((a, b) => startIdx({ startYear: a.boundary.startYear, startMonth: a.boundary.startMonth }) - startIdx({ startYear: b.boundary.startYear, startMonth: b.boundary.startMonth }));

  // resolve TODOS os candidates deste (pessoa, clube) de uma vez — só
  // assim dá pra detectar SPLIT: 2+ candidates do MESMO run competindo
  // pela MESMA entrada existente do registry (ver spell_registry.mjs).
  // Resolver um-por-um, mutando o registry a cada match, mascararia essa
  // colisão (o 2º candidate veria o lastKnownBoundary já estreitado pelo
  // 1º e nunca saberia que estava competindo com ele).
  const matchBoundaries = mergedGroups.map((group) => ({ startYear: group.boundary.startYear, startMonth: group.boundary.startMonth, endYear: group.boundary.endYear, endMonth: group.boundary.endMonth, isOngoing: group.boundary.isOngoing }));
  const groupResolutions = resolveSpellGroupMatches(spellRegistry, canonicalPersonKey, CLUB_CANONICAL_KEY, matchBoundaries.map((boundary) => ({ boundary })));

  mergedGroups.forEach((group, i) => {
    const spellOrder = i + 1;
    const matchBoundary = matchBoundaries[i];
    const resolved = groupResolutions[i];

    if (resolved.status === 'ambiguous' || resolved.status === 'ambiguous_split') {
      ambiguousMatches.push({ canonicalName: person.canonicalName, boundary: matchBoundary, status: resolved.status, matches: resolved.matches.map((m) => m.canonicalSpellKey) });
      return; // BLOCKED_AMBIGUOUS_MATCH — nunca escolhe sozinho, precisa de override humano (spellSplitOverride)
    }

    let entry;
    if (resolved.status === 'matched') {
      entry = resolved.entry;
      refreshKnownBoundary(entry, matchBoundary);
    } else {
      entry = registerNewSpell(spellRegistry, { personCanonicalPersonKey: canonicalPersonKey, clubCanonicalKey: CLUB_CANONICAL_KEY, boundary: matchBoundary });
    }

    spells.push({
      spellId: entry.spellId,
      canonicalSpellKey: entry.canonicalSpellKey,
      personId: person.canonicalId,
      canonicalPersonKey,
      canonicalName: person.canonicalName,
      clubId: CLUB_ID,
      clubSlug: CLUB_LOOKUP_KEY,
      startYear: group.boundary.startYear,
      startMonth: group.boundary.startMonth,
      endYear: group.boundary.endYear,
      endMonth: group.boundary.endMonth,
      isOngoing: group.boundary.isOngoing,
      startPrecision: group.boundary.startPrecision,
      endPrecision: group.boundary.endPrecision,
      spellOrder,
      eligibility: tierUsed === 'TIER1' ? 'APPROVED' : 'PROVISIONAL',
      verificationStatus: group.segments.every((s) => s.verificationStatus === 'VERIFIED') ? 'VERIFIED' : 'PARTIAL',
    });

    for (const seg of group.segments) {
      sources.push({ spellId: entry.spellId, source: seg.source, sourceRecordKey: seg.sourceRecordKey, evidenceType: seg.evidenceType, relationshipType: seg.relationshipType });
    }
  });
}

saveSpellRegistry(SPELL_REGISTRY_PATH, spellRegistry);

const peopleWithSpells = new Set(spells.map((s) => s.personId));
const spellsByPerson = (id) => spells.filter((s) => s.personId === id);
const peopleWithMultipleSpellsList = [...peopleWithSpells]
  .filter((id) => spellsByPerson(id).length > 1)
  .map((id) => {
    const rows = spellsByPerson(id).sort((a, b) => a.spellOrder - b.spellOrder);
    return { canonicalName: rows[0].canonicalName, spellCount: rows.length, periods: rows.map((r) => `${r.startYear}${r.startMonth ? '/' + r.startMonth : ''}-${r.isOngoing ? 'atual' : (r.endYear + (r.endMonth ? '/' + r.endMonth : ''))}`) };
  })
  .sort((a, b) => a.canonicalName.localeCompare(b.canonicalName));

const approvedSpells = spells.filter((s) => s.eligibility === 'APPROVED');
const provisionalSpells = spells.filter((s) => s.eligibility === 'PROVISIONAL');
const ongoingSpells = spells.filter((s) => s.isOngoing);
const byStartPrecision = {}; for (const s of spells) byStartPrecision[s.startPrecision] = (byStartPrecision[s.startPrecision] || 0) + 1;
const byEndPrecision = {}; for (const s of spells) { const k = s.isOngoing ? 'ONGOING' : s.endPrecision; byEndPrecision[k] = (byEndPrecision[k] || 0) + 1; }

const stats = {
  approvedPeopleTotal: approvedIds.size,
  peopleWithAtLeastOneSpell: peopleWithSpells.size,
  peopleWithMultipleSpells: peopleWithMultipleSpellsList.length,
  peopleBlocked: blocked.length,
  totalSpellRows: spells.length,
  approvedSpellRows: approvedSpells.length,
  provisionalSpellRows: provisionalSpells.length,
  totalSpellSourceRows: sources.length,
  ongoingSpells: ongoingSpells.length,
  byStartPrecision,
  byEndPrecision,
  ambiguousMatches,
  mergeDecisions,
  blocked: blocked.sort((a, b) => a.canonicalName.localeCompare(b.canonicalName)),
  peopleWithMultipleSpellsList,
  provisionalList: provisionalSpells.map((s) => ({ canonicalName: s.canonicalName, period: `${s.startYear}-${s.endYear}` })),
};

fs.writeFileSync(path.join(OUT_DIR, 'player_club_spells_seed.json'), JSON.stringify(spells, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_club_spell_sources_seed.json'), JSON.stringify(sources, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_club_spells_seed_stats.json'), JSON.stringify(stats, null, 2) + '\n');

console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
