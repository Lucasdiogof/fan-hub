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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1335.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
function mk(venue, city, url, note) {
  return { venue_name: venue, venue_city: city, venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz (confronto direto)', source_url_if_empty: url, conflict_note: note, notes_append: `Estádio confirmado via página de confronto direto do Futebol de Goyaz, 2026-09-28 (lote 9).` };
}
const CONF_725 = 'https://www.futeboldegoyaz.com.br/clubes/469/725/confronto';
const CONF_322 = 'https://www.futeboldegoyaz.com.br/clubes/469/322/confronto';
const CONF_709 = 'https://www.futeboldegoyaz.com.br/clubes/469/709/confronto';
const CONF_288 = 'https://www.futeboldegoyaz.com.br/clubes/469/288/confronto';
const CONF_577 = 'https://www.futeboldegoyaz.com.br/clubes/469/577/confronto';
const CONF_548 = 'https://www.futeboldegoyaz.com.br/clubes/469/548/confronto';

const updates = {
  // Rio Negro-AM (725)
  'hist-f80-0971': mk('Olímpico', 'Goiânia', CONF_725, 'Confronto direto Goiás x Rio Negro-AM: 29/05/1974, Goiás 2x0 Rio Negro, Série A — data e placar batem exatamente.'),
  'hist-f80-1512': mk('Serra Dourada', 'Goiânia', CONF_725, 'Confronto direto Goiás x Rio Negro-AM: 16/03/1983, Goiás 2x0 Rio Negro, Série A — data e placar batem exatamente.'),
  'hist-f80-1514': mk('Colina', 'Manaus', CONF_725, 'Confronto direto Goiás x Rio Negro-AM: ficha 26/03/1983 (CSV 27/03, 1 dia de diferença), Rio Negro 0x1 Goiás, Série A — placar bate exatamente.'),
  // América-RN (322)
  'hist-f80-0918': mk('Olímpico', 'Goiânia', CONF_322, 'Confronto direto Goiás x América-RN: 09/09/1973, Goiás 0x0 América, Série A — data e placar batem exatamente.'),
  'hist-f80-1044': mk('Machadão', 'Natal', CONF_322, 'Confronto direto Goiás x América-RN: 07/09/1975, América 3x3 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1115': mk('Serra Dourada', 'Goiânia', CONF_322, 'Confronto direto Goiás x América-RN: 20/10/1976, Goiás 0x0 América, Série A — data e placar batem exatamente.'),
  // Mixto-MT (709)
  'hist-f80-1099': mk('Verdão', 'Cuiabá', CONF_709, 'Confronto direto Goiás x Mixto-MT: 29/08/1976, Mixto 1x1 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1204': mk('Serra Dourada', 'Goiânia', CONF_709, 'Confronto direto Goiás x Mixto-MT: 26/04/1978, Goiás 1x1 Mixto, Série A — data e placar batem exatamente.'),
  'hist-f80-1508': mk('Serra Dourada', 'Goiânia', CONF_709, 'Confronto direto Goiás x Mixto-MT: 27/02/1983, Goiás 3x1 Mixto, Série A — data e placar batem exatamente.'),
  // Grêmio-RS (288) — estádio histórico do Grêmio era chamado "Olímpico" (Estádio Olímpico Monumental, Porto Alegre), distinto do Olímpico do Goiás em Goiânia
  'hist-f80-0947': mk('Olímpico Monumental', 'Porto Alegre', CONF_288, 'Confronto direto Goiás x Grêmio: 23/01/1974, Grêmio 1x0 Goiás, Série A — data e placar batem exatamente. Estádio histórico do Grêmio (pré-Arena) chamado "Olímpico" na ficha; usado "Olímpico Monumental" pra não confundir com o Olímpico de Goiânia.'),
  'hist-f80-1049': mk('Olímpico Monumental', 'Porto Alegre', CONF_288, 'Confronto direto Goiás x Grêmio: 28/09/1975, Grêmio 0x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1213': mk('Olímpico Monumental', 'Porto Alegre', CONF_288, 'Confronto direto Goiás x Grêmio: ficha 10/06/1978 (CSV 11/06, 1 dia de diferença), Grêmio 4x1 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-1583': mk('Serra Dourada', 'Goiânia', CONF_288, 'Confronto direto Goiás x Grêmio: 08/04/1984, Goiás 1x1 Grêmio, Série A — data e placar batem exatamente.'),
  // Botafogo-PB (577)
  'hist-f80-1217': mk('Almeidão', 'João Pessoa', CONF_577, 'Confronto direto Goiás x Botafogo-PB: 02/07/1978, Botafogo 0x1 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1302': mk('Serra Dourada', 'Goiânia', CONF_577, 'Confronto direto Goiás x Botafogo-PB: 11/11/1979, Goiás 3x1 Botafogo, Série A — data e placar batem exatamente.'),
  'hist-f80-1730': mk('Almeidão', 'João Pessoa', CONF_577, 'Confronto direto Goiás x Botafogo-PB: 01/10/1986, Botafogo 1x0 Goiás, Série A — data e placar batem exatamente.'),
  // Rio Branco-ES (548)
  'hist-f80-0607': mk('Governador Bley', 'Vitória', CONF_548, 'Confronto direto Goiás x Rio Branco-ES: 06/08/1967, Rio Branco 1x0 Goiás, Taça Brasil — data e placar batem exatamente.'),
  'hist-f80-0609': mk('Olímpico', 'Goiânia', CONF_548, 'Confronto direto Goiás x Rio Branco-ES: 16/08/1967, Goiás 0x0 Rio Branco, Taça Brasil — data e placar batem exatamente.'),
  'hist-f80-1576': mk('Serra Dourada', 'Goiânia', CONF_548, 'Confronto direto Goiás x Rio Branco-ES: 02/03/1984, Goiás 2x1 Rio Branco, Série A — data e placar batem exatamente.'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1354.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
