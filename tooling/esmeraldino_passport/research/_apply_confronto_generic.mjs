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

const SRC = process.argv[2];
const OPP = process.argv[3];
const OUT = process.argv[4];
const CONF_URL = process.argv[5];
const dataFile = process.argv[6];

const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

const confronto = JSON.parse(fs.readFileSync(dataFile, 'utf8'));

const monthMap = {jan:'01',fev:'02',mar:'03',abr:'04',mai:'05',jun:'06',jul:'07',ago:'08',set:'09',out:'10',nov:'11',dez:'12'};
function toDMY(s){ const m = s.match(/(\d{2})\/(\w{3})\/(\d{4})/); if(!m) return null; return `${m[1]}/${monthMap[m[2]]}/${m[3]}`; }
function scoreSet(scoreDisplay) { const m = scoreDisplay.match(/(\d+)\s*x\s*(\d+)/); if (!m) return null; return [parseInt(m[1]), parseInt(m[2])].sort((a,b)=>a-b).join('-'); }
function confrontoScoreSet(scoreStr) { const m = scoreStr.match(/(\d+)(?:\s*\(\d+\))?\s*x\s*(?:\(\d+\)\s*)?(\d+)/); if (!m) return null; return [parseInt(m[1]), parseInt(m[2])].sort((a,b)=>a-b).join('-'); }

let changed = 0, checked = 0, mismatched = [];
for (const r of table.slice(1)) {
  if (r[idx.dataset_origin] !== 'historical_futebol80') continue;
  if (r[idx.venue_name] !== 'UNKNOWN') continue;
  if (r[idx.opponent] !== OPP) continue;
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
  if (!r[idx.source_url]) r[idx.source_url] = CONF_URL;
  r[idx.conflict_note] = `Confronto direto Goiás x ${OPP}: ficha ${hit[0]} "${hit[1]}", Campeonato Goiano — data e placar batem.`;
  r[idx.notes] = (r[idx.notes] ? r[idx.notes] + ' ' : '') + `Estádio confirmado via confronto direto FdG, 2026-09-28.`;
  changed++;
}
console.log(OPP, 'checked:', checked, 'changed:', changed, 'no match:', mismatched.length);
console.log(mismatched);
const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
