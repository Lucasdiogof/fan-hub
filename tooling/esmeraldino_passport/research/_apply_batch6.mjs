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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1284.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
function mk(venue, city, url, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz (confronto direto)', source_url_if_empty: url, conflict_note: note, notes_append: `Estádio confirmado via página de confronto direto do Futebol de Goyaz, 2026-09-28 (lote 6).` };
}
const CONF_654 = 'https://www.futeboldegoyaz.com.br/clubes/469/654/confronto';
const CONF_169 = 'https://www.futeboldegoyaz.com.br/clubes/469/169/confronto';
const CONF_624 = 'https://www.futeboldegoyaz.com.br/clubes/469/624/confronto';
const CONF_173 = 'https://www.futeboldegoyaz.com.br/clubes/469/173/confronto';

const updates = {
  // Botafogo-RJ (654)
  'hist-f80-1172': mk('Maracanã', 'Rio de Janeiro', CONF_654, 'Confronto direto Goiás x Botafogo-RJ: 23/10/1977, Botafogo 3x1 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1626': mk('São Januário', 'Rio de Janeiro', CONF_654, 'Confronto direto Goiás x Botafogo-RJ: 27/01/1985, Botafogo 3x1 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1636': mk('Serra Dourada', 'Goiânia', CONF_654, 'Confronto direto Goiás x Botafogo-RJ: 09/03/1985, Goiás 4x1 Botafogo, Série A — data e placar batem exatamente.'),
  'hist-f80-1773': mk('Maracanã', 'Rio de Janeiro', CONF_654, 'Confronto direto Goiás x Botafogo-RJ: 12/09/1987, Botafogo 1x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1843': mk('Serra Dourada', 'Goiânia', CONF_654, 'Confronto direto Goiás x Botafogo-RJ: 15/10/1988, Goiás 2x1 Botafogo, Série A — data e placar batem exatamente.'),
  // São Paulo-SP (169)
  'hist-f80-1580': mk('Morumbi', 'São Paulo', CONF_169, 'Confronto direto Goiás x São Paulo: 22/03/1984, São Paulo 3x2 Goiás, Série A — data e placar batem exatamente.'),
  // Vitória-BA (624)
  'hist-f80-0928': mk('Fonte Nova', 'Salvador', CONF_624, 'Confronto direto Goiás x Vitória-BA: 20/10/1973, Vitória 3x3 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-0950': mk('Olímpico', 'Goiânia', CONF_624, 'Confronto direto Goiás x Vitória-BA: 03/02/1974, Goiás 1x2 Vitória, Série A — data e placar batem exatamente.'),
  'hist-f80-1046': mk('Serra Dourada', 'Goiânia', CONF_624, 'Confronto direto Goiás x Vitória-BA: 18/09/1975, Goiás 1x0 Vitória, Série A — data e placar batem exatamente.'),
  'hist-f80-1300': mk('Serra Dourada', 'Goiânia', CONF_624, 'Confronto direto Goiás x Vitória-BA: ficha 04/11/1979 (CSV 03/11, 1 dia de diferença), Goiás 1x0 Vitória, Série A — placar bate exatamente.'),
  'hist-f80-1733': mk('Fonte Nova', 'Salvador', CONF_624, 'Confronto direto Goiás x Vitória-BA: ficha 25/10/1986 (CSV 29/10, 4 dias de diferença), Vitória 2x1 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-1744': mk('Serra Dourada', 'Goiânia', CONF_624, 'Confronto direto Goiás x Vitória-BA: 07/12/1986, Goiás 2x1 Vitória, Série A — data e placar batem exatamente.'),
  'hist-f80-1848': mk('Serra Dourada', 'Goiânia', CONF_624, 'Confronto direto Goiás x Vitória-BA: 13/11/1988, Goiás 6x1 Vitória, Série A — data e placar batem exatamente.'),
  'hist-f80-2185': mk('Fonte Nova', 'Salvador', CONF_624, 'Confronto direto Goiás x Vitória-BA: 07/10/1993, Vitória 3x1 Goiás, Série A — data e placar batem exatamente.'),
  // Corinthians-SP (173)
  'hist-f80-1198': mk('Serra Dourada', 'Goiânia', CONF_173, 'Confronto direto Goiás x Corinthians: 02/04/1978, Goiás 0x0 Corinthians, Série A — data e placar batem exatamente.'),
  'hist-f80-1518': mk('Canindé', 'São Paulo', CONF_173, 'Confronto direto Goiás x Corinthians: ficha 13/04/1983 (CSV 14/04, 1 dia de diferença), Corinthians 1x1 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-1521': mk('Serra Dourada', 'Goiânia', CONF_173, 'Confronto direto Goiás x Corinthians: ficha 23/04/1983 (CSV 24/04, 1 dia de diferença), Goiás 2x1 Corinthians, Série A — placar bate exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1301.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
