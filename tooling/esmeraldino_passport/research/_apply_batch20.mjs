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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1418.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

// [date DD/MM/YYYY, score "A x B" as shown (mandante x visitante), venue]
const confronto = [
  ['30/08/1970','Itumbiara 2 x 3 Goiás','Do Goiazinho','Itumbiara'],
  ['25/11/1970','Goiás 1 x 1 Itumbiara','Olímpico','Goiânia'],
  ['05/07/1972','Goiás 2 x 0 Itumbiara','Olímpico','Goiânia'],
  ['20/08/1972','Itumbiara 0 x 0 Goiás','Do Goiazinho','Itumbiara'],
  ['11/08/1974','Goiás 2 x 0 Itumbiara','Olímpico','Goiânia'],
  ['20/10/1974','Itumbiara 0 x 1 Goiás','Paranaíba','Itumbiara'],
  ['07/05/1975','Goiás 1 x 1 Itumbiara','Olímpico','Goiânia'],
  ['22/06/1975','Itumbiara 0 x 0 Goiás','Paranaíba','Itumbiara'],
  ['24/07/1977','Goiás 0 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['30/04/1977','Itumbiara 1 x 2 Goiás','JK','Itumbiara'],
  ['31/08/1978','Goiás 2 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['05/11/1978','Itumbiara 2 x 1 Goiás','JK','Itumbiara'],
  ['17/06/1979','Itumbiara 0 x 0 Goiás','JK','Itumbiara'],
  ['22/07/1979','Goiás 0 x 0 Itumbiara','Serra Dourada','Goiânia'],
  ['15/08/1979','Goiás 1 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['16/10/1980','Goiás 2 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['07/10/1981','Goiás 1 x 0 Itumbiara','Serra Dourada','Goiânia'],
  ['03/09/1981','Itumbiara 2 x 1 Goiás','JK','Itumbiara'],
  ['29/07/1981','Itumbiara 1 x 0 Goiás','JK','Itumbiara'],
  ['07/06/1981','Itumbiara 1 x 1 Goiás','JK','Itumbiara'],
  ['20/05/1981','Goiás 1 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['04/07/1982','Itumbiara 2 x 3 Goiás','JK','Itumbiara'],
  ['12/05/1982','Goiás 0 x 0 Itumbiara','Serra Dourada','Goiânia'],
  ['25/08/1982','Goiás 0 x 0 Itumbiara','Serra Dourada','Goiânia'],
  ['26/09/1982','Itumbiara 2 x 1 Goiás','JK','Itumbiara'],
  ['04/11/1982','Goiás 2 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['17/11/1982','Itumbiara 1 x 1 Goiás','JK','Itumbiara'],
  ['03/08/1983','Goiás 0 x 1 Itumbiara','Serra Dourada','Goiânia'],
  ['28/08/1983','Itumbiara 1 x 0 Goiás','JK','Itumbiara'],
  ['12/06/1983','Itumbiara 2 x 2 Goiás','JK','Itumbiara'],
  ['03/11/1983','Goiás 2 x 0 Itumbiara','Serra Dourada','Goiânia'],
  ['06/06/1999','Goiás 5 x 2 Itumbiara','Serrinha','Goiânia'],
];

// build target date list from CSV pending rows (DD/mmm/YYYY -> parse to DD/MM/YYYY)
const monthMap = {jan:'01',fev:'02',mar:'03',abr:'04',mai:'05',jun:'06',jul:'07',ago:'08',set:'09',out:'10',nov:'11',dez:'12'};
function toDMY(s){ const m = s.match(/(\d{2})\/(\w{3})\/(\d{4})/); if(!m) return null; return `${m[1]}/${monthMap[m[2]]}/${m[3]}`; }

function scoreSet(scoreDisplay) {
  // "3 x 2" -> sorted [2,3] as a simple unordered-pair check
  const m = scoreDisplay.match(/(\d+)\s*x\s*(\d+)/);
  if (!m) return null;
  return [parseInt(m[1]), parseInt(m[2])].sort((a,b)=>a-b).join('-');
}
function confrontoScoreSet(scoreStr) {
  const m = scoreStr.match(/(\d+)(?:\s*\(\d+\))?\s*x\s*(?:\(\d+\)\s*)?(\d+)/);
  if (!m) return null;
  return [parseInt(m[1]), parseInt(m[2])].sort((a,b)=>a-b).join('-');
}

let changed = 0, checked = 0, mismatched = [];
for (const r of table.slice(1)) {
  if (r[idx.dataset_origin] !== 'historical_futebol80') continue;
  if (r[idx.venue_name] !== 'UNKNOWN') continue;
  if (r[idx.opponent] !== 'Itumbiara-GO') continue;
  const dmy = toDMY(r[idx.date_original]);
  if (!dmy) continue;
  checked++;
  const csvScore = scoreSet(r[idx.score_display]);
  // find exact or +/-2 day match in confronto list by date, AND matching score (unordered)
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
  if (!r[idx.source_url]) r[idx.source_url] = 'https://www.futeboldegoyaz.com.br/clubes/469/476/confronto';
  r[idx.conflict_note] = `Confronto direto Goiás x Itumbiara: ficha ${hit[0]} "${hit[1]}", Campeonato Goiano — data (${hit[0] === dmy ? 'exata' : 'poucos dias de diferença'}) e placar batem.`;
  r[idx.notes] = (r[idx.notes] ? r[idx.notes] + ' ' : '') + 'Estádio confirmado via confronto direto FdG (tabela completa Goiás x Itumbiara), 2026-09-28 (lote 20).';
  changed++;
}
console.log('checked pending Itumbiara-Goiano rows:', checked, 'changed:', changed, 'no match:', mismatched.length);
console.log(mismatched);
const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1449.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
