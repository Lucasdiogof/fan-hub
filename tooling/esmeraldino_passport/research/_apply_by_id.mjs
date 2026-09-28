// Aplica confirmacoes de estadio por ID exato (pra linhas fora do
// dataset_origin='historical_futebol80', onde o _apply_confronto_generic.mjs
// nao serve — datas ISO, nao DD/mon/AAAA).
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
const OUT = process.argv[3];
const dataFile = process.argv[4];

const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

const byId = JSON.parse(fs.readFileSync(dataFile, 'utf8'));

let changed = 0, notFound = [];
const seen = new Set();
for (const r of table.slice(1)) {
  const id = r[idx.id];
  if (!byId[id]) continue;
  seen.add(id);
  const hit = byId[id];
  if (r[idx.venue_name] && r[idx.venue_name] !== 'UNKNOWN') { console.log('SKIP (already has venue):', id, r[idx.venue_name]); continue; }
  r[idx.venue_name] = hit.venue_name;
  r[idx.venue_city] = hit.venue_city;
  r[idx.venue_state] = hit.venue_state || 'GO';
  r[idx.venue_confidence] = 'HIGH';
  r[idx.source_secondary] = 'Futebol de Goyaz (confronto direto)';
  if (!r[idx.source_url]) r[idx.source_url] = hit.source_url;
  r[idx.conflict_note] = hit.note || '';
  r[idx.notes] = (r[idx.notes] ? r[idx.notes] + ' ' : '') + 'Estádio confirmado via Futebol de Goyaz (confronto direto), 2026-09-28.';
  changed++;
}
for (const id of Object.keys(byId)) { if (!seen.has(id)) notFound.push(id); }
console.log('changed:', changed, 'not found in CSV:', notFound);

const outLines = table.map(row => row.map(csvField).join(',')).join('\r\n');
fs.writeFileSync(OUT, '﻿' + outLines, 'utf8');
console.log('wrote', OUT);
