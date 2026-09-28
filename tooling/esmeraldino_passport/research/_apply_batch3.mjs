import fs from 'fs';

function parseCSV(text) {
  const rows = []; let i = 0; const len = text.length; let field = ''; let row = []; let inQuotes = false;
  while (i < len) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i += 2; continue; } inQuotes = false; i++; continue; }
      field += c; i++; continue;
    } else {
      if (c === '"') { inQuotes = true; i++; continue; }
      if (c === ',') { row.push(field); field = ''; i++; continue; }
      if (c === '\r') { i++; continue; }
      if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; i++; continue; }
      field += c; i++; continue;
    }
  }
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row); }
  return rows;
}
function csvField(v) { v = v == null ? '' : String(v); if (/[",\n]/.test(v)) return '"' + v.replace(/"/g, '""') + '"'; return v; }

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1248.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

const FDG = 'https://www.futeboldegoyaz.com.br/partidas/';
function mk(fichaId, note) {
  return {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url_if_empty: FDG + fichaId + '/partida',
    conflict_note: note,
    notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 3).`,
  };
}
function mkAccioly(fichaId, note) {
  const o = mk(fichaId, note);
  o.venue_name = 'Antônio Accioly';
  return o;
}

const updates = {
  // 1961 — Citadino de Goiânia, edição 599
  'hist-f80-0409': mk(49065, 'Ficha 49065 (rodada 5, sábado 02/09/1961): "Campineira 4 x 3 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0410': mk(49067, 'Ficha 49067 (rodada 6, sábado 09/09/1961): "Goiás 1 x 3 Ferroviário" — data, placar e mando batem exatamente.'),
  'hist-f80-0416': mk(49076, 'Ficha 49076 (rodada 11, domingo 19/11/1961): "Ferroviário 0 x 2 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0417': mk(49077, 'Ficha 49077 (rodada 12, sábado 02/12/1961): "Goiás 3 x 1 Campineira" — data, placar e mando batem exatamente.'),
  // 1963 — Campeonato Goiano, edição 323 (bloco set-nov/1963)
  'hist-f80-0453': mkAccioly(49505, 'Ficha 49505 (rodada 3, domingo 01/09/1963): "Goiás 3 x 1 São Luís" — data, placar e mando batem exatamente.'),
  'hist-f80-0454': mk(49507, 'Ficha 49507 (rodada 4, domingo 08/09/1963): "Goiás 2 x 0 Trindade EC" — data, placar e mando batem exatamente; "Trindade EC" = "Trindade-GO" no CSV.'),
  'hist-f80-0458': mk(49549, 'Ficha 49549 (rodada 11, domingo 27/10/1963): "Goiás 1 x 0 Botafogo de Buriti" — data e placar líquido batem exatamente; CSV marca goias_is_home=False mas a ficha registra Goiás como mandante. Divergência de mando, não de resultado/estádio.'),
  'hist-f80-0459': mk(49559, 'Ficha 49559 (rodada 13, sábado 09/11/1963): "Goiás 4 x 1 Sírio Libanês" — data, placar e mando batem exatamente.'),
  'hist-f80-0460': mk(49566, 'Ficha 49566 (rodada 14, quarta 13/11/1963): "Santa Rita 1 x 0 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0461': mk(49575, 'Ficha 49575 (rodada 17, sábado 23/11/1963): "Vila Coimbra 1 x 5 Goiás" — data, placar e mando batem exatamente.'),
};

let changed = 0, alreadyResolved = [];
for (const r of table.slice(1)) {
  const id = r[idx.id];
  const u = updates[id];
  if (!u) continue;
  if (r[idx.venue_name] !== 'UNKNOWN' && r[idx.venue_name] !== '') { alreadyResolved.push(id); continue; }
  r[idx.venue_name] = u.venue_name;
  r[idx.venue_city] = u.venue_city;
  r[idx.venue_state] = u.venue_state;
  r[idx.venue_confidence] = u.venue_confidence;
  r[idx.source_secondary] = u.source_secondary;
  if (!r[idx.source_url]) r[idx.source_url] = u.source_url_if_empty;
  r[idx.conflict_note] = u.conflict_note;
  const oldNotes = r[idx.notes];
  r[idx.notes] = oldNotes ? (oldNotes + ' ' + u.notes_append) : u.notes_append;
  changed++;
}

console.log('changed rows:', changed, 'already resolved (skipped, no double count):', alreadyResolved);

const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1258.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
