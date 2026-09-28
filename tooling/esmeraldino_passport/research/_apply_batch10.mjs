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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1355.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
const FDG = 'https://www.futeboldegoyaz.com.br/partidas/';
function mk(fichaId, venue, city, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz', source_url_if_empty: FDG + fichaId + '/partida', conflict_note: note, notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 10).` };
}

const updates = {
  'hist-f80-0098': mk(49770, 'Olímpico', 'Goiânia', 'Ficha 49770 (Citadino 1950, rodada 1, 23/04/1950): "Goiás 3 x 2 Anapolina" — data, placar e mando batem exatamente.'),
  'hist-f80-0100': mk(49776, 'Olímpico', 'Goiânia', 'Ficha 49776 (rodada 3, 07/05/1950): "Goiás 4 x 0 União" — data, placar e mando batem exatamente.'),
  'hist-f80-0102': mk(49783, 'Olímpico', 'Goiânia', 'Ficha 49783 (rodada 8, 18/06/1950): "Goiás 1 x 1 Sírio Libanês" — data, placar e mando batem exatamente; CSV registra o adversário como "Botafogo" (mesmo padrão de alias visto em 1954 — edição não lista Botafogo separado de Sírio Libanês).'),
  'hist-f80-0103': mk(49785, 'Antônio Accioly', 'Goiânia', 'Ficha 49785 (rodada 9, 25/06/1950): "Inhumas 1 x 4 Goiás" — data e placar batem exatamente.'),
  'hist-f80-0106': mk(49798, 'Olímpico', 'Goiânia', 'Ficha 49798 (rodada 15, 06/08/1950): "Araguaia 1 x 6 Goiás" — data e placar batem exatamente.'),
  'hist-f80-0107': mk(49803, 'Manoel Demóstenes', 'Anápolis', 'Ficha 49803 (rodada 16, 20/08/1950): "Anápolis 1 x 6 Goiás" — data e placar batem exatamente; CSV registra o adversário como "União Operária" (possível alias de Anápolis nesta edição, mesmo padrão do Botafogo/Sírio Libanês).'),
  'hist-f80-0108': mk(49805, 'Manoel Demóstenes', 'Anápolis', 'Ficha 49805 (rodada 17, 07/09/1950): "Anapolina 1 x 1 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0109': mk(49811, 'Olímpico', 'Goiânia', 'Ficha 49811 (rodada 19, 17/09/1950): "Goiás 1 x 1 Araguaia" — data, placar e mando batem exatamente.'),
  'hist-f80-0110': mk(49815, 'Olímpico', 'Goiânia', 'Ficha 49815 (rodada 21, 01/10/1950): "Goiás 2 x 0 Inhumas" — data, placar e mando batem exatamente.'),
  'hist-f80-0111': mk(49820, 'Olímpico', 'Goiânia', 'Ficha 49820 (rodada 23, 15/10/1950): "União 2 x 5 Goiás" — data e placar batem exatamente.'),
  'hist-f80-0112': mk(49824, 'Olímpico', 'Goiânia', 'Ficha 49824 (rodada 24, 22/10/1950): "Goiás 5 x 1 Flamengo" — data, placar e mando batem exatamente.'),
  'hist-f80-0113': mk(49828, 'Olímpico', 'Goiânia', 'Ficha 49828 (rodada 26, 01/11/1950): "Goiás 0 x 2 Goiânia" — data, placar e mando batem exatamente.'),
  'hist-f80-0161': mk(47542, 'Olímpico', 'Goiânia', 'Ficha 47542 (Citadino 1952, rodada 24, 30/11/1952): "Goiás 1 x 3 Goiânia" — data, placar e mando batem exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1368.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
