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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1301.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
function mk(venue, city, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz (confronto direto)', source_url_if_empty: 'https://www.futeboldegoyaz.com.br/clubes/469/688/confronto', conflict_note: note, notes_append: `Estádio confirmado via página de confronto direto do Futebol de Goyaz, 2026-09-28 (lote 7).` };
}

const updates = {
  'hist-f80-0932': mk('Olímpico', 'Goiânia', 'Confronto direto Goiás x Ceará: 27/10/1973, Goiás 4x1 Ceará, Série A — data e placar batem exatamente.'),
  'hist-f80-1214': mk('Castelão', 'Fortaleza', 'Confronto direto Goiás x Ceará: 17/06/1978, Ceará 3x2 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1298': mk('Castelão', 'Fortaleza', 'Confronto direto Goiás x Ceará: 20/10/1979, Ceará 0x2 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1307': mk('Serra Dourada', 'Goiânia', 'Confronto direto Goiás x Ceará: 28/11/1979, Goiás 1x0 Ceará, Série A — data e placar batem exatamente.'),
  'hist-f80-2178': mk('Castelão', 'Fortaleza', 'Confronto direto Goiás x Ceará: 12/09/1993, Ceará 3x1 Goiás, Série A — data e placar batem exatamente.'),
};

let changed = 0, alreadyResolved = [], notFound = [];
for (const id in updates) {
  const rowRef = table.slice(1).find(r => r[idx.id] === id);
  if (!rowRef) { notFound.push(id); continue; }
  if (rowRef[idx.venue_name] !== 'UNKNOWN' && rowRef[idx.venue_name] !== '') { alreadyResolved.push(id); continue; }
  const u = updates[id];
  rowRef[idx.venue_name] = u.venue_name;
  rowRef[idx.venue_city] = u.venue_city;
  rowRef[idx.venue_confidence] = u.venue_confidence;
  rowRef[idx.source_secondary] = u.source_secondary;
  if (!rowRef[idx.source_url]) rowRef[idx.source_url] = u.source_url_if_empty;
  rowRef[idx.conflict_note] = u.conflict_note;
  const oldNotes = rowRef[idx.notes];
  rowRef[idx.notes] = oldNotes ? (oldNotes + ' ' + u.notes_append) : u.notes_append;
  changed++;
}
console.log('changed rows:', changed, 'skipped:', alreadyResolved, 'NOT FOUND:', notFound);
const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1306.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
