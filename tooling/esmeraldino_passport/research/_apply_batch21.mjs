import fs from 'fs';
function parseCSV(text) {
  const rows = []; let i = 0; const len = text.length; let field = ''; let row = []; let inQuotes = false;
  while (i < len) {
    const c = text[i];
    if (inQuotes) { if (c === '"') { if (text[i + 1] === '"') { field += '"'; i += 2; continue; } inQuotes = false; i++; continue; } field += c; i++; continue; }
    else { if (c === '"') { inQuotes = true; i++; continue; } if (c === ',') { row.push(field); field = ''; i++; continue; } if (c === '\r') { i++; continue; } if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; i++; continue; } field += c; i++; continue; }
  }
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row); }
  return rows;
}
function csvField(v) { v = v == null ? '' : String(v); if (/[",\n]/.test(v)) return '"' + v.replace(/"/g, '""') + '"'; return v; }

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1449.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

const confronto = [
  ['31/10/1965','Goiás 0 x 3 Goiânia','Olímpico','Goiânia'],
  ['01/08/1965','Goiânia 1 x 1 Goiás','Olímpico','Goiânia'],
  ['22/07/1964','Goiás 1 x 1 Goiânia','Olímpico','Goiânia'],
  ['04/11/1964','Goiânia 2 x 2 Goiás','Olímpico','Goiânia'],
  ['21/08/1966','Goiânia 0 x 0 Goiás','Olímpico','Goiânia'],
  ['27/04/1966','Goiás 2 x 1 Goiânia','Olímpico','Goiânia'],
  ['14/10/1967','Goiânia 1 x 2 Goiás','Olímpico','Goiânia'],
  ['10/09/1967','Goiás 1 x 2 Goiânia','Olímpico','Goiânia'],
  ['14/07/1968','Goiás 3 x 2 Goiânia','Olímpico','Goiânia'],
  ['01/12/1968','Goiânia 0 x 0 Goiás','Olímpico','Goiânia'],
  ['02/03/1969','Goiânia 0 x 1 Goiás','Olímpico','Goiânia'],
  ['02/07/1969','Goiás 1 x 1 Goiânia','Olímpico','Goiânia'],
  ['27/08/1970','Goiânia 0 x 0 Goiás','Olímpico','Goiânia'],
  ['29/11/1970','Goiás 0 x 3 Goiânia','Olímpico','Goiânia'],
  ['02/05/1971','Goiânia 0 x 2 Goiás','Olímpico','Goiânia'],
  ['01/08/1971','Goiás 2 x 1 Goiânia','Olímpico','Goiânia'],
  ['18/06/1972','Goiás 4 x 2 Goiânia','Olímpico','Goiânia'],
  ['10/09/1972','Goiás 2 x 1 Goiânia','Olímpico','Goiânia'],
  ['03/06/1973','Goiás 4 x 0 Goiânia','Olímpico','Goiânia'],
  ['22/07/1973','Goiânia 1 x 0 Goiás','Olímpico','Goiânia'],
  ['15/09/1974','Goiás 1 x 1 Goiânia','Olímpico','Goiânia'],
  ['20/11/1974','Goiás 0 x 1 Goiânia','Olímpico','Goiânia'],
  ['13/10/1974','Goiás 1 x 0 Goiânia','Olímpico','Goiânia'],
  ['24/11/1974','Goiânia 1 x 1 Goiás','Olímpico','Goiânia'],
  ['14/08/1975','Goiás 0 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['20/04/1975','Goiás 2 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['27/07/1975','Goiás 3 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['10/08/1975','Goiânia 0 x 1 Goiás','Serra Dourada','Goiânia'],
  ['17/08/1975','Goiás 3 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['15/05/1977','Goiânia 0 x 0 Goiás','Serra Dourada','Goiânia'],
  ['07/08/1977','Goiás 1 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['25/09/1977','Goiânia 1 x 0 Goiás','Serra Dourada','Goiânia'],
  ['20/08/1978','Goiás 1 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['22/10/1978','Goiás 3 x 1 Goiânia','Serra Dourada','Goiânia'],
  ['11/03/1979','Goiânia 1 x 0 Goiás','Serra Dourada','Goiânia'],
  ['01/04/1979','Goiás 4 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['06/07/1980','Goiânia 1 x 1 Goiás','Serra Dourada','Goiânia'],
  ['17/08/1980','Goiás 3 x 2 Goiânia','Serra Dourada','Goiânia'],
  ['21/09/1980','Goiânia 2 x 1 Goiás','Serra Dourada','Goiânia'],
  ['05/10/1980','Goiânia 0 x 0 Goiás','Serra Dourada','Goiânia'],
  ['24/05/1981','Goiás 1 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['14/06/1981','Goiás 1 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['12/08/1981','Goiás 2 x 1 Goiânia','Olímpico','Goiânia'],
  ['21/10/1981','Goiás 0 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['28/03/1982','Goiás 1 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['20/06/1982','Goiânia 2 x 1 Goiás','Serra Dourada','Goiânia'],
  ['29/08/1982','Goiás 1 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['10/10/1982','Goiás 3 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['10/07/1983','Goiás 0 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['10/08/1983','Goiânia 2 x 1 Goiás','Serra Dourada','Goiânia'],
  ['14/08/1983','Goiás 3 x 1 Goiânia','Serra Dourada','Goiânia'],
  ['18/09/1983','Goiânia 0 x 0 Goiás','Serra Dourada','Goiânia'],
  ['09/10/1983','Goiás 0 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['29/05/1983','Goiás 2 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['28/03/1990','Goiânia 0 x 2 Goiás','Serra Dourada','Goiânia'],
  ['01/04/1990','Goiás 2 x 0 Goiânia','Serra Dourada','Goiânia'],
  ['15/04/1990','Goiás 4 x 1 Goiânia','Serra Dourada','Goiânia'],
  ['06/05/1990','Goiás 4 x 1 Goiânia','Serra Dourada','Goiânia'],
  ['09/05/1990','Goiânia 0 x 2 Goiás','Serra Dourada','Goiânia'],
  ['12/05/1990','Goiás 5 x 0 Goiânia','Serra Dourada','Goiânia'],
];

const monthMap = {jan:'01',fev:'02',mar:'03',abr:'04',mai:'05',jun:'06',jul:'07',ago:'08',set:'09',out:'10',nov:'11',dez:'12'};
function toDMY(s){ const m = s.match(/(\d{2})\/(\w{3})\/(\d{4})/); if(!m) return null; return `${m[1]}/${monthMap[m[2]]}/${m[3]}`; }
function scoreSet(scoreDisplay) { const m = scoreDisplay.match(/(\d+)\s*x\s*(\d+)/); if (!m) return null; return [parseInt(m[1]), parseInt(m[2])].sort((a,b)=>a-b).join('-'); }
function confrontoScoreSet(scoreStr) { const m = scoreStr.match(/(\d+)(?:\s*\(\d+\))?\s*x\s*(?:\(\d+\)\s*)?(\d+)/); if (!m) return null; return [parseInt(m[1]), parseInt(m[2])].sort((a,b)=>a-b).join('-'); }

let changed = 0, checked = 0, mismatched = [];
for (const r of table.slice(1)) {
  if (r[idx.dataset_origin] !== 'historical_futebol80') continue;
  if (r[idx.venue_name] !== 'UNKNOWN') continue;
  if (r[idx.opponent] !== 'Goiânia-GO') continue;
  const dmy = toDMY(r[idx.date_original]);
  if (!dmy) continue;
  checked++;
  const csvScore = scoreSet(r[idx.score_display]);
  const [dd,mm,yyyy] = dmy.split('/').map(Number);
  let hit = null;
  for (const c of confronto) {
    const [cd,cm,cy] = c[0].split('/').map(Number);
    if (cy !== yyyy || cm !== mm) continue;
    if (Math.abs(cd - dd) > 2) continue;
    if (csvScore && confrontoScoreSet(c[1]) !== csvScore) continue;
    hit = c; break;
  }
  if (!hit) { mismatched.push([r[idx.id], dmy, r[idx.score_display]]); continue; }
  r[idx.venue_name] = hit[2];
  r[idx.venue_city] = hit[3];
  r[idx.venue_confidence] = 'HIGH';
  r[idx.source_secondary] = 'Futebol de Goyaz (confronto direto)';
  if (!r[idx.source_url]) r[idx.source_url] = 'https://www.futeboldegoyaz.com.br/clubes/469/1/confronto';
  r[idx.conflict_note] = `Confronto direto Goiás x Goiânia: ficha ${hit[0]} "${hit[1]}", Campeonato Goiano — data e placar batem.`;
  r[idx.notes] = (r[idx.notes] ? r[idx.notes] + ' ' : '') + 'Estádio confirmado via confronto direto FdG (tabela completa Goiás x Goiânia), 2026-09-28 (lote 21).';
  changed++;
}
console.log('checked:', checked, 'changed:', changed, 'no match:', mismatched.length);
console.log(mismatched);
const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1481.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
