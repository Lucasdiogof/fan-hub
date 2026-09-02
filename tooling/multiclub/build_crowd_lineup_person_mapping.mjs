// Etapa F5 — mapeia lib/features/crowd_lineup/domain/goias_squad.dart
// (roster hardcoded, independente, id=slug) para person_id, reusando
// EXCLUSIVAMENTE o mapping já aprovado da F4
// (squad_members_person_mapping.json) — nunca resolve por nome/alias/
// primeiro candidato. Confirmado por auditoria: os 31 ids do goiasSquad
// são EXATAMENTE os 31 ids de squad_members (mesmo slug, 1:1), então o
// caminho é sempre goiasSquad.id -> squad_members.id -> person_id, nunca
// nome.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const OUT_DIR = RECON;

// Lista literal dos ids do goiasSquad (goias_squad.dart) — mantida em
// paralelo por design: este script NUNCA lê/parseia o .dart (fora de
// escopo pra um script de dados), só valida contra ele via teste
// dedicado (test_crowd_lineup_person_mapping.mjs lê o .dart de verdade e
// compara a lista de ids extraída contra esta).
const GOIAS_SQUAD_IDS = [
  'tadeu', 'ezequiel', 'murillo_victorio', 'thiago_rodrigues',
  'luisao', 'lucas_ribeiro', 'luiz_felipe', 'ramon_menezes', 'murilo_camara',
  'rodrigo_soares', 'marcos_vinicius',
  'nicolas', 'danilo', 'djalma',
  'lourenco', 'filipe_machado', 'baldoria', 'juninho', 'lucas_rodrigues',
  'gege', 'lucas_lima', 'brayann', 'wellington_rato',
  'pedrinho', 'anselmo_ramon', 'cadu', 'felipe_clemente',
  'jean_carlos', 'halerrandrio', 'esli_garcia', 'kadu_sousa',
];

const squadMapping = JSON.parse(fs.readFileSync(path.join(RECON, 'squad_members_person_mapping.json'), 'utf8'));
const squadMappingById = new Map(squadMapping.map((m) => [m.squadMemberId, m]));

const mapping = [];
for (const squadPlayerId of GOIAS_SQUAD_IDS) {
  const f4 = squadMappingById.get(squadPlayerId);
  if (!f4) {
    mapping.push({ squadPlayerId, personId: null, canonicalName: null, source: 'squad_members_person_mapping', status: 'UNRESOLVED', notes: 'squadPlayerId não encontrado em squad_members_person_mapping.json (F4) — goiasSquad e squad_members deveriam compartilhar o mesmo id-space; isto é uma divergência de dado, reportar antes de prosseguir.' });
    continue;
  }
  if (f4.status !== 'RESOLVED') {
    mapping.push({ squadPlayerId, personId: null, canonicalName: f4.canonicalName ?? null, source: 'squad_members_person_mapping', status: f4.status, notes: `F4 classificou squad_members:${squadPlayerId} como ${f4.status}, não RESOLVED — não propagar um person_id que a própria F4 não aprovou.` });
    continue;
  }
  mapping.push({ squadPlayerId, personId: f4.personId, canonicalName: f4.canonicalName, source: 'squad_members_person_mapping', status: 'RESOLVED', notes: null });
}

const resolved = mapping.filter((m) => m.status === 'RESOLVED');
const personIdCounts = new Map();
for (const m of resolved) personIdCounts.set(m.personId, (personIdCounts.get(m.personId) || 0) + 1);
const duplicatePersonIds = [...personIdCounts.entries()].filter(([, c]) => c > 1);

const stats = {
  total: mapping.length,
  RESOLVED: resolved.length,
  UNRESOLVED: mapping.filter((m) => m.status === 'UNRESOLVED').length,
  AMBIGUOUS: mapping.filter((m) => m.status === 'AMBIGUOUS').length,
  OUT_OF_SCOPE: mapping.filter((m) => m.status === 'OUT_OF_SCOPE').length,
  duplicatePersonIdsAmongResolved: duplicatePersonIds.length,
  allResolved100pct: resolved.length === mapping.length,
};

fs.writeFileSync(path.join(OUT_DIR, 'crowd_lineup_person_mapping.json'), JSON.stringify(mapping, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'crowd_lineup_person_mapping_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);
