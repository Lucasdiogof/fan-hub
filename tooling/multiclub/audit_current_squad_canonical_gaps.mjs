// Etapa F4.5 — re-audita (não confia só no relatório da F4) as 2 lacunas
// que a F4 encontrou na fundação canônica do elenco atual:
//   1) squad_members RESOLVED sem player_club_spells ongoing no Goiás.
//   2) squad_members RESOLVED sem player_club_stats CLUB_TOTAL no Goiás.
// Lê exclusivamente os exports/seeds JÁ APLICADOS (Etapas B/D) + o export
// bruto de squad_members.club_history — NUNCA reconstrói reconciliação,
// NUNCA toca people/player_club_spells/player_club_stats.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const squadMembers = JSON.parse(fs.readFileSync(path.join(DATA, 'squad_members.json'), 'utf8'));
const squadMapping = JSON.parse(fs.readFileSync(path.join(RECON, 'squad_members_person_mapping.json'), 'utf8'));
const spells = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_spells_seed.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_stats_seed.json'), 'utf8'));
const spellSources = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_spell_sources_seed.json'), 'utf8'));

const resolvedRows = squadMapping.filter((m) => m.status === 'RESOLVED');
const provenanceCountBySpellId = new Map();
for (const src of spellSources) {
  provenanceCountBySpellId.set(src.spellId, (provenanceCountBySpellId.get(src.spellId) || 0) + 1);
}

const spellsByPersonId = new Map();
for (const s of spells) {
  if (s.clubSlug !== 'goias') continue;
  if (!spellsByPersonId.has(s.personId)) spellsByPersonId.set(s.personId, []);
  spellsByPersonId.get(s.personId).push(s);
}
const clubTotalByPersonId = new Map();
for (const s of stats) {
  if (s.clubSlug !== 'goias' || s.statsScope !== 'CLUB_TOTAL') continue;
  clubTotalByPersonId.set(s.personId, s);
}

const spellGaps = [];
const spellOk = [];
for (const row of resolvedRows) {
  const personSpells = spellsByPersonId.get(row.personId) || [];
  const ongoing = personSpells.filter((s) => s.isOngoing);
  const rawGoiasHistory = squadMembers.find((r) => r.id === row.squadMemberId).club_history.filter((c) => c.is_goias);
  const entry = {
    squadMemberId: row.squadMemberId,
    personId: row.personId,
    canonicalName: row.canonicalName,
    allGoiasSpells: personSpells.map((s) => ({ spellId: s.spellId, canonicalSpellKey: s.canonicalSpellKey, clubId: s.clubId, startYear: s.startYear, startMonth: s.startMonth, startDate: s.startDate ?? null, startPrecision: s.startPrecision, endYear: s.endYear, endMonth: s.endMonth, endDate: s.endDate ?? null, endPrecision: s.endPrecision, isOngoing: s.isOngoing, spellOrder: s.spellOrder, verificationStatus: s.verificationStatus, provenanceSourceCount: provenanceCountBySpellId.get(s.spellId) || 0 })),
    rawSquadMembersGoiasHistory: rawGoiasHistory,
  };
  if (ongoing.length === 1) { spellOk.push({ ...entry, gapType: 'NONE', status: 'ALREADY_CORRECT' }); continue; }
  if (ongoing.length > 1) { spellGaps.push({ ...entry, gapType: 'MULTIPLE_ONGOING_SPELLS', status: 'AMBIGUOUS' }); continue; }
  // 0 ongoing
  spellGaps.push({ ...entry, gapType: 'MISSING_ONGOING_SPELL', status: personSpells.length > 0 ? 'NEEDS_REVIEW' : 'BLOCKED_INSUFFICIENT_EVIDENCE' });
}

const statsGaps = [];
const statsOk = [];
for (const row of resolvedRows) {
  const clubTotal = clubTotalByPersonId.get(row.personId);
  const rawGoiasHistory = squadMembers.find((r) => r.id === row.squadMemberId).club_history.filter((c) => c.is_goias);
  if (clubTotal) { statsOk.push({ squadMemberId: row.squadMemberId, personId: row.personId, canonicalName: row.canonicalName, gapType: 'NONE', status: 'ALREADY_CORRECT', existingClubTotal: clubTotal }); continue; }
  statsGaps.push({
    squadMemberId: row.squadMemberId,
    personId: row.personId,
    canonicalName: row.canonicalName,
    gapType: 'MISSING_CLUB_TOTAL',
    status: 'NEEDS_REVIEW',
    rawSquadMembersGoiasHistory: rawGoiasHistory,
  });
}

const GOIAS_CLUB_ID = '4c16340d-300c-5ab2-903f-17519db9b146';

const audit = {
  resolvedSquadMembersTotal: resolvedRows.length,
  goiasClubId: GOIAS_CLUB_ID,
  // todos os person_ids do elenco atual RESOLVED — usado pra validar o
  // invariant do elenco INTEIRO na migration (não só os corrigidos).
  currentSquadPersonIds: resolvedRows.map((r) => r.personId).sort(),
  totalPlayerClubSpellsBeforeFix: spells.length,
  spellGaps,
  spellOk: spellOk.length,
  statsGaps,
  statsOk: statsOk.length,
};

fs.writeFileSync(path.join(OUT_DIR, 'current_squad_canonical_gap_audit.json'), JSON.stringify(audit, null, 2) + '\n');
console.log(JSON.stringify({ resolvedSquadMembersTotal: resolvedRows.length, spellGapsFound: spellGaps.length, spellOk: spellOk.length, statsGapsFound: statsGaps.length, statsOk: statsOk.length, spellGapIds: spellGaps.map((g) => g.squadMemberId), statsGapIds: statsGaps.map((g) => g.squadMemberId) }, null, 2));
console.log('\nEscrito em:', OUT_DIR);
