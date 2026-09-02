// Constrói o seed de player_positions (+ sources) SOMENTE pro Goiás,
// SOMENTE pra pessoas já em `public.people` (96 APPROVED), e SOMENTE onde
// existe evidência resolvível — nunca inventa lado (D/E) quando a fonte
// não diz.
//
// Fonte Tier 1 canônica: lib/features/crowd_lineup/domain/goias_squad.dart
// — lista humana curada, ORDENADA (1ª = primária), pros 31 do elenco
// atual. Onde ela existe, é a ÚNICA verdade de ordem — squad_members/
// guess_players/lineup_matches viram só CORROBORATING (nunca reordenam).
//
// Pra quem NÃO está em goias_squad.dart (histórico): agrega códigos
// resolvíveis de squad_members.position, guess_players.position,
// career_players.position (composto, "X / Y") e lineup_matches.pos
// (composto, "LD/MC" — caso real do Dieguinho). Se todas as fontes
// concordam num único código -> VERIFIED, 1 linha. Se aparecem 2+ códigos
// distintos sem ordem confiável entre fontes -> PARTIAL, position_order
// atribuído por frequência (nunca alegado como hierarquia real). Um par
// de códigos sem adjacência tática conhecida NUNCA é tratado como erro
// de dado — position_compatibility.dart é o motor de escalação ATUAL, não
// a possibilidade histórica de alguém ter jogado em funções diferentes.
// Classificação vira NON_ADJACENT_MULTI_POSITION, só uma flag de revisão,
// nunca bloqueia/descarta a posição.
//
// spell_id fica SEMPRE null nesta rodada — nenhuma fonte atual dá posição
// no grão de spell (career_players.position é por PESSOA, não por
// club_career[i]; squad_members/goias_squad são "hoje", sem data). A
// coluna existe pro schema aceitar precisão futura, não pra fingir uma
// precisão que os dados de hoje não têm.
//
// player_position_overrides.json: decisões humanas explícitas de CAP
// (restringir a posição canônica) — hoje só Fernandão/Iarley (MEI
// suprimido, ATA único canônico). Evidência suprimida nunca é apagada:
// fica documentada em stats.suppressedPositions, e a fonte bruta
// (career_players.json) nunca é editada.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { CANONICAL_POSITIONS, normalizeDirectCode, resolveCareerPlayersPosition, resolveLineupMatchesPosition, arePositionsCompatible } from './position_catalog.mjs';
import { loadClubRegistry, resolveClubId } from './club_registry.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;
const GOIAS_SQUAD_DART = path.join(ROOT, 'lib', 'features', 'crowd_lineup', 'domain', 'goias_squad.dart');

const CLUB_LOOKUP_KEY = 'goias';

const squadMembers = JSON.parse(fs.readFileSync(path.join(DATA, 'squad_members.json'), 'utf8'));
const guessPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'guess_players.json'), 'utf8'));
const careerPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'career_players.json'), 'utf8'));
const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));
const positionOverrides = JSON.parse(fs.readFileSync(path.join(__dirname, 'player_position_overrides.json'), 'utf8'));

const capOverrideByName = new Map(
  positionOverrides.overrides.filter((o) => o.type === 'cap_canonical_positions').map((o) => [o.canonicalName, o])
);

const clubRegistry = loadClubRegistry(path.join(__dirname, 'clubs_registry.json'));
const clubResolved = resolveClubId(clubRegistry, CLUB_LOOKUP_KEY);
if (clubResolved.status !== 'matched') throw new Error('Clube "goias" não está no club registry.');
const CLUB_ID = clubResolved.clubId;

const approvedIds = new Set(insertPlan.filter((p) => p.insert_status === 'APPROVED').map((p) => p.canonical_person_id));

// ---------------------------------------------------------------------------
// 1. Parseia goias_squad.dart — regex sobre `SquadPlayer(... id: 'x', ...
//    allowedPositions: _pos(['a','b']), ...)`, um bloco por entrada.
// ---------------------------------------------------------------------------
const dartSrc = fs.readFileSync(GOIAS_SQUAD_DART, 'utf8');
const goiasSquadById = new Map();
{
  const blockRe = /SquadPlayer\(([\s\S]*?)\),\n(?=\s*(?:SquadPlayer\(|\];))/g;
  let m;
  while ((m = blockRe.exec(dartSrc))) {
    const block = m[1];
    const idMatch = block.match(/id:\s*'([^']+)'/);
    const posMatch = block.match(/allowedPositions:\s*_pos\(\[([^\]]*)\]\)/);
    if (!idMatch || !posMatch) continue;
    const rawCodes = posMatch[1].split(',').map((s) => s.trim().replace(/^'|'$/g, '')).filter(Boolean);
    goiasSquadById.set(idMatch[1], rawCodes.map((c) => ({ raw: c, code: c.toUpperCase() })));
  }
}
if (goiasSquadById.size !== 31) throw new Error(`Esperava 31 entradas em goias_squad.dart, parseou ${goiasSquadById.size} — regex desalinhado com o arquivo, corrigir antes de continuar.`);
for (const [id, entries] of goiasSquadById) {
  for (const e of entries) if (!CANONICAL_POSITIONS.includes(e.code)) throw new Error(`goias_squad.dart:${id} tem código não-canônico "${e.code}".`);
}

const squadById = new Map(squadMembers.map((p) => [p.id, p]));
const guessById = new Map(guessPlayers.map((p) => [p.id, p]));
const careerById = new Map(careerPlayers.map((p) => [p.id, p]));

const SQUAD_MEMBERS_WORD_TO_CODE = { 'Goleiro': 'GOL', 'Zagueiro': 'ZAG', 'Lateral-direito': 'LD', 'Lateral-esquerdo': 'LE', 'Volante': 'VOL', 'Meia-atacante': 'MEI', 'Ponta-direita': 'PD', 'Ponta-esquerda': 'PE', 'Centroavante': 'ATA' };

// ---------------------------------------------------------------------------
// 2. Por pessoa APPROVED: coleta observações resolvíveis de cada fonte.
//    Cada observação guarda a evidência granular completa (source_type,
//    source_ref, raw_value, match_id, observed_at) — nunca só um código
//    "flat" sem rastro de onde veio.
// ---------------------------------------------------------------------------
const positions = [];
const sources = [];
const blocked = [];
const conflictsReport = [];
const suppressedPositions = [];

for (const person of canonicalPeople) {
  if (!approvedIds.has(person.canonicalId)) continue;

  const squadMemberIds = person.members.filter((m) => m.source === 'squad_members').map((m) => m.sourceId);
  const goiasSquadId = squadMemberIds.find((id) => goiasSquadById.has(id));

  const observations = [];

  if (goiasSquadId) {
    const entries = goiasSquadById.get(goiasSquadId);
    entries.forEach((entry) => {
      observations.push({ code: entry.code, sourceType: 'goias_squad_dart', sourceRef: goiasSquadId, rawValue: entry.raw, matchId: null, observedAt: null, evidenceType: 'PRIMARY' });
    });
  }

  // squad_members.position — corroborante quando já há goias_squad.dart;
  // senão entra como observação de 1ª linha (single value, sem ordem).
  for (const sid of squadMemberIds) {
    const sq = squadById.get(sid);
    if (!sq || !sq.position) continue;
    const code = SQUAD_MEMBERS_WORD_TO_CODE[sq.position];
    if (!code) { conflictsReport.push({ canonicalName: person.canonicalName, issue: `squad_members.position "${sq.position}" não mapeado` }); continue; }
    observations.push({ code, sourceType: 'squad_members', sourceRef: sid, rawValue: sq.position, matchId: null, observedAt: null, evidenceType: goiasSquadId ? 'CORROBORATING' : 'PRIMARY' });
  }

  for (const m of person.members) {
    if (m.source === 'guess_players') {
      const gp = guessById.get(m.sourceId);
      if (gp && gp.position) {
        const code = normalizeDirectCode(gp.position);
        if (code) observations.push({ code, sourceType: 'guess_players', sourceRef: m.sourceId, rawValue: gp.position, matchId: null, observedAt: null, evidenceType: goiasSquadId ? 'CORROBORATING' : 'PRIMARY' });
      }
    }
    if (m.source === 'career_players') {
      const cp = careerById.get(m.sourceId);
      if (cp && cp.position) {
        const { resolved, unmapped } = resolveCareerPlayersPosition(cp.position);
        for (const code of resolved) observations.push({ code, sourceType: 'career_players', sourceRef: m.sourceId, rawValue: cp.position, matchId: null, observedAt: null, evidenceType: goiasSquadId ? 'CORROBORATING' : 'PRIMARY' });
        if (unmapped.length) conflictsReport.push({ canonicalName: person.canonicalName, issue: `career_players.position "${cp.position}" tem fragmento(s) não mapeável(is): ${unmapped.join(', ')} (lado desconhecido, nunca adivinhado)` });
      }
    }
    if (m.source === 'lineup_matches') {
      const matchIds = m.matchIdFilter || lineupMatches.filter((match) => match.lineup.some((l) => (l.answer || '').toLowerCase() === m.sourceId.toLowerCase())).map((match) => match.id);
      for (const matchId of matchIds) {
        const match = lineupMatches.find((x) => x.id === matchId);
        if (!match) continue;
        for (const l of match.lineup) {
          if ((l.answer || '').toLowerCase() !== m.sourceId.toLowerCase()) continue;
          const { resolved, unmapped } = resolveLineupMatchesPosition(l.pos);
          for (const code of resolved) observations.push({ code, sourceType: 'lineup_matches', sourceRef: m.sourceId, rawValue: l.pos, matchId, observedAt: match.match_date || null, evidenceType: goiasSquadId ? 'CORROBORATING' : 'PRIMARY' });
          if (unmapped.length) conflictsReport.push({ canonicalName: person.canonicalName, issue: `lineup_matches:${matchId} pos "${l.pos}" tem fragmento(s) genérico(s) não mapeável(is): ${unmapped.join(', ')}` });
        }
      }
    }
  }

  if (!observations.length) {
    blocked.push({ canonicalName: person.canonicalName, canonicalId: person.canonicalId, reason: 'NO_RESOLVABLE_POSITION_EVIDENCE' });
    continue;
  }

  const distinctCodes = [...new Set(observations.map((o) => o.code))];
  let orderedCodes;
  let eligibility;
  let verificationStatus;

  if (goiasSquadId) {
    orderedCodes = goiasSquadById.get(goiasSquadId).map((e) => e.code);
    eligibility = 'APPROVED';
    verificationStatus = 'VERIFIED';
    const outsideList = distinctCodes.filter((c) => !orderedCodes.includes(c));
    if (outsideList.length) {
      conflictsReport.push({ canonicalName: person.canonicalName, issue: `fonte secundária sugere ${outsideList.join(',')}, fora da lista humana de goias_squad.dart (${orderedCodes.join(',')}) — mantido só o que a fonte-ouro diz, divergência reportada, nunca somada silenciosamente.` });
    }
  } else if (distinctCodes.length === 1) {
    orderedCodes = distinctCodes;
    eligibility = 'APPROVED';
    verificationStatus = 'VERIFIED';
  } else {
    // 2+ códigos distintos, sem fonte-ouro ordenada — versatilidade real,
    // mas sem hierarquia confiável entre fontes. Ordena por frequência de
    // observação (mais forte "aparece mais" != "é a principal", por isso
    // PARTIAL, nunca APPROVED).
    const freq = new Map();
    for (const o of observations) freq.set(o.code, (freq.get(o.code) || 0) + 1);
    orderedCodes = distinctCodes.sort((a, b) => (freq.get(b) - freq.get(a)) || a.localeCompare(b));
    eligibility = 'PROVISIONAL';
    verificationStatus = 'PARTIAL';
    // Classificação NEUTRA — position_compatibility.dart#_naturalAdaptations
    // é o motor de escalação ATUAL, não a possibilidade histórica de
    // alguém ter jogado em funções diferentes ao longo da carreira. Um
    // par sem adjacência tática conhecida NUNCA é tratado como erro de
    // dado nem bloqueia/descarta a posição — só vira flag de revisão.
    const allPairsCompatible = distinctCodes.every((a, i) => distinctCodes.every((b, j) => i >= j || arePositionsCompatible(a, b)));
    const classification = allPairsCompatible ? 'COMPATIBLE_MULTI_POSITION' : 'NON_ADJACENT_MULTI_POSITION';
    conflictsReport.push({ canonicalName: person.canonicalName, issue: `versatilidade sem fonte-ouro: códigos ${orderedCodes.join(',')} — position_order por frequência, NÃO por hierarquia confirmada (PARTIAL).${allPairsCompatible ? '' : ' Sem adjacência tática conhecida no motor de escalação atual — flag de revisão, evidência PRESERVADA, nunca descartada.'}`, classification });
  }

  // Aplica cap override, se existir pra esta pessoa — restringe a posição
  // CANÔNICA, mas nunca apaga a evidência bruta (fica em
  // suppressedPositions, e a fonte original nunca é editada).
  const capOverride = capOverrideByName.get(person.canonicalName);
  if (capOverride) {
    const suppressed = orderedCodes.filter((c) => !capOverride.canonicalPositions.includes(c));
    if (suppressed.length) {
      suppressedPositions.push({
        canonicalName: person.canonicalName,
        suppressedCodes: suppressed,
        keptCodes: capOverride.canonicalPositions,
        reason: capOverride.reason,
        overrideId: capOverride.id,
      });
      orderedCodes = orderedCodes.filter((c) => capOverride.canonicalPositions.includes(c));
      verificationStatus = 'VERIFIED'; // decisão humana explícita = override, mesma semântica de VERIFIED em player_club_spells
      eligibility = 'APPROVED';
    }
  }

  orderedCodes.forEach((code, idx) => {
    positions.push({
      personId: person.canonicalId,
      canonicalName: person.canonicalName,
      clubId: CLUB_ID,
      clubSlug: CLUB_LOOKUP_KEY,
      positionCode: code,
      positionOrder: idx + 1,
      eligibility,
      verificationStatus,
    });
    const obsForCode = observations.filter((o) => o.code === code);
    const seenKeys = new Set();
    for (const o of obsForCode) {
      const key = `${o.sourceType}|${o.sourceRef}|${o.matchId || ''}`;
      if (seenKeys.has(key)) continue; // mesma fonte-registro não duplica provenance
      seenKeys.add(key);
      const notes = o.rawValue && o.rawValue.includes('/') ? `valor composto na fonte ("${o.rawValue}") — este código corresponde a 1 dos tokens/observações` : null;
      sources.push({
        personId: person.canonicalId,
        clubSlug: CLUB_LOOKUP_KEY,
        positionCode: code,
        sourceType: o.sourceType,
        sourceRef: o.sourceRef,
        rawValue: o.rawValue,
        matchId: o.matchId,
        observedAt: o.observedAt,
        evidenceType: o.evidenceType,
        notes,
      });
    }
  });
}

// ---------------------------------------------------------------------------
// 3. Stats
// ---------------------------------------------------------------------------
const peopleWithPosition = new Set(positions.map((p) => p.personId));
const countByPerson = new Map();
for (const p of positions) countByPerson.set(p.personId, (countByPerson.get(p.personId) || 0) + 1);
const distribution = { 1: 0, 2: 0, '3+': 0 };
for (const n of countByPerson.values()) {
  if (n === 1) distribution['1']++;
  else if (n === 2) distribution['2']++;
  else distribution['3+']++;
}

const stats = {
  approvedPeopleTotal: approvedIds.size,
  peopleWithAtLeastOnePosition: peopleWithPosition.size,
  peopleBlocked: blocked.length,
  totalPositionRows: positions.length,
  verifiedRows: positions.filter((p) => p.verificationStatus === 'VERIFIED').length,
  partialRows: positions.filter((p) => p.verificationStatus === 'PARTIAL').length,
  totalSourceRows: sources.length,
  peopleWith1Position: distribution['1'],
  peopleWith2Positions: distribution['2'],
  peopleWith3PlusPositions: distribution['3+'],
  peopleFromGoldSource: [...peopleWithPosition].filter((id) => positions.find((p) => p.personId === id).eligibility === 'APPROVED' && countByPerson.get(id) > 1).length,
  conflictsReport,
  suppressedPositions,
  blocked: blocked.sort((a, b) => a.canonicalName.localeCompare(b.canonicalName)),
};

fs.writeFileSync(path.join(OUT_DIR, 'player_positions_seed.json'), JSON.stringify(positions, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_position_sources_seed.json'), JSON.stringify(sources, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'player_positions_seed_stats.json'), JSON.stringify(stats, null, 2) + '\n');

console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
