// Etapa F3 — mapeia cada linha de `guess_players` (Quem Vestiu o Manto,
// 173 jogadores hoje) pro `person_id` canônico já existente em `people`.
// NÃO cria pessoas novas. NÃO resolve por nome/ilike — reusa
// exclusivamente os `member`s já reconciliados em canonical_people_
// candidates.json (source='guess_players', sourceId=guess_players.id) —
// a mesma fundação que já alimentou player_club_spells/player_club_stats/
// player_positions/person_aliases (que já tem entradas source='guess_
// players' pros homônimos Danilo/Nicolas — ver 20260901030000_seed_goias_
// person_aliases.sql).
//
// Classificação (mesma definição exata da F1):
//   RESOLVED     — exatamente 1 pessoa canônica, e essa pessoa está
//                  insert_status='APPROVED' em people_insert_plan.json.
//   AMBIGUOUS    — 2+ pessoas canônicas reivindicam o mesmo sourceId.
//   UNRESOLVED   — 0 pessoas reclamam o sourceId, OU existe 1 pessoa mas
//                  ela não está APPROVED.
//   OUT_OF_SCOPE — linha com is_active=false (0 casos hoje).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const OUT_DIR = RECON;

const guessPlayers = JSON.parse(fs.readFileSync(path.join(DATA, 'guess_players.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));

const planByPersonId = new Map(insertPlan.map((p) => [p.canonical_person_id, p]));

const ownersBySourceId = new Map();
for (const person of canonicalPeople) {
  for (const member of person.members) {
    if (member.source !== 'guess_players') continue;
    if (!ownersBySourceId.has(member.sourceId)) ownersBySourceId.set(member.sourceId, []);
    ownersBySourceId.get(member.sourceId).push(person);
  }
}

const mapping = [];
for (const row of guessPlayers) {
  const outOfScope = row.is_active === false;
  const base = { guessPlayerId: row.id, currentName: row.display_name || row.name };

  if (outOfScope) {
    mapping.push({ ...base, personId: null, canonicalName: null, status: 'OUT_OF_SCOPE', resolutionReason: 'is_active=false — linha não servida ao usuário hoje, fora de escopo desta migração de identidade.', sources: [] });
    continue;
  }

  const owners = ownersBySourceId.get(row.id) || [];
  if (owners.length === 0) {
    mapping.push({ ...base, personId: null, canonicalName: null, status: 'UNRESOLVED', resolutionReason: `Nenhum member em canonical_people_candidates.json aponta pra source='guess_players' sourceId='${row.id}'.`, sources: [] });
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

// Cardinalidade real — auditada, não suposta (item 10 do pedido). Nunca
// decide UNIQUE aqui, só REPORTA quantas vezes cada person_id aparece
// entre as linhas RESOLVED — a decisão de criar (ou não) a constraint
// fica pro gerador de migration, lendo estes números.
const personIdOccurrences = new Map();
for (const m of mapping) {
  if (m.status !== 'RESOLVED') continue;
  if (!personIdOccurrences.has(m.personId)) personIdOccurrences.set(m.personId, []);
  personIdOccurrences.get(m.personId).push(m.guessPlayerId);
}
const personIdReusedAcrossRows = [...personIdOccurrences.entries()]
  .filter(([, ids]) => ids.length > 1)
  .map(([personId, ids]) => ({ personId, canonicalName: mapping.find((m) => m.personId === personId)?.canonicalName, guessPlayerIds: ids }));

const stats = {
  total: mapping.length,
  RESOLVED: mapping.filter((m) => m.status === 'RESOLVED').length,
  AMBIGUOUS: mapping.filter((m) => m.status === 'AMBIGUOUS').length,
  UNRESOLVED: mapping.filter((m) => m.status === 'UNRESOLVED').length,
  OUT_OF_SCOPE: mapping.filter((m) => m.status === 'OUT_OF_SCOPE').length,
  distinctPersonIdsAmongResolved: personIdOccurrences.size,
  personIdReusedAcrossRows, // cardinalidade real — [] hoje, mas nunca suposto vazio sem checar
  unresolvedList: mapping.filter((m) => m.status === 'UNRESOLVED').map((m) => ({ guessPlayerId: m.guessPlayerId, currentName: m.currentName, reason: m.resolutionReason })),
};

fs.writeFileSync(path.join(OUT_DIR, 'guess_players_person_mapping.json'), JSON.stringify(mapping, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'guess_players_person_mapping_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
