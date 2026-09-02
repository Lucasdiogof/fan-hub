// Etapa F5 — injeta personId: '<uuid>' logo após cada `id: '<slug>',` em
// lib/features/crowd_lineup/domain/goias_squad.dart, usando
// crowd_lineup_person_mapping.json (gerado por
// build_crowd_lineup_person_mapping.mjs) como única fonte. Mecânico:
// nenhuma lógica de resolução mora aqui. Aborta (sem escrever nada) se o
// mapping não estiver 100% RESOLVED, ou se algum id do arquivo não tiver
// entrada no mapping — nunca escreve um SquadPlayer sem personId (o campo
// é non-null).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TARGET = path.join(ROOT, 'lib', 'features', 'crowd_lineup', 'domain', 'goias_squad.dart');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'crowd_lineup_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'crowd_lineup_person_mapping_stats.json'), 'utf8'));

if (!stats.allResolved100pct) {
  console.error(`ABORTADO: mapping não está 100% RESOLVED (${stats.RESOLVED}/${stats.total}) — SquadPlayer.personId é non-null, não posso aplicar com gaps. Corrija a resolução antes de rodar este script.`);
  process.exit(1);
}

const byId = new Map(mapping.map((m) => [m.squadPlayerId, m]));

const raw = fs.readFileSync(TARGET, 'utf8');
if (/^\s*personId: '[0-9a-f-]{36}',$/m.test(raw)) {
  throw new Error(`ABORTADO: ${path.relative(ROOT, TARGET)} já tem linhas 'personId:' — este script não é seguro pra rodar 2x (duplicaria o campo). Se o objetivo é reaplicar com um mapping atualizado, reverta o arquivo pro estado sem personId primeiro.`);
}
const usesCRLF = raw.includes('\r\n');
const lines = raw.split(/\r\n|\n/);

const idLineRe = /^(\s*)id: '([a-z0-9_]+)',$/;
let injected = 0;
const output = [];
for (const line of lines) {
  output.push(line);
  const m = line.match(idLineRe);
  if (!m) continue;
  const [, indent, slug] = m;
  const entry = byId.get(slug);
  if (!entry || entry.status !== 'RESOLVED') {
    throw new Error(`id '${slug}' encontrado em goias_squad.dart mas sem mapping RESOLVED — abortando sem escrever nada.`);
  }
  output.push(`${indent}personId: '${entry.personId}',`);
  injected++;
}

if (injected !== mapping.length) {
  throw new Error(`injetei personId em ${injected} linhas, mas o mapping tem ${mapping.length} entradas RESOLVED — algum id do mapping não foi encontrado no arquivo (ou o arquivo já tinha personId injetado antes). Abortando sem escrever.`);
}

fs.writeFileSync(TARGET, output.join(usesCRLF ? '\r\n' : '\n'));
console.log(`personId injetado em ${injected} SquadPlayer(...) em ${path.relative(ROOT, TARGET)}`);
