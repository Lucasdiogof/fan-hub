import fs from 'fs';

function parseCSV(text) {
  const rows = [];
  let i = 0;
  const len = text.length;
  let field = '';
  let row = [];
  let inQuotes = false;
  while (i < len) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i++; continue;
      }
      field += c; i++; continue;
    } else {
      if (c === '"') { inQuotes = true; i++; continue; }
      if (c === ',') { row.push(field); field = ''; i++; continue; }
      if (c === '\r') { i++; continue; }
      if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; i++; continue; }
      field += c; i++; continue;
    }
  }
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row); }
  return rows;
}

function csvField(v) {
  v = v == null ? '' : String(v);
  if (/[",\n]/.test(v)) return '"' + v.replace(/"/g, '""') + '"';
  return v;
}

const raw = fs.readFileSync(process.argv[2] || 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1259.csv', 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

const out = [ [...header, 'venue_pending_type'] ];
let unknownCount = 0, emptyCount = 0, confirmed2102 = 0, total2102 = 0;

for (const r of table.slice(1)) {
  if (r.length < 2) continue;
  const venue = r[idx.venue_name];
  const origin = r[idx.dataset_origin];
  if (origin === 'historical_futebol80') {
    total2102++;
    if (venue !== 'UNKNOWN') confirmed2102++;
  }
  if (venue === 'UNKNOWN') { out.push([...r, 'UNKNOWN']); unknownCount++; }
  else if (!venue) { out.push([...r, 'EMPTY']); emptyCount++; }
}

console.log('pending rows:', out.length - 1, '(unknown=', unknownCount, 'empty=', emptyCount, ')');
console.log('2102-scope confirmed:', confirmed2102, '/', total2102, '=', (confirmed2102/total2102*100).toFixed(2)+'%');

const outLines = out.map(r => r.map(csvField).join(',')).join('\r\n');
const outName = process.argv[3] || 'GOIAS_PENDENCIAS_ESTADIOS_1259.csv';
fs.writeFileSync(outName, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', outName);
