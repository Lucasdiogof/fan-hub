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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1306.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
function mk(venue, city, url, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz (confronto direto)', source_url_if_empty: url, conflict_note: note, notes_append: `Estádio confirmado via página de confronto direto do Futebol de Goyaz, 2026-09-28 (lote 8).` };
}
const CONF_180 = 'https://www.futeboldegoyaz.com.br/clubes/469/180/confronto';
const CONF_310 = 'https://www.futeboldegoyaz.com.br/clubes/469/310/confronto';
const CONF_593 = 'https://www.futeboldegoyaz.com.br/clubes/469/593/confronto';
const CONF_200 = 'https://www.futeboldegoyaz.com.br/clubes/469/200/confronto';
const CONF_645 = 'https://www.futeboldegoyaz.com.br/clubes/469/645/confronto';

const updates = {
  // Palmeiras-SP (180)
  'hist-f80-1504': mk('Morumbi', 'São Paulo', CONF_180, 'Confronto direto Goiás x Palmeiras: ficha 02/02/1983 (CSV 03/02, 1 dia de diferença), Palmeiras 1x0 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-1507': mk('Serra Dourada', 'Goiânia', CONF_180, 'Confronto direto Goiás x Palmeiras: ficha 19/02/1983 (CSV 20/02, 1 dia de diferença), Goiás 0x2 Palmeiras, Série A — placar bate exatamente.'),
  // Vasco da Gama-RJ — via goiasec.com.br (site oficial do clube), não a ficha da FdG
  'hist-f80-1101': { venue_name: 'São Januário', venue_city: 'Rio de Janeiro', venue_confidence: 'HIGH', source_secondary: 'Goiás Esporte Clube (site oficial)', source_url_if_empty: 'https://www.goiasec.com.br/noticias/goias-e-vasco-se-enfrentam-desde-1973', conflict_note: 'Site oficial do Goiás confirma: 04/09/1976, Vasco 1x0 Goiás, São Januário, gol de Roberto Dinamite — data e placar batem exatamente com o CSV.', notes_append: 'Estádio confirmado via site oficial do Goiás EC, 2026-09-28 (lote 8).' },
  // Santa Cruz-PE (310)
  'hist-f80-0926': mk('Olímpico', 'Goiânia', CONF_310, 'Confronto direto Goiás x Santa Cruz: 14/10/1973, Goiás 5x1 Santa Cruz, Série A — data e placar batem exatamente.'),
  'hist-f80-0936': mk('Olímpico', 'Goiânia', CONF_310, 'Confronto direto Goiás x Santa Cruz: 14/11/1973, Goiás 0x0 Santa Cruz, Série A — data e placar batem exatamente.'),
  'hist-f80-0949': mk('Arruda', 'Recife', CONF_310, 'Confronto direto Goiás x Santa Cruz: 30/01/1974, Santa Cruz 1x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-0958': mk('Arruda', 'Recife', CONF_310, 'Confronto direto Goiás x Santa Cruz: ficha 21/03/1974 (CSV 20/03, 1 dia de diferença), Santa Cruz 2x1 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-1043': mk('Arruda', 'Recife', CONF_310, 'Confronto direto Goiás x Santa Cruz: 03/09/1975, Santa Cruz 2x2 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1215': mk('Arruda', 'Recife', CONF_310, 'Confronto direto Goiás x Santa Cruz: 20/06/1978, Santa Cruz 1x0 Goiás, Série A — data e placar batem exatamente.'),
  // Remo-PA (593)
  'hist-f80-1055': mk('Serra Dourada', 'Goiânia', CONF_593, 'Confronto direto Goiás x Remo: 19/10/1975, Goiás 1x0 Remo, Série A — data e placar batem exatamente.'),
  'hist-f80-1299': mk('Mangueirão', 'Belém', CONF_593, 'Confronto direto Goiás x Remo: ficha 31/10/1979 (CSV 30/10, 1 dia de diferença), Remo 1x0 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-2179': mk('Serra Dourada', 'Goiânia', CONF_593, 'Confronto direto Goiás x Remo: 15/09/1993, Goiás 1x2 Remo, Série A — data e placar batem exatamente.'),
  'hist-f80-2192': mk('Baenão', 'Belém', CONF_593, 'Confronto direto Goiás x Remo: ficha 21/10/1993 (CSV 20/10, 1 dia de diferença), Remo 4x0 Goiás, Série A — placar bate exatamente.'),
  // Portuguesa de Desportos-SP (200)
  'hist-f80-0959': mk('Olímpico', 'Goiânia', CONF_200, 'Confronto direto Goiás x Portuguesa: 23/03/1974, Goiás 0x0 Portuguesa, Série A — data e placar batem exatamente.'),
  'hist-f80-0975': mk('Olímpico', 'Goiânia', CONF_200, 'Confronto direto Goiás x Portuguesa: 30/06/1974, Goiás 0x1 Portuguesa, Série A — data e placar batem exatamente.'),
  'hist-f80-1051': mk('Parque Antárctica', 'São Paulo', CONF_200, 'Confronto direto Goiás x Portuguesa: 05/10/1975, Portuguesa 0x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1849': mk('Canindé', 'São Paulo', CONF_200, 'Confronto direto Goiás x Portuguesa: 17/11/1988, Portuguesa 1x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1908': mk('Serra Dourada', 'Goiânia', CONF_200, 'Confronto direto Goiás x Portuguesa: 10/09/1989, Goiás 2x1 Portuguesa, Série A — data e placar batem exatamente.'),
  'hist-f80-1997': mk('Canindé', 'São Paulo', CONF_200, 'Confronto direto Goiás x Portuguesa: 18/11/1990, Portuguesa 2x0 Goiás, Série A — data e placar batem exatamente.'),
  // America-RJ (645)
  'hist-f80-1052': mk('Serra Dourada', 'Goiânia', CONF_645, 'Confronto direto Goiás x América-RJ: 08/10/1975, Goiás 2x0 América, Série A — data e placar batem exatamente.'),
  'hist-f80-1107': mk('Serra Dourada', 'Goiânia', CONF_645, 'Confronto direto Goiás x América-RJ: 26/09/1976, Goiás 1x0 América, Série A — data e placar batem exatamente.'),
  'hist-f80-1122': mk('Serra Dourada', 'Goiânia', CONF_645, 'Confronto direto Goiás x América-RJ: 04/12/1976, Goiás 0x2 América, Torneio Centro-Oeste — data e placar batem exatamente.'),
  'hist-f80-1629': mk('São Januário', 'Rio de Janeiro', CONF_645, 'Confronto direto Goiás x América-RJ: 07/02/1985, América 0x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1729': mk('Serra Dourada', 'Goiânia', CONF_645, 'Confronto direto Goiás x América-RJ: ficha 27/09/1986 (CSV 28/09, 1 dia de diferença), Goiás 3x2 América, Série A — placar bate exatamente.'),
  'hist-f80-1842': mk('Caio Martins', 'Niterói', CONF_645, 'Confronto direto Goiás x América-RJ: 08/10/1988, América 0(6)x(7)0 Goiás (pênaltis), Série A — data e placar batem exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1331.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
