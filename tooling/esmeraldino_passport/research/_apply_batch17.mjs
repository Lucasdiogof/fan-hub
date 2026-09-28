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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1400.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
function mk(venue, city, url, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz (confronto direto)', source_url_if_empty: url, conflict_note: note, notes_append: `Estádio confirmado via página de confronto direto do Futebol de Goyaz, 2026-09-28 (lote 17).` };
}
const CONF_306 = 'https://www.futeboldegoyaz.com.br/clubes/469/306/confronto';
const CONF_682 = 'https://www.futeboldegoyaz.com.br/clubes/469/682/confronto';
const CONF_685 = 'https://www.futeboldegoyaz.com.br/clubes/469/685/confronto';
const CONF_898 = 'https://www.futeboldegoyaz.com.br/clubes/469/898/confronto';
const CONF_209 = 'https://www.futeboldegoyaz.com.br/clubes/469/209/confronto';
const CONF_188 = 'https://www.futeboldegoyaz.com.br/clubes/469/188/confronto';

const updates = {
  // Náutico-PE (306)
  'hist-f80-1513': mk('Arruda', 'Recife', CONF_306, 'Confronto direto Goiás x Náutico: ficha 19/03/1983 (CSV 20/03, 1 dia de diferença), Náutico 4x0 Goiás, Série A — placar bate exatamente.'),
  // Uberlândia-MG (682)
  'hist-f80-0702': mk('Olímpico', 'Goiânia', CONF_682, 'Confronto direto Goiás x Uberlândia: 05/10/1969, Goiás 2x1 Uberlândia, Copa Brasil Central — data e placar batem exatamente.'),
  'hist-f80-0712': mk('Juca Ribeiro', 'Uberlândia', CONF_682, 'Confronto direto Goiás x Uberlândia: 30/11/1969, Uberlândia 1x1 Goiás, Copa Brasil Central — data e placar batem exatamente.'),
  'hist-f80-1323': mk('Juca Ribeiro', 'Uberlândia', CONF_682, 'Confronto direto Goiás x Uberlândia: 23/03/1980, Uberlândia 1x1 Goiás, Série B — data e placar batem exatamente.'),
  // Uberaba-MG (685)
  'hist-f80-0696': mk('Olímpico', 'Goiânia', CONF_685, 'Confronto direto Goiás x Uberaba: 03/09/1969, Goiás 2x2 Uberaba, Copa Brasil Central — data e placar batem exatamente.'),
  'hist-f80-0707': mk('Boulanger Pucci', 'Uberaba', CONF_685, 'Confronto direto Goiás x Uberaba: 12/11/1969, Uberaba 3x1 Goiás, Copa Brasil Central — data e placar batem exatamente.'),
  // Araxá-MG (898)
  'hist-f80-0700': mk('Olímpico', 'Goiânia', CONF_898, 'Confronto direto Goiás x Araxá: 24/09/1969, Goiás 2x1 Araxá, Copa Brasil Central — data e placar batem exatamente.'),
  'hist-f80-0706': mk('Majestoso', 'Araxá', CONF_898, 'Confronto direto Goiás x Araxá: 09/11/1969, Araxá 0x1 Goiás, Copa Brasil Central — data e placar batem exatamente.'),
  // América/SJRP-SP (209)
  'hist-f80-0698': mk('Mário Alves Mendonça', 'São José do Rio Preto', CONF_209, 'Confronto direto Goiás x América-SP: 13/09/1969, América 2x3 Goiás, Copa Brasil Central — data e placar batem exatamente.'),
  'hist-f80-0711': mk('Olímpico', 'Goiânia', CONF_209, 'Confronto direto Goiás x América-SP: 26/11/1969, Goiás 2x2 América, Copa Brasil Central — data e placar batem exatamente.'),
  // XV de Piracicaba-SP (188)
  'hist-f80-0699': mk('Barão de Serra Negra', 'Piracicaba', CONF_188, 'Confronto direto Goiás x XV de Piracicaba: 17/09/1969, XV 2x3 Goiás, Copa Brasil Central — data e placar batem exatamente.'),
  'hist-f80-0708': mk('Olímpico', 'Goiânia', CONF_188, 'Confronto direto Goiás x XV de Piracicaba: 16/11/1969, Goiás 0x0 XV, Copa Brasil Central — data e placar batem exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1412.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
