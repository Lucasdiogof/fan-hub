// Etapa F6 — mapeia cada entrada de `goias_players.dart` (215 jogadores
// históricos usados hoje SÓ pro autocomplete do Career Path) pro
// `person_id` canônico, reusando a reconciliação JÁ EXISTENTE — nunca cria
// um reconciliador paralelo. `goias_players.dart` já participa da
// pipeline como 6ª fonte (`source='goias_players_dart'`,
// `sourceId=String(índice 0-based no array)`), confirmada em
// `docs/multiclub/15_player_reconciliation_report.md`.
//
// Classificação:
//   RESOLVED     — exatamente 1 pessoa canônica dona do índice, essa
//                  pessoa tem identity != AMBIGUOUS_IDENTITY, E
//                  insert_status='APPROVED' em people_insert_plan.json.
//   AMBIGUOUS    — 2+ pessoas reivindicam o mesmo índice (0 casos reais,
//                  tratado defensivamente); OU a pessoa dona tem
//                  identity='AMBIGUOUS_IDENTITY' (ela mesma é uma mistura
//                  não resolvida, ex.: "Danilo Portugal", "Carlos
//                  Eduardo" bare); OU 0 pessoas reivindicam o índice
//                  justamente porque o motor deixou o registro
//                  DELIBERADAMENTE fora de qualquer member (caso real:
//                  índice 178 "Nicolas" bare — ver
//                  player_reconciliation_overrides.json, nicolas_split,
//                  e canonical_aliases.json onde 'nicolas' já é
//                  AMBIGUOUS_ALIAS apontando pra 2 pessoas).
//   UNRESOLVED   — 1 pessoa dona, identity != AMBIGUOUS_IDENTITY, mas
//                  insert_status PROVISIONAL/BLOCKED_INSUFFICIENT_IDENTITY
//                  (não é seguro persistir sem aprovação).
//   TEXT_ALIAS_ONLY — reservado pra entradas que não representam uma
//                  linha de jogador independente (não ocorre nesta fonte:
//                  todas as 215 entradas são jogadores distintos; os
//                  `aliases` internos de 16 delas são tratados como texto
//                  extra da MESMA entrada, nunca uma entrada à parte —
//                  ver goias_players_aliases_seed.json).
//   OUT_OF_SCOPE — não aplicável aqui (existe por consistência de forma).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const DART_FILE = path.join(ROOT, 'lib', 'features', 'arena', 'games', 'career_path', 'goias_players.dart');

const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));
const planByPersonId = new Map(insertPlan.map((p) => [p.canonical_person_id, p]));

// parse determinístico do .dart real — nunca confia num snapshot JSON à
// parte pra extrair as 215 entradas. `personId:` é opcional (só as 41 já
// resolvidas têm) — o parser precisa reconhecer os dois formatos: com e
// sem personId injetado.
export function extractGoiasPlayers(dartSrc) {
  const re = /GoiasPlayer\(name: '((?:[^'\\]|\\.)*)'(?:, personId: '([0-9a-f-]{36})')?(?:, aliases: \[([^\]]*)\])?\)/g;
  return [...dartSrc.matchAll(re)].map((m) => ({
    name: m[1].replace(/\\'/g, "'"),
    personId: m[2] || null,
    aliases: m[3] ? [...m[3].matchAll(/'((?:[^'\\]|\\.)*)'/g)].map((a) => a[1].replace(/\\'/g, "'")) : [],
  }));
}

const dartSrc = fs.readFileSync(DART_FILE, 'utf8');
const players = extractGoiasPlayers(dartSrc);

const ownersByIndex = new Map();
for (const p of canonicalPeople) {
  for (const m of p.members) {
    if (m.source !== 'goias_players_dart') continue;
    if (!ownersByIndex.has(m.sourceId)) ownersByIndex.set(m.sourceId, []);
    ownersByIndex.get(m.sourceId).push(p);
  }
}

const mapping = [];
players.forEach((entry, index) => {
  const owners = ownersByIndex.get(String(index)) || [];
  const base = { sourceIndex: index, sourceName: entry.name, normalizedName: normalize(entry.name) };

  if (owners.length === 0) {
    mapping.push({
      ...base,
      personId: null,
      canonicalName: null,
      status: 'AMBIGUOUS',
      resolutionReason: `Nenhuma pessoa canônica reivindica goias_players_dart:${index} — o motor de reconciliação deixou este registro deliberadamente fora de qualquer member (não é ausência de dado, é ambiguidade real sem evidência pra decidir). Ver player_reconciliation_overrides.json e canonical_aliases.json.`,
      sources: [],
    });
    return;
  }
  if (owners.length > 1) {
    mapping.push({
      ...base,
      personId: null,
      canonicalName: null,
      status: 'AMBIGUOUS',
      resolutionReason: `${owners.length} pessoas canônicas diferentes reivindicam o mesmo índice — split não resolvido, nunca escolhido sozinho.`,
      sources: owners.map((o) => ({ personId: o.canonicalId, canonicalName: o.canonicalName, identity: o.identity })),
    });
    return;
  }

  const owner = owners[0];
  if (owner.identity === 'AMBIGUOUS_IDENTITY') {
    mapping.push({
      ...base,
      personId: null,
      canonicalName: owner.canonicalName,
      status: 'AMBIGUOUS',
      resolutionReason: `A própria pessoa canônica "${owner.canonicalName}" tem identity=AMBIGUOUS_IDENTITY — ela mesma representa uma mistura não resolvida de possíveis pessoas reais diferentes, não é seguro atribuir um person_id único.`,
      sources: [{ personId: owner.canonicalId, canonicalName: owner.canonicalName, identity: owner.identity }],
    });
    return;
  }

  const plan = planByPersonId.get(owner.canonicalId);
  if (!plan || plan.insert_status !== 'APPROVED') {
    mapping.push({
      ...base,
      personId: null,
      canonicalName: owner.canonicalName,
      status: 'UNRESOLVED',
      resolutionReason: `1 pessoa canônica encontrada (${owner.canonicalName}, identity=${owner.identity}), mas insert_status=${plan ? plan.insert_status : 'AUSENTE_DE_people_insert_plan.json'} — não é seguro persistir person_id sem aprovação.`,
      sources: [{ personId: owner.canonicalId, canonicalName: owner.canonicalName, identity: owner.identity, insertStatus: plan ? plan.insert_status : null }],
    });
    return;
  }

  mapping.push({
    ...base,
    personId: owner.canonicalId,
    canonicalName: owner.canonicalName,
    status: 'RESOLVED',
    resolutionReason: `1 pessoa canônica (${owner.canonicalName}), identity=${owner.identity}, insert_status=APPROVED.`,
    sources: [{ personId: owner.canonicalId, canonicalName: owner.canonicalName, identity: owner.identity, insertStatus: 'APPROVED' }],
  });
});

function normalize(s) {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim().replace(/\s+/g, ' ');
}

// colisões por texto normalizado — inclui aliases internos como o MESMO
// personId da entrada dona (nunca uma identidade à parte).
const textOccurrences = new Map(); // normalizedText -> [{sourceIndex, sourceName, isAlias, personId, status}]
players.forEach((entry, index) => {
  const m = mapping[index];
  const push = (text, isAlias) => {
    const key = normalize(text);
    if (!textOccurrences.has(key)) textOccurrences.set(key, []);
    textOccurrences.get(key).push({ sourceIndex: index, sourceName: text, isAlias, personId: m.personId, status: m.status });
  };
  push(entry.name, false);
  for (const alias of entry.aliases) push(alias, true);
});
const collisions = [...textOccurrences.entries()].filter(([, occ]) => occ.length > 1);
const samePersonCollisions = collisions.filter(([, occ]) => {
  const ids = new Set(occ.map((o) => o.personId).filter(Boolean));
  return ids.size <= 1 && occ.every((o) => o.personId != null);
});
const crossPersonCollisions = collisions.filter(([, occ]) => {
  const ids = new Set(occ.map((o) => o.personId).filter(Boolean));
  return ids.size > 1;
});
const unresolvedInvolvedCollisions = collisions.filter(([, occ]) => occ.some((o) => o.personId == null));

const stats = {
  total: mapping.length,
  RESOLVED: mapping.filter((m) => m.status === 'RESOLVED').length,
  AMBIGUOUS: mapping.filter((m) => m.status === 'AMBIGUOUS').length,
  UNRESOLVED: mapping.filter((m) => m.status === 'UNRESOLVED').length,
  TEXT_ALIAS_ONLY: mapping.filter((m) => m.status === 'TEXT_ALIAS_ONLY').length,
  OUT_OF_SCOPE: mapping.filter((m) => m.status === 'OUT_OF_SCOPE').length,
  distinctNormalizedTexts: textOccurrences.size,
  normalizedTextCollisions: collisions.length,
  samePersonCollisions: samePersonCollisions.length,
  crossPersonCollisions: crossPersonCollisions.length,
  unresolvedInvolvedCollisions: unresolvedInvolvedCollisions.length,
  crossPersonCollisionDetail: crossPersonCollisions.map(([text, occ]) => ({ normalizedText: text, occurrences: occ })),
  unresolvedList: mapping.filter((m) => m.status !== 'RESOLVED').map((m) => ({ sourceIndex: m.sourceIndex, sourceName: m.sourceName, status: m.status, reason: m.resolutionReason })),
};

fs.writeFileSync(path.join(RECON, 'goias_players_person_mapping.json'), JSON.stringify(mapping, null, 2) + '\n');
fs.writeFileSync(path.join(RECON, 'goias_players_person_mapping_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify({ ...stats, crossPersonCollisionDetail: undefined, unresolvedList: undefined }, null, 2));
console.log('\nEscrito em:', RECON);
