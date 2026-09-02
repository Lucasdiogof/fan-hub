// Etapa F6 — injeta personId: '<uuid>' logo após cada `name: '<nome>',`
// em lib/features/arena/games/career_path/goias_players.dart, usando
// goias_players_person_mapping.json (gerado por
// build_goias_players_person_mapping.mjs) como única fonte. Mecânico:
// nenhuma lógica de resolução mora aqui. Só as entradas RESOLVED (status
// exato, 41/215 hoje) recebem personId — as outras 174 continuam com
// personId omitido (default null via construtor). Aborta (sem escrever
// nada) se o arquivo já tiver alguma linha `personId:` — não é seguro
// rodar 2x.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const TARGET = path.join(ROOT, 'lib', 'features', 'arena', 'games', 'career_path', 'goias_players.dart');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'goias_players_person_mapping.json'), 'utf8'));
const byIndex = new Map(mapping.map((m) => [m.sourceIndex, m]));

const raw = fs.readFileSync(TARGET, 'utf8');
if (/personId:/.test(raw)) {
  throw new Error(`ABORTADO: ${path.relative(ROOT, TARGET)} já tem 'personId:' — este script não é seguro pra rodar 2x. Reverta o arquivo antes de reaplicar.`);
}
const usesCRLF = raw.includes('\r\n');
const lines = raw.split(/\r\n|\n/);

const entryLineRe = /^(\s*)GoiasPlayer\(name: '((?:[^'\\]|\\.)*)'(, aliases: \[[^\]]*\])?\),$/;
let index = -1;
let injected = 0;
const output = lines.map((line) => {
  const m = line.match(entryLineRe);
  if (!m) return line;
  index++;
  const [, indent, , aliasesPart] = m;
  const entry = byIndex.get(index);
  if (!entry) throw new Error(`Índice ${index} não encontrado no mapping — abortando sem escrever.`);
  if (entry.status !== 'RESOLVED') return line;
  injected++;
  return `${indent}GoiasPlayer(name: '${entry.sourceName.replace(/'/g, "\\'")}', personId: '${entry.personId}'${aliasesPart || ''}),`;
});

if (index + 1 !== mapping.length) {
  throw new Error(`processei ${index + 1} entradas GoiasPlayer(...) no arquivo, mas o mapping tem ${mapping.length} — abortando sem escrever.`);
}
const expectedResolved = mapping.filter((m) => m.status === 'RESOLVED').length;
if (injected !== expectedResolved) {
  throw new Error(`injetei personId em ${injected} entradas, mas o mapping tem ${expectedResolved} RESOLVED — abortando sem escrever.`);
}

fs.writeFileSync(TARGET, output.join(usesCRLF ? '\r\n' : '\n'));
console.log(`personId injetado em ${injected} de ${mapping.length} GoiasPlayer(...) em ${path.relative(ROOT, TARGET)}`);
