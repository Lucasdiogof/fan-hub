// Constrói o seed de player_match_appearances (+ sources) SOMENTE pro
// Goiás, SOMENTE pra pessoas já em `public.people` (96 APPROVED), e
// SOMENTE a partir de lineup_matches.json — a ÚNICA fonte com participação
// por partida que este projeto tem hoje.
//
// LIMITAÇÃO REAL DO WORKER (src/football/normalize/match_lineup.ts +
// onefootball_provider.ts), preservada aqui pra nunca ser esquecida: o
// provider atual entrega `matchLineup.lineup` (titulares) e eventos de
// substituição (`playerIn`/`playerOut`), mas NUNCA a lista completa do
// banco de reservas — não dá pra afirmar UNUSED_SUBSTITUTE de forma
// completa (quem ficou no banco sem entrar) com o dado disponível hoje. O
// schema SUPORTA UNUSED_SUBSTITUTE (participation_status tem os 3
// estados), mas nenhum sync deste provider deve inventar essa linha —
// só grava o que a fonte realmente distingue. lineup_matches.json (a
// fonte usada NESTA etapa) é só titulares (11/partida, confirmado por
// auditoria — nenhuma reserva, nenhuma substituição) — por isso TODA linha
// aqui é participation_status=STARTED.
//
// Homônimos (Nicolas, Danilo, Michael): NUNCA resolvidos aqui — só
// processamos `person.members` já reconciliados na Etapa A (com
// matchIdFilter quando havia ambiguidade). Nunca escaneamos
// lineup_matches "cru" por conta própria. Ver também a REGRA de identidade
// viva por nome (bloqueada nesta etapa) em docs/multiclub/
// 16_live_data_architecture.md §11 — não se aplica ao seed histórico (que
// nunca resolve por nome cru, só por member já reconciliado), mas rege
// qualquer sync futuro que tente resolver jogador só pelo `name` que o
// provider devolve.
//
// spell_id: resolvido por sobreposição de data contra os spells reais da
// pessoa (mesmo algoritmo de overlap das etapas anteriores) — 1 match
// único vira spell_id, 0 ou 2+ fica NULL, nunca um palpite. Quando fica
// NULL, a RAZÃO é classificada em 4 categorias auditáveis (A/B/C/D — ver
// classifySpellGap()), nunca um "sem spell" opaco.
//
// position_code: quando o valor bruto é composto ("LD/MC" — caso real do
// Dieguinho, jogou em 2 funções na MESMA partida), fica NULL na linha
// principal (1 coluna não representa 2 posições simultâneas) — o valor
// bruto INTEIRO continua preservado em raw_value na provenance, nunca
// perdido. DEF/ALA (genéricos, Etapa C) também ficam NULL.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { resolveLineupMatchesPosition } from './position_catalog.mjs';
import { loadClubRegistry, resolveClubId } from './club_registry.mjs';
import { resolveSpellForDate, classifySpellGap, NEAR_BOUNDARY_GRACE_MONTHS } from './spell_link.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const CLUB_LOOKUP_KEY = 'goias';

const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));
const clubSpells = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_spells_seed.json'), 'utf8'));
const matchesSeed = JSON.parse(fs.readFileSync(path.join(RECON, 'matches_seed.json'), 'utf8'));

const clubRegistry = loadClubRegistry(path.join(__dirname, 'clubs_registry.json'));
const clubResolved = resolveClubId(clubRegistry, CLUB_LOOKUP_KEY);
if (clubResolved.status !== 'matched') throw new Error('Clube "goias" não está no club registry.');
const CLUB_ID = clubResolved.clubId;

const approvedIds = new Set(insertPlan.filter((p) => p.insert_status === 'APPROVED').map((p) => p.canonical_person_id));
const matchByLineupId = new Map(matchesSeed.map((m) => [m.lineupMatchId, m]));
const lineupMatchById = new Map(lineupMatches.map((m) => [m.id, m]));

const spellsByPersonId = new Map();
for (const s of clubSpells) {
  if (!spellsByPersonId.has(s.personId)) spellsByPersonId.set(s.personId, []);
  spellsByPersonId.get(s.personId).push(s);
}

const appearances = [];
const sources = [];
const blocked = [];
const conflictsReport = [];
const spellCoherenceReport = []; // ambíguo/sem spell — auditável, nunca silencioso, agora com categoria A/B/C/D

for (const person of canonicalPeople) {
  if (!approvedIds.has(person.canonicalId)) continue;

  const rowsForPerson = [];

  for (const member of person.members) {
    if (member.source !== 'lineup_matches') continue;

    // conjunto de match ids que pertencem a ESTA pessoa — restrito ao
    // matchIdFilter já curado na Etapa A quando existe (caso homônimo),
    // senão TODOS os matches onde o sourceId responde.
    const matchIds = member.matchIdFilter
      ? member.matchIdFilter
      : lineupMatches.filter((m) => m.lineup.some((l) => (l.answer || '').toLowerCase() === member.sourceId.toLowerCase())).map((m) => m.id);

    for (const matchId of matchIds) {
      const rawMatch = lineupMatchById.get(matchId);
      const matchRow = matchByLineupId.get(matchId);
      if (!rawMatch || !matchRow) { conflictsReport.push({ canonicalName: person.canonicalName, issue: `lineup_matches:${matchId} não tem correspondente em matches_seed.json — appearance descartada.` }); continue; }

      const lineupEntry = rawMatch.lineup.find((l) => (l.answer || '').toLowerCase() === member.sourceId.toLowerCase());
      if (!lineupEntry) { conflictsReport.push({ canonicalName: person.canonicalName, issue: `lineup_matches:${matchId} não tem entrada pro sourceId "${member.sourceId}" apesar de listado — appearance descartada.` }); continue; }

      const { resolved: positionCodes, unmapped } = resolveLineupMatchesPosition(lineupEntry.pos);
      const positionCode = positionCodes.length === 1 ? positionCodes[0] : null;
      if (positionCodes.length > 1 || unmapped.length) {
        conflictsReport.push({ canonicalName: person.canonicalName, issue: `lineup_matches:${matchId} pos "${lineupEntry.pos}" ${positionCodes.length > 1 ? 'é composto (2+ códigos numa só partida)' : 'tem fragmento genérico não mapeável'} — position_code fica NULL na appearance, valor bruto preservado na provenance.` });
      }

      const spellsForPerson = spellsByPersonId.get(person.canonicalId) || [];
      const matchedSpell = resolveSpellForDate(spellsForPerson, rawMatch.match_date);
      if (!matchedSpell) {
        const category = classifySpellGap(spellsForPerson, rawMatch.match_date);
        const reasonBySpecies = {
          A: 'pessoa não possui nenhum spell canônico Goiás.',
          B: 'boundary de precisão YEAR perto o bastante da data pra não decidir com segurança.',
          C: 'a data cai realmente fora de todos os spells conhecidos da pessoa.',
          D: '2+ spells candidatos se sobrepõem à mesma data — ambiguidade real.',
        };
        spellCoherenceReport.push({ canonicalName: person.canonicalName, matchId, matchDate: rawMatch.match_date, category, reason: reasonBySpecies[category] });
      }

      rowsForPerson.push({
        matchId,
        canonicalMatchId: matchRow.matchId,
        participationStatus: 'STARTED',
        positionCode,
        shirtNumber: lineupEntry.no ?? null,
        verificationStatus: matchRow.verificationStatus,
        spellId: matchedSpell ? matchedSpell.spellId : null,
        sourceType: 'lineup_matches',
        sourceRef: `${matchId}:${member.sourceId}`,
        rawValue: lineupEntry,
        observedAt: rawMatch.match_date,
      });
    }
  }

  if (!rowsForPerson.length) {
    blocked.push({ canonicalName: person.canonicalName, canonicalId: person.canonicalId, reason: 'NO_LINEUP_EVIDENCE' });
    continue;
  }

  // nunca duplicar (person, club, match) mesmo que 2 members apontem pro
  // mesmo jogo por engano — dedup defensivo antes de escrever.
  const seenMatch = new Set();
  for (const row of rowsForPerson) {
    if (seenMatch.has(row.matchId)) { conflictsReport.push({ canonicalName: person.canonicalName, issue: `Duplicata descartada: 2 members resolveram a MESMA partida (${row.matchId}).` }); continue; }
    seenMatch.add(row.matchId);
    appearances.push({
      personId: person.canonicalId,
      canonicalName: person.canonicalName,
      clubSlug: CLUB_LOOKUP_KEY,
      clubId: CLUB_ID,
      lineupMatchId: row.matchId,
      canonicalMatchId: row.canonicalMatchId,
      spellId: row.spellId,
      participationStatus: row.participationStatus,
      positionCode: row.positionCode,
      shirtNumber: row.shirtNumber,
      verificationStatus: row.verificationStatus,
    });
    sources.push({
      personId: person.canonicalId,
      clubSlug: CLUB_LOOKUP_KEY,
      lineupMatchId: row.matchId,
      canonicalMatchId: row.canonicalMatchId,
      sourceType: row.sourceType,
      sourceRef: row.sourceRef,
      rawValue: row.rawValue,
      sourceRole: 'PRIMARY',
      observedAt: row.observedAt,
    });
  }
}

const peopleWithAppearances = new Set(appearances.map((a) => a.personId));
const spellDecomposition = spellCoherenceReport.reduce((acc, r) => { acc[r.category] = (acc[r.category] || 0) + 1; return acc; }, { A: 0, B: 0, C: 0, D: 0 });
const stats = {
  approvedPeopleTotal: approvedIds.size,
  peopleWithAtLeastOneAppearance: peopleWithAppearances.size,
  peopleBlocked: blocked.length,
  totalAppearanceRows: appearances.length,
  byParticipationStatus: appearances.reduce((acc, a) => { acc[a.participationStatus] = (acc[a.participationStatus] || 0) + 1; return acc; }, {}),
  workerLimitation: 'lineup_matches.json cobre SOMENTE titulares (11/partida) — provider OneFootball atual (src/football) não expõe banco de reservas completo, só lineup titular + eventos de substituição. UNUSED_SUBSTITUTE é suportado pelo schema mas NUNCA inventado por este seed nem deve ser por um sync futuro deste provider.',
  verifiedRows: appearances.filter((a) => a.verificationStatus === 'VERIFIED').length,
  partialRows: appearances.filter((a) => a.verificationStatus === 'PARTIAL').length,
  withSpellId: appearances.filter((a) => a.spellId).length,
  withoutSpellId: appearances.filter((a) => !a.spellId).length,
  spellDecomposition,
  spellDecompositionLegend: {
    A: 'pessoa não possui nenhum spell canônico Goiás',
    B: `boundary de precisão YEAR a <= ${NEAR_BOUNDARY_GRACE_MONTHS} meses da partida — precisão insuficiente pra decidir`,
    C: 'possui spell(s), mas a data cai realmente fora de todos eles',
    D: '2+ spells candidatos se sobrepõem à mesma data — ambiguidade real',
  },
  withPositionCode: appearances.filter((a) => a.positionCode).length,
  withoutPositionCode: appearances.filter((a) => !a.positionCode).length,
  totalSourceRows: sources.length,
  conflictsReport,
  spellCoherenceReport,
  blocked: blocked.sort((a, b) => a.canonicalName.localeCompare(b.canonicalName)),
};

fs.writeFileSync(path.join(OUT_DIR, 'player_match_appearances_seed.json'), JSON.stringify(appearances, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_match_appearance_sources_seed.json'), JSON.stringify(sources, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_match_appearances_seed_stats.json'), JSON.stringify(stats, null, 2) + '\n');

console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
