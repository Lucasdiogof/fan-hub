// Etapa F5 (endurecimento) — roda computeSquadDrift contra as fontes
// REAIS (o .dart que roda de verdade + squad_members.json, o mesmo
// export já validado pela F4) e persiste o resultado pra auditoria
// futura. Não corrige nada — só reporta.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { extractSquadPlayerFields, computeSquadDrift } from './crowd_lineup_squad_drift.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DART_FILE = path.join(ROOT, 'lib', 'features', 'crowd_lineup', 'domain', 'goias_squad.dart');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const dartSrc = fs.readFileSync(DART_FILE, 'utf8');
const squadMembers = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'squad_members.json'), 'utf8'));

const entries = extractSquadPlayerFields(dartSrc);
if (entries.length !== 31) {
  console.error(`ABORTADO: extraí ${entries.length} SquadPlayer(...) do .dart, esperava 31.`);
  process.exit(1);
}

const { rows, stats } = computeSquadDrift(entries, squadMembers);

fs.writeFileSync(path.join(OUT_DIR, 'crowd_lineup_squad_drift_report.json'), JSON.stringify({ rows, stats }, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);

if (stats.NAME_DIVERGENCE > 0 || stats.SHIRT_DIVERGENCE > 0) {
  console.log('\n⚠ Divergências reais encontradas — reportar ao usuário, NÃO corrigir automaticamente, NÃO commitar sem revisão.');
}
