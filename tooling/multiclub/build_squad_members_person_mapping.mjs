// Etapa F4 — mapeia cada linha de `squad_members` (Elenco, 31 jogadores
// hoje — o elenco profissional ATUAL) pro `person_id` canônico já
// existente em `people`. Mesma disciplina de F1/F3: NÃO cria pessoas
// novas, NÃO resolve por nome/ilike — reusa exclusivamente os `member`s
// já reconciliados em canonical_people_candidates.json
// (source='squad_members', sourceId=squad_members.id).
//
// Classificação (mesma definição exata de F1/F3):
//   RESOLVED     — exatamente 1 pessoa canônica, e essa pessoa está
//                  insert_status='APPROVED' em people_insert_plan.json.
//   AMBIGUOUS    — 2+ pessoas canônicas reivindicam o mesmo sourceId.
//   UNRESOLVED   — 0 pessoas reclamam o sourceId, OU existe 1 pessoa mas
//                  ela não está APPROVED.
//   OUT_OF_SCOPE — squad_members não tem coluna is_active (diferente de
//                  career_players/guess_players) — categoria existe pra
//                  consistência de formato, mas nunca populada nesta
//                  etapa (0 casos, documentado, não um "esquecimento").
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const squadMembers = JSON.parse(fs.readFileSync(path.join(DATA, 'squad_members.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));

const planByPersonId = new Map(insertPlan.map((p) => [p.canonical_person_id, p]));

const ownersBySourceId = new Map();
for (const person of canonicalPeople) {
  for (const member of person.members) {
    if (member.source !== 'squad_members') continue;
    if (!ownersBySourceId.has(member.sourceId)) ownersBySourceId.set(member.sourceId, []);
    ownersBySourceId.get(member.sourceId).push(person);
  }
}

const mapping = [];
for (const row of squadMembers) {
  // squad_members não tem is_active — nunca OUT_OF_SCOPE nesta fonte hoje.
  const base = { squadMemberId: row.id, currentName: row.full_name || row.name };

  const owners = ownersBySourceId.get(row.id) || [];
  if (owners.length === 0) {
    mapping.push({ ...base, personId: null, canonicalName: null, status: 'UNRESOLVED', resolutionReason: `Nenhum member em canonical_people_candidates.json aponta pra source='squad_members' sourceId='${row.id}'.`, sources: [] });
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

// Cardinalidade real — auditada nos 2 sentidos, nunca suposta (item 7 do
// pedido, mesma disciplina reforçada de F3).
const personIdOccurrences = new Map();
for (const m of mapping) {
  if (m.status !== 'RESOLVED') continue;
  if (!personIdOccurrences.has(m.personId)) personIdOccurrences.set(m.personId, []);
  personIdOccurrences.get(m.personId).push(m.squadMemberId);
}
const personIdReusedAcrossRows = [...personIdOccurrences.entries()]
  .filter(([, ids]) => ids.length > 1)
  .map(([personId, ids]) => ({ personId, canonicalName: mapping.find((m) => m.personId === personId)?.canonicalName, squadMemberIds: ids }));

// checagem reversa: alguma pessoa canônica com 2+ members squad_members?
const reverseMultiMembership = [];
for (const p of canonicalPeople) {
  const smMembers = p.members.filter((m) => m.source === 'squad_members');
  if (smMembers.length > 1) reverseMultiMembership.push({ canonicalId: p.canonicalId, canonicalName: p.canonicalName, squadMemberIds: smMembers.map((m) => m.sourceId) });
}

const stats = {
  total: mapping.length,
  RESOLVED: mapping.filter((m) => m.status === 'RESOLVED').length,
  AMBIGUOUS: mapping.filter((m) => m.status === 'AMBIGUOUS').length,
  UNRESOLVED: mapping.filter((m) => m.status === 'UNRESOLVED').length,
  OUT_OF_SCOPE: mapping.filter((m) => m.status === 'OUT_OF_SCOPE').length,
  distinctPersonIdsAmongResolved: personIdOccurrences.size,
  personIdReusedAcrossRows,
  reverseMultiMembership,
  unresolvedList: mapping.filter((m) => m.status !== 'RESOLVED').map((m) => ({ squadMemberId: m.squadMemberId, currentName: m.currentName, status: m.status, reason: m.resolutionReason })),
};

fs.writeFileSync(path.join(OUT_DIR, 'squad_members_person_mapping.json'), JSON.stringify(mapping, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'squad_members_person_mapping_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
