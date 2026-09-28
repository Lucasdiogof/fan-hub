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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1384.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
const FDG = 'https://www.futeboldegoyaz.com.br/partidas/';
function mk(fichaId, venue, city, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz', source_url_if_empty: FDG + fichaId + '/partida', conflict_note: note, notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 13).` };
}

const updates = {
  'hist-f80-0068': mk(47108, 'Olímpico', 'Goiânia', 'Ficha 47108 (Citadino 1948, rodada 1, 16/05/1948): "Goiás 8 x 0 União" — data, placar e mando batem exatamente; CSV registra o adversário como "ABG" (possível alias de União nesta edição — confiança MEDIA, revisar se aparecer outra pendência ABG/União no mesmo ano).'),
  'hist-f80-0072': mk(47115, 'Olímpico', 'Goiânia', 'Ficha 47115 (rodada 6, 27/06/1948): "Goiânia 2 x 1 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0073': mk(47120, 'Olímpico', 'Goiânia', 'Ficha 47120 (rodada 8, 18/07/1948): "Goiás 3 x 1 Sírio Libanês" — data, placar e mando batem exatamente; CSV registra o adversário como "Botafogo" (alias já visto em 1950/1951/1954).'),
  'hist-f80-0076': mk(47130, 'Antônio Accioly', 'Goiânia', 'Ficha 47130 (rodada 15, 12/09/1948): "União 1 x 2 Goiás" — data e placar batem exatamente; CSV registra o adversário como "ABG" (mesmo alias tentativo da rodada 1 — confiança MEDIA).'),
  'hist-f80-0082': mk(47148, 'Olímpico', 'Goiânia', 'Ficha 47148 (rodada 26, 05/12/1948): "Sírio Libanês 0 x 8 Goiás" — data e placar batem exatamente; CSV registra o adversário como "Botafogo".'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1389.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
