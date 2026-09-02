// Constrói o seed de player_club_stats (+ sources) SOMENTE pro Goiás,
// SOMENTE pra pessoas já em `public.people` (96 APPROVED), e SOMENTE onde
// existe evidência resolvível.
//
// Duas granularidades, nunca uma derivando a outra por palpite:
//   CLUB_TOTAL — total conhecido pelo clube (spell_id null).
//   SPELL      — número de UMA passagem específica (spell_id preenchido),
//   SÓ quando a fonte realmente dá esse número, casado contra os spells
//   reais de player_club_spells_seed.json por sobreposição de período
//   (nunca um palpite de qual spell é qual).
//
// Precedência de CLUB_TOTAL, do mais confiável pro menos:
//   1. override.liveDataBaseline (ex.: Tadeu=400, humano+snapshot datado)
//      -> source_role BASELINE (a Etapa E vai procurar isso pelo nome do
//      campo, nunca inferir por texto de nota).
//   2. career_players.aggregate_stats (club=Goiás) — total explicitamente
//      afirmado pela fonte (source_role PRIMARY); se os club_career[i] do
//      MESMO source somam exatamente esse total, viram evidência
//      CORROBORATING do total (além de SPELL rows próprios).
//   3. squad_members: 1 única entrada Goiás -> total direto (PRIMARY)
//   4. career_players: 1 única entrada Goiás -> total direto (PRIMARY)
//   5. soma de 2+ entradas conhecidas (squad_members) — SÓ quando NENHUMA
//      agregação explícita existe E há COBERTURA COMPLETA dos spells
//      canônicos reais da pessoa (ver requireFullSpellCoverage abaixo).
//      Cada componente vira uma linha de provenance PRÓPRIA
//      (source_role DERIVED_COMPONENT) — nunca um blob opaco "somei X".
//
// Regra de cobertura completa (obrigatória pra derivar CLUB_TOTAL por
// soma): TODOS os player_club_spells reais de (person_id, club_id)
// precisam ter aparecido, cada um casado 1:1 com uma fonte que dá o
// número — pra appearances E pra goals, AVALIADOS SEPARADAMENTE. Se só
// appearances tem cobertura completa, o total sai com goals=NULL (nunca
// vira 0). Se NEM appearances tem cobertura completa, nenhum CLUB_TOTAL
// derivado é criado — as linhas SPELL individuais continuam existindo
// normalmente, só o agregado fica de fora.
//
// NUNCA deriva SPELL a partir de CLUB_TOTAL (diferença/proporção) — só na
// direção contrária (somar SPELLs conhecidos vira CLUB_TOTAL derivado).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parseYearPeriod, parseMonthPeriod } from './parse_period.mjs';
import { loadClubRegistry, resolveClubId } from './club_registry.mjs';
import { checkSpellCoverage, worstVerificationStatus } from './stats_coverage.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const CLUB_LOOKUP_KEY = 'goias';

const careerPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'career_players.json'), 'utf8'));
const squadMembers = JSON.parse(fs.readFileSync(path.join(DATA, 'squad_members.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));
const clubSpells = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_spells_seed.json'), 'utf8'));

const clubRegistry = loadClubRegistry(path.join(__dirname, 'clubs_registry.json'));
const clubResolved = resolveClubId(clubRegistry, CLUB_LOOKUP_KEY);
if (clubResolved.status !== 'matched') throw new Error('Clube "goias" não está no club registry.');
const CLUB_ID = clubResolved.clubId;

const approvedIds = new Set(insertPlan.filter((p) => p.insert_status === 'APPROVED').map((p) => p.canonical_person_id));
const careerById = new Map(careerPlayers.map((p) => [p.id, p]));
const squadById = new Map(squadMembers.map((p) => [p.id, p]));
const spellsByPersonId = new Map();
for (const s of clubSpells) {
  if (!spellsByPersonId.has(s.personId)) spellsByPersonId.set(s.personId, []);
  spellsByPersonId.get(s.personId).push(s);
}

// --- helpers de tempo (mesma convenção de build_player_club_spells_seed) ---
function monthIdx(year, month, role) { const m = month != null ? month : role === 'start' ? 1 : 12; return year * 12 + (m - 1); }
function boundaryOf(period) { return [monthIdx(period.startYear, period.startMonth, 'start'), period.isOngoing ? Infinity : monthIdx(period.endYear, period.endMonth, 'end')]; }
function overlaps(period, spell) {
  const [aS, aE] = boundaryOf(period);
  const [bS, bE] = boundaryOf({ startYear: spell.startYear, startMonth: spell.startMonth, endYear: spell.endYear, endMonth: spell.endMonth, isOngoing: spell.isOngoing });
  return aS <= bE && bS <= aE;
}
/** Casa um período-candidato contra os spells reais da pessoa — 1 match
 * -> spell; 0 ou 2+ -> null (nunca escolhe sozinho). */
function matchSpell(personId, period) {
  const spells = spellsByPersonId.get(personId) || [];
  const matches = spells.filter((s) => overlaps(period, s));
  return matches.length === 1 ? matches[0] : null;
}

const DIVERGENCE_KEYWORDS = ['diverg', 'há ledger', 'ha ledger'];
function noteFlagsDivergence(note) {
  if (!note) return false;
  return DIVERGENCE_KEYWORDS.some((k) => note.toLowerCase().includes(k));
}
/** Extrai um par "NN/MM" citado na nota como valor concorrente — só
 * quando a nota realmente cita um número concreto (ex. "há ledger com
 * 98/48"). Quando a nota só sinaliza divergência em abstrato (ex. "Há
 * divergência de escopo em fontes"), devolve null — nunca inventa o
 * número concorrente. */
function extractCompetingValue(note) {
  if (!note) return null;
  const m = note.match(/(\d+)\s*\/\s*(\d+)/);
  if (!m) return null;
  return { appearances: parseInt(m[1], 10), goals: parseInt(m[2], 10) };
}

const stats = [];
const sources = [];
const blocked = [];
const conflictsReport = [];
const partialDivergences = [];

for (const person of canonicalPeople) {
  if (!approvedIds.has(person.canonicalId)) continue;

  const careerMemberIds = person.members.filter((m) => m.source === 'career_players').map((m) => m.sourceId);
  const squadMemberIds = person.members.filter((m) => m.source === 'squad_members').map((m) => m.sourceId);
  const personSpells = spellsByPersonId.get(person.canonicalId) || [];

  let clubTotalRow = null; // { appearances, goals, verificationStatus, asOfDate, asOfMatchId, sourceRows: [...] }
  const spellCandidates = []; // [{ period, appearances, goals, verificationStatus, sourceType, sourceRef, rawValue }]

  // 0. override.spellModelImplication — appearances EXPLÍCITO vira
  //    candidate de SPELL direto (Walter 2019 = 0).
  if (person.spellModelImplication) {
    person.spellModelImplication.spells.forEach((s, idx) => {
      if (s.appearances != null) {
        spellCandidates.push({ period: parseYearPeriod(s.period), appearances: s.appearances, goals: null, verificationStatus: 'VERIFIED', sourceType: 'override_spell_model_implication', sourceRef: `${person.overrideId}:${idx}`, rawValue: s });
      }
    });
  }

  // 1. override.liveDataBaseline — prioridade máxima, source_role BASELINE
  if (person.liveDataBaseline && person.liveDataBaseline.clubSlug === CLUB_LOOKUP_KEY && person.liveDataBaseline.appearances != null) {
    clubTotalRow = {
      appearances: person.liveDataBaseline.appearances,
      goals: null,
      verificationStatus: 'VERIFIED',
      asOfDate: person.liveDataBaseline.asOfDate || null,
      asOfMatchId: person.liveDataBaseline.asOfMatchId || null,
      sourceRows: [{ sourceType: 'override_live_data_baseline', sourceRef: person.overrideId, rawValue: person.liveDataBaseline, role: 'BASELINE', asOfDate: person.liveDataBaseline.asOfDate || null }],
    };
  }

  // 2. career_players.aggregate_stats (club=Goiás) — PRIMARY; club_career
  //    que soma exatamente o total vira CORROBORATING (+ SPELL rows).
  if (!clubTotalRow) {
    for (const sid of careerMemberIds) {
      const cp = careerById.get(sid);
      if (!cp) continue;
      const agg = (cp.aggregate_stats || []).find((a) => a.club === 'Goiás');
      if (agg && agg.appearances != null) {
        const isPartial = noteFlagsDivergence(agg.note);
        const sourceRows = [{ sourceType: 'career_players_aggregate_stats', sourceRef: sid, rawValue: agg, role: 'PRIMARY', asOfDate: null }];
        const goiasEntries = cp.club_career.filter((c) => c.is_goias);
        if (goiasEntries.every((e) => e.appearances != null)) {
          const sumApp = goiasEntries.reduce((a, e) => a + e.appearances, 0);
          const sumGoals = goiasEntries.reduce((a, e) => a + (e.goals || 0), 0);
          if (sumApp === agg.appearances && (agg.goals == null || sumGoals === agg.goals)) {
            for (const e of goiasEntries) {
              spellCandidates.push({ period: parseYearPeriod(e.period), appearances: e.appearances, goals: e.goals ?? null, verificationStatus: 'VERIFIED', sourceType: 'career_players_club_career', sourceRef: sid, rawValue: e });
              sourceRows.push({ sourceType: 'career_players_club_career', sourceRef: `${sid}:${e.period}`, rawValue: e, role: 'CORROBORATING', asOfDate: null });
            }
          } else {
            conflictsReport.push({ canonicalName: person.canonicalName, issue: `career_players:${sid} club_career soma (${sumApp}) diverge do aggregate_stats (${agg.appearances}) — SPELL rows NÃO criados a partir daqui, só CLUB_TOTAL.` });
          }
        }
        clubTotalRow = { appearances: agg.appearances, goals: agg.goals ?? null, verificationStatus: isPartial ? 'PARTIAL' : 'VERIFIED', asOfDate: null, asOfMatchId: null, sourceRows };
        if (isPartial) {
          partialDivergences.push({ canonicalName: person.canonicalName, persistedValue: { appearances: agg.appearances, goals: agg.goals ?? null }, competingValue: extractCompetingValue(agg.note), reason: agg.note, source: `career_players_aggregate_stats:${sid}` });
        }
        break;
      }
    }
  }

  // 3. squad_members: 1 única entrada Goiás -> total direto (PRIMARY)
  if (!clubTotalRow) {
    for (const sid of squadMemberIds) {
      const sq = squadById.get(sid);
      if (!sq) continue;
      const goiasEntries = sq.club_history.filter((c) => c.is_goias);
      if (goiasEntries.length === 1 && goiasEntries[0].appearances != null) {
        const e = goiasEntries[0];
        clubTotalRow = {
          appearances: e.appearances, goals: e.goals ?? null,
          verificationStatus: e.data_quality === 'partial' ? 'PARTIAL' : 'VERIFIED',
          asOfDate: null, asOfMatchId: null,
          sourceRows: [{ sourceType: 'squad_members_club_history', sourceRef: sid, rawValue: e, role: 'PRIMARY', asOfDate: null }],
        };
      }
    }
  }

  // 4. career_players: 1 única entrada Goiás -> total direto (PRIMARY)
  if (!clubTotalRow) {
    for (const sid of careerMemberIds) {
      const cp = careerById.get(sid);
      if (!cp) continue;
      const goiasEntries = cp.club_career.filter((c) => c.is_goias);
      if (goiasEntries.length === 1 && goiasEntries[0].appearances != null) {
        const e = goiasEntries[0];
        clubTotalRow = {
          appearances: e.appearances, goals: e.goals ?? null, verificationStatus: 'VERIFIED',
          asOfDate: null, asOfMatchId: null,
          sourceRows: [{ sourceType: 'career_players_club_career', sourceRef: sid, rawValue: e, role: 'PRIMARY', asOfDate: null }],
        };
      }
    }
  }

  // 5. soma de 2+ entradas — SÓ com cobertura completa dos spells reais.
  if (!clubTotalRow) {
    for (const sid of squadMemberIds) {
      const sq = squadById.get(sid);
      if (!sq) continue;
      const goiasEntries = sq.club_history.filter((c) => c.is_goias);
      if (goiasEntries.length <= 1) continue;

      // casa cada entrada com um spell real — obrigatório pra cobertura
      const matchedRaw = goiasEntries.map((e) => ({ entry: e, spell: matchSpell(person.canonicalId, parseMonthPeriod(e.period)) }));
      const matchedEntries = matchedRaw.filter((m) => m.spell).map((m) => ({ spellId: m.spell.spellId, appearances: m.entry.appearances, goals: m.entry.goals }));
      const canonicalSpellIds = personSpells.map((s) => s.spellId);
      const { appearancesFullyCovered, goalsFullyCovered } = checkSpellCoverage(canonicalSpellIds, matchedEntries);

      if (!appearancesFullyCovered) {
        conflictsReport.push({ canonicalName: person.canonicalName, issue: `squad_members:${sid} tem ${goiasEntries.length} entrada(s) Goiás mas a pessoa tem ${personSpells.length} spell(s) canônico(s) — cobertura incompleta, CLUB_TOTAL derivado NÃO criado (só as linhas SPELL com evidência própria).` });
        // ainda registra os candidates de SPELL que TÊM número, mesmo sem total derivado
        for (const e of goiasEntries) {
          if (e.appearances != null) spellCandidates.push({ period: parseMonthPeriod(e.period), appearances: e.appearances, goals: e.goals ?? null, verificationStatus: e.data_quality === 'partial' ? 'PARTIAL' : 'VERIFIED', sourceType: 'squad_members_club_history', sourceRef: sid, rawValue: e });
        }
        continue;
      }

      const sumApp = goiasEntries.reduce((a, e) => a + e.appearances, 0);
      const sumGoals = goalsFullyCovered ? goiasEntries.reduce((a, e) => a + e.goals, 0) : null;
      // Propagação de qualidade: verification_status do total = PIOR
      // entre os componentes (cobertura 100% não implica VERIFIED — são
      // perguntas diferentes, ver stats_coverage.mjs).
      const componentStatuses = goiasEntries.map((e) => (e.data_quality === 'partial' ? 'PARTIAL' : 'VERIFIED'));
      clubTotalRow = {
        appearances: sumApp, goals: sumGoals,
        verificationStatus: worstVerificationStatus(componentStatuses),
        asOfDate: null, asOfMatchId: null,
        sourceRows: goiasEntries.map((e) => ({ sourceType: 'squad_members_club_history', sourceRef: `${sid}:${e.period}`, rawValue: e, role: 'DERIVED_COMPONENT', asOfDate: null })),
      };
      for (const e of goiasEntries) {
        spellCandidates.push({ period: parseMonthPeriod(e.period), appearances: e.appearances, goals: e.goals ?? null, verificationStatus: e.data_quality === 'partial' ? 'PARTIAL' : 'VERIFIED', sourceType: 'squad_members_club_history', sourceRef: sid, rawValue: e });
      }
    }
  }

  if (!clubTotalRow && spellCandidates.length === 0) {
    blocked.push({ canonicalName: person.canonicalName, canonicalId: person.canonicalId, reason: 'NO_RESOLVABLE_STATS_EVIDENCE' });
    continue;
  }

  // --- monta linhas ---
  const rowsForPerson = [];
  if (clubTotalRow) rowsForPerson.push({ scope: 'CLUB_TOTAL', spellId: null, spellOrder: null, ...clubTotalRow });
  for (const cand of spellCandidates) {
    const matched = matchSpell(person.canonicalId, cand.period);
    if (!matched) {
      conflictsReport.push({ canonicalName: person.canonicalName, issue: `Candidate de SPELL (${cand.sourceType}:${cand.sourceRef}, período ${JSON.stringify(cand.period)}) não casou com exatamente 1 spell real — descartado, nunca um palpite.` });
      continue;
    }
    rowsForPerson.push({
      scope: 'SPELL', spellId: matched.spellId, spellOrder: matched.spellOrder,
      appearances: cand.appearances, goals: cand.goals, verificationStatus: cand.verificationStatus,
      asOfDate: null, asOfMatchId: null,
      sourceRows: [{ sourceType: cand.sourceType, sourceRef: cand.sourceRef, rawValue: cand.rawValue, role: 'PRIMARY', asOfDate: null }],
    });
  }

  for (const row of rowsForPerson) {
    const statRow = {
      personId: person.canonicalId,
      canonicalName: person.canonicalName,
      clubId: CLUB_ID,
      clubSlug: CLUB_LOOKUP_KEY,
      spellId: row.spellId,
      spellOrder: row.spellOrder,
      statsScope: row.scope,
      appearances: row.appearances,
      goals: row.goals,
      verificationStatus: row.verificationStatus,
      asOfDate: row.asOfDate,
      asOfMatchId: row.asOfMatchId,
    };
    stats.push(statRow);
    // 1 linha de provenance por (source_type, source_ref, role) — nunca
    // um blob opaco: dá pra reconstruir A + B -> CLUB_TOTAL consultando
    // direto as linhas DERIVED_COMPONENT deste stat.
    const seenKeys = new Set();
    for (const sr of row.sourceRows) {
      const key = `${sr.sourceType}|${sr.sourceRef}|${sr.role}`;
      if (seenKeys.has(key)) continue;
      seenKeys.add(key);
      sources.push({
        personId: person.canonicalId, clubSlug: CLUB_LOOKUP_KEY, spellId: row.spellId, statsScope: row.scope,
        sourceType: sr.sourceType, sourceRef: sr.sourceRef, rawValue: sr.rawValue, sourceRole: sr.role, asOfDate: sr.asOfDate,
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Stats do build
// ---------------------------------------------------------------------------
const peopleWithStats = new Set(stats.map((s) => s.personId));
const peopleWithClubTotal = new Set(stats.filter((s) => s.statsScope === 'CLUB_TOTAL').map((s) => s.personId));
const peopleWithSpellStats = new Set(stats.filter((s) => s.statsScope === 'SPELL').map((s) => s.personId));
const verifiedCount = stats.filter((s) => s.verificationStatus === 'VERIFIED').length;
const partialCount = stats.filter((s) => s.verificationStatus === 'PARTIAL').length;
const appearancesKnown = stats.filter((s) => s.appearances != null).length;
const goalsKnown = stats.filter((s) => s.goals != null).length;
const appearancesZero = stats.filter((s) => s.appearances === 0).length;
const goalsZero = stats.filter((s) => s.goals === 0).length;

const eligibilityByPerson = new Map();
for (const s of stats) {
  const cur = eligibilityByPerson.get(s.personId) || 'NONE';
  if (s.verificationStatus === 'VERIFIED') eligibilityByPerson.set(s.personId, 'APPROVED');
  else if (cur !== 'APPROVED') eligibilityByPerson.set(s.personId, 'PARTIAL');
}
const eligApproved = [...eligibilityByPerson.values()].filter((v) => v === 'APPROVED').length;
const eligPartial = [...eligibilityByPerson.values()].filter((v) => v === 'PARTIAL').length;

const sourcesByRole = {};
for (const s of sources) sourcesByRole[s.sourceRole] = (sourcesByRole[s.sourceRole] || 0) + 1;

const buildStats = {
  approvedPeopleTotal: approvedIds.size,
  peopleWithAnyStats: peopleWithStats.size,
  peopleWithClubTotal: peopleWithClubTotal.size,
  peopleWithSpellStats: peopleWithSpellStats.size,
  peopleBlocked: blocked.length,
  eligibilityApproved: eligApproved,
  eligibilityPartial: eligPartial,
  eligibilityBlocked: blocked.length,
  totalStatRows: stats.length,
  clubTotalRows: stats.filter((s) => s.statsScope === 'CLUB_TOTAL').length,
  spellRows: stats.filter((s) => s.statsScope === 'SPELL').length,
  verifiedRows: verifiedCount,
  partialRows: partialCount,
  totalSourceRows: sources.length,
  sourceRowsByRole: sourcesByRole,
  appearancesKnown, goalsKnown,
  appearancesNull: stats.length - appearancesKnown,
  goalsNull: stats.length - goalsKnown,
  appearancesZeroExplicit: appearancesZero,
  goalsZeroExplicit: goalsZero,
  partialDivergences,
  conflictsReport,
  blocked: blocked.sort((a, b) => a.canonicalName.localeCompare(b.canonicalName)),
};

fs.writeFileSync(path.join(OUT_DIR, 'player_club_stats_seed.json'), JSON.stringify(stats, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_club_stat_sources_seed.json'), JSON.stringify(sources, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_club_stats_seed_stats.json'), JSON.stringify(buildStats, null, 2) + '\n');

console.log(JSON.stringify(buildStats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
