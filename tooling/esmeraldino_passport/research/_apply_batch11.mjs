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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1368.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
const FDG = 'https://www.futeboldegoyaz.com.br/partidas/';
function mk(fichaId, venue, city, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz', source_url_if_empty: FDG + fichaId + '/partida', conflict_note: note, notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 11).` };
}

const updates = {
  // 1950 (edição 580)
  'hist-f80-0105': mk(49794, 'Manoel Demóstenes', 'Anápolis', 'Ficha 49794 (Citadino 1950, rodada 13, 23/07/1950): "Flamengo 0 x 4 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0116': mk(49838, 'Antônio Accioly', 'Goiânia', 'Ficha 49838 (rodada 32, 03/12/1950): "Goiás 2 x 0 Anápolis" — data, placar e mando batem exatamente; CSV registra o adversário como "União Operária" (mesmo alias de Anápolis já visto na rodada 16).'),
  // 1951 (edição 582)
  'hist-f80-0137': mk(47285, 'Manoel Demóstenes', 'Anápolis', 'Ficha 47285 (Citadino 1951, rodada 20, 30/09/1951): "Anápolis 1 x 6 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0138': mk(47290, 'Olímpico', 'Goiânia', 'Ficha 47290 (rodada 22, 14/10/1951): "Goiás 3 x 3 União" — data, placar e mando batem exatamente.'),
  'hist-f80-0139': mk(47292, 'Olímpico', 'Goiânia', 'Ficha 47292 (rodada 23, 21/10/1951): "Goiás 9 x 0 Flamengo" — data, placar e mando batem exatamente.'),
  'hist-f80-0140': mk(47296, 'Olímpico', 'Goiânia', 'Ficha 47296 (rodada 25, 28/10/1951): "Sírio Libanês 0 x 0 Goiás" — data e placar batem exatamente; CSV registra o adversário como "Botafogo" (mesmo alias de Sírio Libanês já visto em 1950/1954).'),
  'hist-f80-0142': mk(47302, 'Olímpico', 'Goiânia', 'Ficha 47302 (rodada 28, 15/11/1951): "Goiás 5 x 1 São Francisco" — data, placar e mando batem exatamente.'),
  'hist-f80-0143': mk(47305, 'Olímpico', 'Goiânia', 'Ficha 47305 (rodada 30, 25/11/1951): "Goiás 4 x 1 Anapolina" — data, placar e mando batem exatamente.'),
  'hist-f80-0144': mk(47309, 'Olímpico', 'Goiânia', 'Ficha 47309 (rodada 32, 09/12/1951): "Goiás 2 x 0 Goiânia" — data, placar e mando batem exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1377.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
