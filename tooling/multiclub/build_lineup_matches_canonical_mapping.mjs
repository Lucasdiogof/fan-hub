// Etapa F7 — ponte READ-ONLY entre a feature `lineup_matches` (Adivinhe a
// Escalação) e a camada canônica já construída pela Etapa E
// (matches/match_source_refs/player_match_appearances). NUNCA reconcilia
// partida de novo, NUNCA cria appearance nova, NUNCA gera DML. Só lê os
// artefatos já existentes e classifica.
//
// 3 identidades, nunca confundidas:
//   lineup_matches.id      -> chave da FEATURE (progress/ranking, intocada)
//   canonicalMatchId       -> matches.id (resolvido via match_source_refs,
//                             namespace 'goias_lineup_curated' — NUNCA
//                             recalculado aqui, só lido de matches_seed.json)
//   personId                -> people.id (resolvido via a reconciliação já
//                             aprovada — canonical_people_candidates.json +
//                             people_insert_plan.json — NUNCA por nome cru)
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));
const passportMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'passport_matches.json'), 'utf8'));
const passportById = new Map(passportMatches.map((p) => [p.id, p]));
const matchesSeed = JSON.parse(fs.readFileSync(path.join(RECON, 'matches_seed.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));
const appearances = JSON.parse(fs.readFileSync(path.join(RECON, 'player_match_appearances_seed.json'), 'utf8'));
const appearanceSources = JSON.parse(fs.readFileSync(path.join(RECON, 'player_match_appearance_sources_seed.json'), 'utf8'));

const planByPersonId = new Map(insertPlan.map((p) => [p.canonical_person_id, p]));
const matchByLineupId = new Map(matchesSeed.map((m) => [m.lineupMatchId, m]));

// sourceRef ("<lineupMatchId>:<sourceIdLower>") -> {personId, lineupMatchId}
const sourceRefOwner = new Map();
for (const s of appearanceSources) {
  if (s.sourceType !== 'lineup_matches') continue;
  sourceRefOwner.set(s.sourceRef, { personId: s.personId, lineupMatchId: s.lineupMatchId, rawValue: s.rawValue });
}
// (personId|lineupMatchId) -> appearance row
const appearanceByPersonMatch = new Map();
for (const a of appearances) appearanceByPersonMatch.set(`${a.personId}|${a.lineupMatchId}`, a);

// ============================================================================
// 6) coverage lineup_matches -> canonicalMatchId (só LÊ matches_seed.json,
//    nunca reconcilia de novo — o registry já resolveu isso na Etapa E)
// ============================================================================
const matchCoverage = [];
for (const m of lineupMatches) {
  const canonical = matchByLineupId.get(m.id);
  matchCoverage.push({
    lineupMatchId: m.id,
    canonicalMatchId: canonical ? canonical.matchId : null,
    matchStatus: canonical ? 'RESOLVED' : 'NO_CANONICAL_MATCH',
  });
}
const matchesWithCanonical = matchCoverage.filter((m) => m.canonicalMatchId).length;
const matchesWithoutCanonical = matchCoverage.filter((m) => !m.canonicalMatchId);
// 2+ canonical matches pro mesmo lineupMatchId nunca deveria ocorrer (1:1
// por construção do registry) — checado defensivamente via contagem de
// linhas em matchesSeed por lineupMatchId, nunca assumido.
const canonicalCountByLineupId = new Map();
for (const m of matchesSeed) canonicalCountByLineupId.set(m.lineupMatchId, (canonicalCountByLineupId.get(m.lineupMatchId) || 0) + 1);
const matchesWith2PlusCanonical = [...canonicalCountByLineupId.entries()].filter(([, c]) => c > 1);

// ============================================================================
// 24 catálogo de códigos canônicos, pra diff de posição (mesmo do Etapa C)
// ============================================================================
function normalizePosFragment(pos) {
  // reimplementação MÍNIMA e LOCAL só pra comparação de igualdade (nunca
  // resolve posição de novo pra gravar em lugar nenhum) — decide só se o
  // positionCode canônico já persistido é COMPATÍVEL com o pos bruto do
  // slot, nunca recalcula um valor novo.
  return pos.split('/').map((p) => p.trim().toUpperCase());
}

// ============================================================================
// 8-14, 15, 16, 20 — auditoria por SLOT
// ============================================================================
const players = []; // achatado, todos os 341 slots, pra stats/reprodutibilidade
const perMatch = [];
const homonymAudit = { danilo: [], nicolas: [], michael: [], fabiano: [], carlos_eduardo: [], luiz_felipe: [], murilo: [], murillo: [] };
const positionDiff = { MATCH: 0, CANONICAL_NULL: 0, SOURCE_NULL: 0, DIVERGENCE: 0 };
const shirtDiff = { MATCH: 0, CANONICAL_NULL: 0, SOURCE_NULL: 0, DIVERGENCE: 0 };
const duplicateSourcePlayers = []; // mesma pessoa 2x na MESMA lineup (quando personId conhecido)

for (const m of lineupMatches) {
  const canonical = matchByLineupId.get(m.id);
  const canonicalMatchId = canonical ? canonical.matchId : null;
  const matchPlayers = [];
  const seenPersonIdsThisMatch = new Map();

  m.lineup.forEach((slot, slotIndex) => {
    const sourceId = (slot.answer || '').toLowerCase();
    const sourceRef = `${m.id}:${sourceId}`;

    // candidatos: TODA pessoa canônica com member source=lineup_matches
    // cujo sourceId bate E (sem matchIdFilter OU matchIdFilter inclui
    // esta partida) — mesma regra exata usada na direção inversa por
    // build_player_match_appearances_seed.mjs, nunca uma nova heurística.
    const candidates = canonicalPeople.filter((p) =>
      p.members.some((mem) => mem.source === 'lineup_matches' && mem.sourceId.toLowerCase() === sourceId && (!mem.matchIdFilter || mem.matchIdFilter.includes(m.id))),
    );
    // candidatos que reivindicam esse sourceId em QUALQUER partida (só pra
    // diagnosticar o caso "existe mas não pra ESTE jogo", nunca pra decidir).
    const anyMatchCandidates = canonicalPeople.filter((p) => p.members.some((mem) => mem.source === 'lineup_matches' && mem.sourceId.toLowerCase() === sourceId));

    let status;
    let personId = null;
    let canonicalName = null;
    let appearanceSourceRef = null;
    let reason;

    if (candidates.length > 1) {
      status = 'AMBIGUOUS_PERSON';
      reason = `${candidates.length} pessoas canônicas reivindicam este slot exato — split não resolvido, nunca escolhido sozinho.`;
    } else if (candidates.length === 0) {
      if (anyMatchCandidates.length > 0) {
        status = 'AMBIGUOUS_PERSON';
        reason = `sourceId "${sourceId}" é reivindicado por ${anyMatchCandidates.length} pessoa(s) canônica(s) EM OUTRAS partidas, mas nenhuma tem matchIdFilter cobrindo ${m.id} — mesmo padrão do índice 178 do goias_players.dart (F6): homônimo sem dado suficiente pra decidir NESTE jogo específico, personId fica NULL.`;
      } else {
        status = 'UNRESOLVED_PERSON';
        reason = `Nenhuma pessoa canônica reivindica sourceId "${sourceId}" em nenhuma partida.`;
      }
    } else {
      const owner = candidates[0];
      if (owner.identity === 'AMBIGUOUS_IDENTITY') {
        status = 'AMBIGUOUS_PERSON';
        canonicalName = owner.canonicalName;
        reason = `A pessoa canônica "${owner.canonicalName}" tem identity=AMBIGUOUS_IDENTITY — ela mesma é uma mistura não resolvida.`;
      } else {
        const plan = planByPersonId.get(owner.canonicalId);
        if (!plan || plan.insert_status !== 'APPROVED') {
          status = 'UNRESOLVED_PERSON';
          canonicalName = owner.canonicalName;
          reason = `1 pessoa canônica encontrada (${owner.canonicalName}), mas insert_status=${plan ? plan.insert_status : 'AUSENTE'} — não aprovada.`;
        } else {
          personId = owner.canonicalId;
          canonicalName = owner.canonicalName;
          const refOwner = sourceRefOwner.get(sourceRef);
          const appearance = refOwner ? appearanceByPersonMatch.get(`${refOwner.personId}|${m.id}`) : null;
          if (refOwner && appearance && refOwner.personId === personId) {
            // integridade: o raw_value da provenance precisa bater com o
            // slot REAL de hoje — nunca confiar cegamente no link.
            const rawMatches = refOwner.rawValue && refOwner.rawValue.answer === slot.answer && refOwner.rawValue.name === slot.name;
            if (!rawMatches || appearance.participationStatus !== 'STARTED' || appearance.canonicalMatchId !== canonicalMatchId) {
              status = 'SOURCE_MISMATCH';
              reason = 'Provenance/appearance existente aponta pra este slot, mas os dados (raw_value, participation_status ou canonical_match_id) divergem do que o slot real tem hoje.';
            } else {
              status = 'RESOLVED_EXISTING_APPEARANCE';
              appearanceSourceRef = sourceRef;
              reason = 'Appearance canônica STARTED já existe e é coerente com o slot.';
            }
          } else if (refOwner && refOwner.personId !== personId) {
            status = 'SOURCE_MISMATCH';
            reason = `Existe provenance pra este sourceRef, mas aponta pra outra pessoa (${refOwner.personId}) — divergência real.`;
          } else {
            status = 'RESOLVED_PERSON_NO_APPEARANCE';
            reason = `Pessoa aprovada (${owner.canonicalName}), slot legítimo, mas nenhuma appearance canônica correspondente encontrada — GAP, não corrigido nesta etapa.`;
          }
        }
      }
    }

    // --- diff de posição (só quando slot resolvido com appearance) ---
    if (status === 'RESOLVED_EXISTING_APPEARANCE') {
      const appearance = appearanceByPersonMatch.get(`${personId}|${m.id}`);
      const canonicalPos = appearance.positionCode;
      if (canonicalPos == null) {
        positionDiff.CANONICAL_NULL++;
      } else {
        const fragments = normalizePosFragment(slot.pos);
        if (fragments.length === 1 && fragments[0] === canonicalPos) positionDiff.MATCH++;
        else positionDiff.DIVERGENCE++;
      }
      // --- diff de camisa ---
      if (slot.no == null && appearance.shirtNumber == null) shirtDiff.MATCH++;
      else if (slot.no == null || appearance.shirtNumber == null) shirtDiff.CANONICAL_NULL++;
      else if (slot.no === appearance.shirtNumber) shirtDiff.MATCH++;
      else shirtDiff.DIVERGENCE++;

      // --- duplicata: mesma pessoa 2x na MESMA lineup ---
      if (seenPersonIdsThisMatch.has(personId)) {
        duplicateSourcePlayers.push({ lineupMatchId: m.id, personId, canonicalName, slots: [seenPersonIdsThisMatch.get(personId), slotIndex] });
      } else {
        seenPersonIdsThisMatch.set(personId, slotIndex);
      }
    }

    // --- homônimos obrigatórios ---
    for (const key of Object.keys(homonymAudit)) {
      const needle = key.replace('_', ' ');
      if (sourceId === needle || (slot.name || '').toLowerCase().includes(needle)) {
        homonymAudit[key].push({ lineupMatchId: m.id, slot: slotIndex, rawName: slot.name, sourceId, status, personId, canonicalName });
      }
    }

    const playerRow = {
      slot: slotIndex,
      rawName: slot.name,
      rawAnswer: slot.answer,
      rawPos: slot.pos,
      rawShirtNumber: slot.no,
      personId,
      canonicalName,
      appearanceSourceRef,
      status,
      reason,
    };
    matchPlayers.push(playerRow);
    players.push({ lineupMatchId: m.id, canonicalMatchId, ...playerRow });
  });

  const slotStatusBreakdown = {};
  for (const p of matchPlayers) slotStatusBreakdown[p.status] = (slotStatusBreakdown[p.status] || 0) + 1;
  const resolvedAppearanceCount = slotStatusBreakdown.RESOLVED_EXISTING_APPEARANCE || 0;

  perMatch.push({
    lineupMatchId: m.id,
    canonicalMatchId,
    matchStatus: canonicalMatchId ? 'RESOLVED' : 'NO_CANONICAL_MATCH',
    matchDate: m.match_date,
    homeTeam: m.home_team,
    awayTeam: m.away_team,
    competition: m.competition,
    season: m.season,
    slotStatusBreakdown,
    resolvedAppearanceCount,
    hasAtLeastOneResolvedAppearance: resolvedAppearanceCount > 0,
    players: matchPlayers,
  });
}

// ============================================================================
// endurecimento pós-revisão — coverage no NÍVEL DA PARTIDA, nunca
// confundida com coverage no nível do slot (ver seção 5 do pedido:
// MATCH IDENTITY COVERAGE != PLAYER IDENTITY COVERAGE BY MATCH != BY SLOT).
// Nada aqui é hardcoded — tudo derivado de `perMatch`, que por sua vez
// vem só da classificação real dos 341 slots.
// ============================================================================
const matchesTotal = perMatch.length;
const matchesWithCanonicalMatchId = perMatch.filter((m) => m.canonicalMatchId).length;
const matchesWithAtLeastOneResolvedAppearance = perMatch.filter((m) => m.hasAtLeastOneResolvedAppearance);
const matchesWithZeroResolvedAppearances = perMatch.filter((m) => !m.hasAtLeastOneResolvedAppearance);

// verificação obrigatória (item 4 do pedido): nas partidas com ZERO
// appearance resolvida, confirmar que isso é porque 0 pessoas foram
// aprovadas ali (RESOLVED_EXISTING_APPEARANCE=0 E RESOLVED_PERSON_NO_
// APPEARANCE=0) — nunca porque a Etapa E esqueceu de inserir uma
// appearance pra uma pessoa já aprovada. Se RESOLVED_PERSON_NO_APPEARANCE
// > 0 em qualquer uma delas, isso é reportado explicitamente (nunca
// escondido) — o script NUNCA aborta sozinho, quem decide é o relatório.
const zeroAppearanceMatchesDetail = matchesWithZeroResolvedAppearances.map((m) => ({
  lineupMatchId: m.lineupMatchId,
  canonicalMatchId: m.canonicalMatchId,
  matchDate: m.matchDate,
  homeTeam: m.homeTeam,
  awayTeam: m.awayTeam,
  competition: m.competition,
  season: m.season,
  slotStatusBreakdown: m.slotStatusBreakdown,
  slotCount: m.players.length,
  isGapFromEtapaE: (m.slotStatusBreakdown.RESOLVED_PERSON_NO_APPEARANCE || 0) > 0,
}));
const anyGapFromEtapaE = zeroAppearanceMatchesDetail.some((m) => m.isGapFromEtapaE);

// ============================================================================
// 9) casos ida/volta — reconfirma via matches_seed.json, nunca por placar/nome
// ============================================================================
const idaVoltaChecks = [
  ['2010_independiente_sulamericana_final_ida', '2010_independiente_sulamericana_final_volta'],
  ['2013_vasco_cdb_quartas_ida', '2013_vasco_cdb_quartas_volta'],
  ['2026_atleticogo_goiano_final_ida', '2026_atleticogo_goiano_final_volta'],
].map(([a, b]) => {
  const ca = matchByLineupId.get(a);
  const cb = matchByLineupId.get(b);
  return {
    pair: [a, b],
    canonicalMatchIdA: ca ? ca.matchId : null,
    canonicalMatchIdB: cb ? cb.matchId : null,
    distinct: !!ca && !!cb && ca.matchId !== cb.matchId,
  };
});

// ============================================================================
// 12) appearance STARTED sem slot correspondente (direção inversa)
// ============================================================================
const orphanAppearances = [];
for (const a of appearances) {
  const rawMatch = lineupMatches.find((m) => m.id === a.lineupMatchId);
  const src = appearanceSources.find((s) => s.personId === a.personId && s.lineupMatchId === a.lineupMatchId && s.sourceType === 'lineup_matches');
  const hasSlot = !!(rawMatch && src && rawMatch.lineup.some((l) => l.answer === src.rawValue.answer));
  if (!hasSlot) orphanAppearances.push({ personId: a.personId, canonicalName: a.canonicalName, lineupMatchId: a.lineupMatchId });
}

// ============================================================================
// 26/27 — sanity de data/competição/placar contra passport (só quando
// linkado — nunca usado como identidade, só checagem factual)
// ============================================================================
const passportSanity = [];
for (const m of lineupMatches) {
  const canonical = matchByLineupId.get(m.id);
  if (!canonical || !canonical.passportMatchId) continue;
  const p = passportById.get(canonical.passportMatchId);
  if (!p) continue;
  const dateMatch = p.match_date === m.match_date;
  const scoreMatch = p.home_score === m.home_score && p.away_score === m.away_score;
  const competitionMatch = p.competition === m.competition;
  passportSanity.push({ lineupMatchId: m.id, passportMatchId: canonical.passportMatchId, dateMatch, scoreMatch, competitionMatch });
}

// ============================================================================
// stats globais
// ============================================================================
const byStatus = {};
for (const p of players) byStatus[p.status] = (byStatus[p.status] || 0) + 1;

const stats = {
  totalLineupMatches: lineupMatches.length,
  totalSlots: players.length,
  matchesWithCanonical,
  matchesWithoutCanonical: matchesWithoutCanonical.length,
  matchesWithoutCanonicalList: matchesWithoutCanonical,
  matchesWith2PlusCanonical: matchesWith2PlusCanonical.length,
  matchesWith2PlusCanonicalList: matchesWith2PlusCanonical,
  idaVoltaChecks,
  slotStatus: byStatus,
  positionDiff,
  shirtDiff,
  duplicateSourcePlayers,
  orphanAppearances,
  passportSanity,
  homonymAuditCounts: Object.fromEntries(Object.entries(homonymAudit).map(([k, v]) => [k, v.length])),
  totalAppearancesInSeed: appearances.length,
  appearancesLinkedToSlot: appearances.length - orphanAppearances.length,

  // Endurecimento pós-revisão — 3 métricas de coverage DIFERENTES, nunca
  // misturadas entre si (item 5 do pedido). "31/31" (matchIdentityCoverage)
  // NUNCA deve ser lido como "31/31 partidas têm gente identificada" — só
  // significa que a PARTIDA em si tem canonicalMatchId.
  coverage: {
    matchIdentityCoverage: {
      description: 'Quantas lineup_matches têm canonicalMatchId (matches.id) resolvido — NADA a ver com quantos jogadores foram identificados.',
      matchesTotal,
      matchesWithCanonicalMatchId,
    },
    playerIdentityCoverageByMatch: {
      description: 'Das partidas com canonicalMatchId, quantas têm PELO MENOS 1 slot com appearance canônica resolvida vs quantas têm ZERO.',
      matchesWithAtLeastOneResolvedAppearance: matchesWithAtLeastOneResolvedAppearance.length,
      matchesWithZeroResolvedAppearances: matchesWithZeroResolvedAppearances.length,
      zeroAppearanceMatches: zeroAppearanceMatchesDetail,
      anyGapFromEtapaE,
    },
    playerIdentityCoverageBySlot: {
      description: 'Dos 341 slots totais, quantos têm appearance canônica resolvida — granularidade de JOGADOR, não de partida.',
      totalSlots: players.length,
      resolvedSlots: byStatus.RESOLVED_EXISTING_APPEARANCE || 0,
      resolvedSlotsPct: Math.round(((byStatus.RESOLVED_EXISTING_APPEARANCE || 0) / players.length) * 1000) / 10,
    },
  },
};

fs.writeFileSync(path.join(OUT_DIR, 'lineup_matches_canonical_mapping.json'), JSON.stringify(perMatch, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'lineup_matches_canonical_mapping_stats.json'), JSON.stringify({ ...stats, homonymAudit }, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
