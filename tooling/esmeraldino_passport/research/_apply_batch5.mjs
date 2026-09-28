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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1259.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
function mk(venue, city, url, note) {
  return { venue_name: venue, venue_city: city, venue_state: '', venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz (confronto direto)', source_url_if_empty: url, conflict_note: note, notes_append: `Estádio confirmado via página de confronto direto do Futebol de Goyaz, 2026-09-28 (lote 5).` };
}
const CONF_469_618 = 'https://www.futeboldegoyaz.com.br/clubes/469/618/confronto';
const CONF_469_289 = 'https://www.futeboldegoyaz.com.br/clubes/469/289/confronto';
const CONF_469_630 = 'https://www.futeboldegoyaz.com.br/clubes/469/630/confronto';
const CONF_469_174 = 'https://www.futeboldegoyaz.com.br/clubes/469/174/confronto';
const CONF_469_628 = 'https://www.futeboldegoyaz.com.br/clubes/469/628/confronto';
const CONF_469_674 = 'https://www.futeboldegoyaz.com.br/clubes/469/674/confronto';

const updates = {
  // Bahia-BA (clube 618)
  'hist-f80-1209': mk('Serra Dourada', 'Goiânia', CONF_469_618, 'Confronto direto Goiás x Bahia: 21/05/1978, Goiás 3x0 Bahia, Série A — data e placar batem exatamente.'),
  'hist-f80-1297': mk('Fonte Nova', 'Salvador', CONF_469_618, 'Confronto direto Goiás x Bahia: 17/10/1979, Bahia 1x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1506': mk('Serra Dourada', 'Goiânia', CONF_469_618, 'Confronto direto Goiás x Bahia: 13/02/1983, Goiás 1x1 Bahia, Série A — data e placar batem exatamente.'),
  'hist-f80-1509': mk('Fonte Nova', 'Salvador', CONF_469_618, 'Confronto direto Goiás x Bahia: 06/03/1983, Bahia 3x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1777': mk('Fonte Nova', 'Salvador', CONF_469_618, 'Confronto direto Goiás x Bahia: 04/10/1987, Bahia 1x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1996': mk('Serra Dourada', 'Goiânia', CONF_469_618, 'Confronto direto Goiás x Bahia: 14/11/1990, Goiás 0x0 Bahia, Série A — data e placar batem exatamente.'),
  // Internacional-RS (clube 289)
  'hist-f80-1220': mk('Serra Dourada', 'Goiânia', CONF_469_289, 'Confronto direto Goiás x Internacional: ficha data 13/07/1978 (CSV 12/07, 1 dia de diferença), Goiás 0x1 Internacional, Série A — placar bate exatamente.'),
  'hist-f80-1784': mk('Beira Rio', 'Porto Alegre', CONF_469_289, 'Confronto direto Goiás x Internacional: ficha data 08/11/1987 (CSV 07/11, 1 dia de diferença), Internacional 0x0 Goiás, Série A — placar bate exatamente.'),
  // Coritiba-PR (clube 630)
  'hist-f80-1061': mk('Serra Dourada', 'Goiânia', CONF_469_630, 'Confronto direto Goiás x Coritiba: 09/11/1975, Goiás 2x2 Coritiba, Série A — data e placar batem exatamente.'),
  'hist-f80-1838': mk('Couto Pereira', 'Curitiba', CONF_469_630, 'Confronto direto Goiás x Coritiba: 11/09/1988, Coritiba 0(5)x(4)0 Goiás (pênaltis), Série A — data e placar batem exatamente.'),
  'hist-f80-1911': mk('Serra Dourada', 'Goiânia', CONF_469_630, 'Confronto direto Goiás x Coritiba: 01/10/1989, Goiás 2x3 Coritiba, Série A — data e placar batem exatamente.'),
  'hist-f80-2261': mk('Serra Dourada', 'Goiânia', CONF_469_630, 'Confronto direto Goiás x Coritiba: 03/11/1994, Goiás 2x0 Coritiba, Série B — data e placar batem exatamente.'),
  // Guarani-SP (clube 174)
  'hist-f80-0960': mk('Brinco de Ouro', 'Campinas', CONF_469_174, 'Confronto direto Goiás x Guarani: 30/03/1974, Guarani 3x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1058': mk('Brinco de Ouro', 'Campinas', CONF_469_174, 'Confronto direto Goiás x Guarani: 29/10/1975, Guarani 0x0 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1519': mk('Serra Dourada', 'Goiânia', CONF_469_174, 'Confronto direto Goiás x Guarani: ficha 16/04/1983 (CSV 17/04, 1 dia de diferença), Goiás 1x1 Guarani, Série A — placar bate exatamente.'),
  'hist-f80-1522': mk('Brinco de Ouro', 'Campinas', CONF_469_174, 'Confronto direto Goiás x Guarani: ficha 30/04/1983 (CSV 01/05, 1 dia de diferença), Guarani 1x2 Goiás, Série A — placar bate exatamente.'),
  'hist-f80-1632': mk('Serra Dourada', 'Goiânia', CONF_469_174, 'Confronto direto Goiás x Guarani: ficha 24/02/1985 (CSV 23/02, 1 dia de diferença), Goiás 1x1 Guarani, Série A — placar bate exatamente.'),
  // Atlético-PR (clube 628)
  'hist-f80-0979': mk('Olímpico', 'Goiânia', CONF_469_628, 'Confronto direto Goiás x Atlético-PR: 17/07/1974, Goiás 1x2 Atlético-PR, Série A — data e placar batem exatamente.'),
  'hist-f80-1182': mk('Couto Pereira', 'Curitiba', CONF_469_628, 'Confronto direto Goiás x Atlético-PR: 01/12/1977, Atlético-PR 3x3 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1584': mk('Serra Dourada', 'Goiânia', CONF_469_628, 'Confronto direto Goiás x Atlético-PR: 11/04/1984, Goiás 0x0 Atlético-PR, Série A — data e placar batem exatamente.'),
  'hist-f80-1586': mk('Couto Pereira', 'Curitiba', CONF_469_628, 'Confronto direto Goiás x Atlético-PR: 19/04/1984, Atlético-PR 2x1 Goiás, Série A — data e placar batem exatamente.'),
  'hist-f80-1726': mk('Serra Dourada', 'Goiânia', CONF_469_628, 'Confronto direto Goiás x Atlético-PR: 14/09/1986, Goiás 0x0 Atlético-PR, Série A — data e placar batem exatamente.'),
  // Cruzeiro-MG (clube 674)
  'hist-f80-1294': mk('Serra Dourada', 'Goiânia', CONF_469_674, 'Confronto direto Goiás x Cruzeiro: 04/10/1979, Goiás 3x1 Cruzeiro, Série A — data e placar batem exatamente.'),
  'hist-f80-1310': mk('Serra Dourada', 'Goiânia', CONF_469_674, 'Confronto direto Goiás x Cruzeiro: ficha 08/12/1979 (CSV 09/12, 1 dia de diferença), Goiás 1x1 Cruzeiro, Série A — placar bate exatamente.'),
  'hist-f80-1786': mk('Mineirão', 'Belo Horizonte', CONF_469_674, 'Confronto direto Goiás x Cruzeiro: ficha 18/11/1987 (CSV 15/11, 3 dias de diferença), Cruzeiro 1x0 Goiás, Série A — placar bate exatamente.'),
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
console.log('changed rows:', changed, 'skipped(already resolved):', alreadyResolved, 'NOT FOUND (check id):', notFound);
const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1284.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
