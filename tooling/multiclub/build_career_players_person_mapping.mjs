// Etapa F1 — mapeia cada linha de `career_players` (Adivinhe o Jogador,
// 30 jogadores hoje) pro `person_id` canônico já existente em `people`
// (96 aprovados, Etapas A-E). NÃO cria pessoas novas. NÃO resolve por
// nome/ilike — reusa exclusivamente os `member`s já reconciliados em
// canonical_people_candidates.json (source='career_players',
// sourceId=career_players.id), a mesma fundação que já alimentou
// player_club_spells/player_club_stats/player_positions.
//
// Classificação (definição exata pedida pelo usuário):
//   RESOLVED     — exatamente 1 pessoa canônica, e essa pessoa está
//                  insert_status='APPROVED' em people_insert_plan.json.
//   AMBIGUOUS    — 2+ pessoas canônicas reivindicam o mesmo sourceId
//                  (cenário de split não previsto pra career_players,
//                  mas verificado estruturalmente, nunca suposto ausente).
//   UNRESOLVED   — 0 pessoas reclamam o sourceId, OU existe 1 pessoa mas
//                  ela não está APPROVED (PROVISIONAL/BLOCKED_AMBIGUOUS/
//                  etc. — identidade real ainda não fechada em NENHUMA
//                  feature, não é um problema desta migração).
//   OUT_OF_SCOPE — linha com is_active=false (não servida ao usuário hoje
//                  — categoria existe pra runs futuros, 0 casos agora).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const careerPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'career_players.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));

const planByPersonId = new Map(insertPlan.map((p) => [p.canonical_person_id, p]));

// index: sourceId (career_players.id) -> [pessoas canônicas que o reivindicam]
const ownersBySourceId = new Map();
for (const person of canonicalPeople) {
  for (const member of person.members) {
    if (member.source !== 'career_players') continue;
    if (!ownersBySourceId.has(member.sourceId)) ownersBySourceId.set(member.sourceId, []);
    ownersBySourceId.get(member.sourceId).push(person);
  }
}

const mapping = [];
for (const row of careerPlayers) {
  const outOfScope = row.is_active === false;
  const goiasSpellsCount = (row.club_career || []).filter((c) => c.is_goias).length;
  const base = {
    careerPlayerKey: row.id,
    currentName: row.answer,
    goiasSpellsInClubCareer: goiasSpellsCount,
  };

  if (outOfScope) {
    mapping.push({ ...base, personId: null, canonicalName: null, status: 'OUT_OF_SCOPE', resolutionReason: 'is_active=false — linha não servida ao usuário hoje, fora de escopo desta migração de identidade.', sources: [] });
    continue;
  }

  const owners = ownersBySourceId.get(row.id) || [];
  if (owners.length === 0) {
    mapping.push({ ...base, personId: null, canonicalName: null, status: 'UNRESOLVED', resolutionReason: `Nenhum member em canonical_people_candidates.json aponta pra source='career_players' sourceId='${row.id}'.`, sources: [] });
    continue;
  }
  if (owners.length > 1) {
    mapping.push({
      ...base,
      personId: null,
      canonicalName: null,
      status: 'AMBIGUOUS',
      resolutionReason: `${owners.length} pessoas canônicas diferentes reivindicam o mesmo sourceId — split não resolvido, nunca escolhido sozinho.`,
      sources: owners.map((o) => ({ personId: o.canonicalId, canonicalName: o.canonicalName, identity: o.identity })),
    });
    continue;
  }

  const owner = owners[0];
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
    continue;
  }

  mapping.push({
    ...base,
    personId: owner.canonicalId,
    canonicalName: owner.canonicalName,
    status: 'RESOLVED',
    resolutionReason: `1 pessoa canônica (${owner.canonicalName}), identity=${owner.identity}, insert_status=APPROVED.`,
    sources: [{ personId: owner.canonicalId, canonicalName: owner.canonicalName, identity: owner.identity, insertStatus: 'APPROVED' }],
  });
}

// nunca o mesmo person_id em 2 linhas RESOLVED — auditado, não suposto.
const seenPersonId = new Map();
const duplicatePersonIdIssues = [];
for (const m of mapping) {
  if (m.status !== 'RESOLVED') continue;
  if (seenPersonId.has(m.personId)) duplicatePersonIdIssues.push({ personId: m.personId, keys: [seenPersonId.get(m.personId), m.careerPlayerKey] });
  else seenPersonId.set(m.personId, m.careerPlayerKey);
}

const stats = {
  total: mapping.length,
  RESOLVED: mapping.filter((m) => m.status === 'RESOLVED').length,
  AMBIGUOUS: mapping.filter((m) => m.status === 'AMBIGUOUS').length,
  UNRESOLVED: mapping.filter((m) => m.status === 'UNRESOLVED').length,
  OUT_OF_SCOPE: mapping.filter((m) => m.status === 'OUT_OF_SCOPE').length,
  duplicatePersonIdIssues,
  unresolvedList: mapping.filter((m) => m.status === 'UNRESOLVED').map((m) => ({ careerPlayerKey: m.careerPlayerKey, currentName: m.currentName, reason: m.resolutionReason })),
  multiplePassagens: mapping.filter((m) => m.goiasSpellsInClubCareer > 1).map((m) => ({ careerPlayerKey: m.careerPlayerKey, status: m.status, goiasSpellsInClubCareer: m.goiasSpellsInClubCareer })),
};

if (duplicatePersonIdIssues.length) {
  console.error('ERRO — person_id duplicado entre linhas RESOLVED:', JSON.stringify(duplicatePersonIdIssues, null, 2));
  process.exit(1);
}

fs.writeFileSync(path.join(OUT_DIR, 'career_players_person_mapping.json'), JSON.stringify(mapping, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'career_players_person_mapping_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
