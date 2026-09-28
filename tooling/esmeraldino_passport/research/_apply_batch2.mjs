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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1229.csv';
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
    notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 2).`,
  };
}

const updates = {
  // 1958 — Citadino 1958 (edição 596), games 48942-48990
  'hist-f80-0319': mk(48953, 'Ficha 48953 (rodada 4, sábado 16/08/1958): "Sírio Libanês 3 x 2 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0321': mk(48958, 'Ficha 48958 (rodada 6, domingo 31/08/1958): "Goianás 0 x 3 Goiás" — placar líquido (3x0 pró-Goiás) e data batem; CSV marca goias_is_home=True mas a ficha registra Goiás como visitante. Divergência de mando, não de resultado/estádio.'),
  'hist-f80-0324': mk(48967, 'Ficha 48967 (rodada 11, sábado 04/10/1958): "Ferroviário 3 x 1 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0325': mk(48972, 'Ficha 48972 (rodada 14, sábado 01/11/1958): "Goiás 2 x 0 Campineira" — data, placar e mando batem exatamente.'),
  'hist-f80-0328': mk(48986, 'Ficha 48986 (rodada 18, sábado 06/12/1958): "Goiás 3 x 1 Ferroviário" — data, placar e mando batem exatamente.'),
  'hist-f80-0329': mk(48990, 'Ficha 48990 (rodada 19, domingo 14/12/1958): "Goiás 0 x 2 Sírio Libanês" — data, placar e mando batem exatamente.'),
  // 1959 — parte final da edição 1958 (jan/1959) + nova edição 1959 (a partir de mai/1959)
  'hist-f80-0330': mk(48994, 'Ficha 48994 (rodada 22, quinta 01/01/1959): "Campineira 4 x 1 Goiás" — data, placar e mando batem exatamente (continuação da edição 1958 até jan/1959).'),
  'hist-f80-0331': mk(48997, 'Ficha 48997 (rodada 23, terça 06/01/1959): "Goiás 1 x 3 Goianás" — data, placar e mando batem exatamente.'),
  'hist-f80-0345': mk(49005, 'Ficha 49005 (Primeira fase, rodada 2, sábado 30/05/1959): "Goiás 4 x 0 América" — data, placar e mando batem; "América" = "América de Morrinhos-GO" no CSV.'),
  'hist-f80-0347': mk(49009, 'Ficha 49009 (Primeira fase, rodada 4, sábado 13/06/1959): "Goiás 7 x 1 Sírio Libanês" — data, placar e mando batem exatamente.'),
  'hist-f80-0349': mk(49013, 'Ficha 49013 (Primeira fase, rodada 5, domingo 21/06/1959): "Goianás 1 x 1 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0357': mk(49031, 'Ficha 49031 (Primeira fase, rodada 14, quinta 03/09/1959): "Goiás 3 x 2 Santa Rita" — data, placar e mando batem exatamente.'),
  'hist-f80-0358': mk(49037, 'Ficha 49037 (Primeira fase, rodada 16, domingo 20/09/1959): "Goiás 2 x 1 Campineira" — data, placar e mando batem exatamente.'),
  'hist-f80-0360': mk(49041, 'Ficha 49041 (Primeira fase, rodada 18, domingo 04/10/1959): "Ferroviário 1 x 2 Goiás" — data, placar e mando batem exatamente.'),
  // 1960 — edição 598
  'hist-f80-0369': mk(49051, 'Ficha 49051 (Fase final, rodada 2, domingo 13/03/1960): "Goiás 1 x 3 Campineira" — data, placar e mando batem exatamente.'),
  'hist-f80-0379': mk(49464, 'Ficha 49464 (rodada 1, quarta 22/06/1960): "Goiás 1 x 0 Ferroviário" — data, placar e mando batem exatamente.'),
  'hist-f80-0387': mk(49477, 'Ficha 49477 (rodada 10, domingo 14/08/1960): "Goiás 2 x 0 Campineira" — data, placar e mando batem exatamente.'),
  'hist-f80-0388': mk(49478, 'Ficha 49478 (rodada 11, domingo 18/09/1960): "Ferroviário 1 x 2 Goiás" — data, placar e mando batem exatamente.'),
  'hist-f80-0392': mk(49491, 'Ficha 49491 (rodada 19, final da tabela, sábado 03/12/1960): "Goiás 2 x 0 Campineira" — data, placar e mando batem exatamente; encontrada direto na página da edição (campeonatos/598/edicao).'),
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
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1248.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
