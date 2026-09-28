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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1378.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
const FDG = 'https://www.futeboldegoyaz.com.br/partidas/';
function mk(fichaId, venue, city, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz', source_url_if_empty: FDG + fichaId + '/partida', conflict_note: note, notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 12).` };
}

const updates = {
  'hist-f80-0125': mk(47266, 'Olímpico', 'Goiânia', 'Ficha 47266 (Citadino 1951, rodada 2, 20/05/1951): "Goiás 8 x 1 Anápolis" — data, placar e mando batem exatamente; CSV registra o adversário como "União Operária" (mesmo alias de Anápolis já visto).'),
  'hist-f80-0127': mk(47271, 'Olímpico', 'Goiânia', 'Ficha 47271 (rodada 5, 10/06/1951): "União 1 x 4 Goiás" — data e placar batem exatamente.'),
  'hist-f80-0128': mk(47273, 'Manoel Demóstenes', 'Anápolis', 'Ficha 47273 (rodada 6, 17/06/1951): "Flamengo 1 x 3 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0130': mk(47250, 'Manoel Demóstenes', 'Anápolis', 'Ficha 47250 (rodada 11, 22/07/1951): "Anapolina 2 x 3 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0133': mk(47255, 'Manoel Demóstenes', 'Anápolis', 'Ficha 47255 (rodada 13, 05/08/1951): "São Francisco 2 x 3 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0135': mk(47262, 'Olímpico', 'Goiânia', 'Ficha 47262 (rodada 17, 02/09/1951): "Goiânia 3 x 1 Goiás" — data, placar e mando batem exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1384.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
