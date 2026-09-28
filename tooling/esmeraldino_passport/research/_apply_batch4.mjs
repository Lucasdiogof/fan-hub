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

const SRC = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1258.csv';
const raw = fs.readFileSync(SRC, 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));
const FDG = 'https://www.futeboldegoyaz.com.br/partidas/';
function mk(fichaId, note) {
  return { venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH', source_secondary: 'Futebol de Goyaz', source_url_if_empty: FDG + fichaId + '/partida', conflict_note: note, notes_append: `Estádio confirmado via Futebol de Goyaz (ficha ${fichaId}), 2026-09-28 (lote 4).` };
}

const updates = {
  'hist-f80-0502': mk(20524, 'Ficha 20524 (rodada 15, sábado 19/09/1964): "Campinas 0 x 1 Goiás" — placar líquido (1x0 pró-Goiás) e adversário batem; data da ficha (19/09) diverge 1 dia da do CSV (20/09).'),
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
console.log('changed rows:', changed, 'skipped:', alreadyResolved);
const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
const OUT = 'passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1259.csv';
fs.writeFileSync(OUT, '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote', OUT);
