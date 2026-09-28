import fs from 'fs';

function parseCSV(text) {
  const rows = [];
  let i = 0;
  const len = text.length;
  let field = '';
  let row = [];
  let inQuotes = false;
  while (i < len) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i++; continue;
      }
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

function csvField(v) {
  v = v == null ? '' : String(v);
  if (/[",\n]/.test(v)) return '"' + v.replace(/"/g, '""') + '"';
  return v;
}

const raw = fs.readFileSync('passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1223.csv', 'utf8').replace(/^﻿/, '');
const table = parseCSV(raw);
const header = table[0];
const idx = Object.fromEntries(header.map((h, i) => [h, i]));

const updates = {
  'hist-f80-0200': {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url: 'https://www.futeboldegoyaz.com.br/partidas/48709/partida',
    conflict_note: 'Ficha 48709 (Citadino 1954, 1a rodada, 27/06/1954, domingo) registra "Sirio Libanes 2 x 2 Goias" — mesma data e placar do CSV (Botafogo de Goiania-GO). Edicao 1954 (campeonatos/592) lista só 5 clubes (Goiânia, Atlético, Sírio Libanês, Goiás, União); não há Botafogo. Confirma-se o estádio pela coincidência exata de data+placar; o nome do adversário ficou registrado como possível alias, sem alterar o campo opponent.',
    notes_append: 'Estádio confirmado via Futebol de Goyaz (ficha 48709), 2026-09-28.'
  },
  'hist-f80-0204': {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url: 'https://www.futeboldegoyaz.com.br/partidas/48715/partida',
    conflict_note: 'Ficha 48715 (Citadino 1954, 7a rodada, 22/08/1954, domingo): "União 2 x 1 Goiás" — data, placar e mando batem exatamente com o CSV.',
    notes_append: 'Estádio confirmado via Futebol de Goyaz (ficha 48715), 2026-09-28.'
  },
  'hist-f80-0206': {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url: 'https://www.futeboldegoyaz.com.br/partidas/48718/partida',
    conflict_note: 'Ficha 48718 (Citadino 1954, 10a rodada): "Goiás 0 x 2 Goiânia", terça-feira 07/09/1954 — placar e adversário batem exatamente; data do CSV (08/09) diverge em 1 dia da ficha (07/09), divergência de fonte, mantida a data original do CSV.',
    notes_append: 'Estádio confirmado via Futebol de Goyaz (ficha 48718), 2026-09-28.'
  },
  'hist-f80-0207': {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url: 'https://www.futeboldegoyaz.com.br/partidas/48720/partida',
    conflict_note: 'Ficha 48720 (Citadino 1954, 13a rodada): "Goiás 3 x 2 União", domingo 31/10/1954 — placar, mando e adversário batem exatamente; data do CSV (17/10) diverge da ficha (31/10) em duas semanas. A ficha 48721 confirma que 17/10/1954 é outro jogo (Atlético x Sírio Libanês, WOx0), não este. Mantida a data original do CSV; estádio confirmado pelo cruzamento adversário+placar único na temporada.',
    notes_append: 'Estádio confirmado via Futebol de Goyaz (ficha 48720), 2026-09-28.'
  },
  'hist-f80-0211': {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url: 'https://www.futeboldegoyaz.com.br/partidas/48725/partida',
    conflict_note: 'Ficha 48725 (Citadino 1954, 16a rodada, 21/11/1954, domingo): "Goiânia 1 x 1 Goiás" — data, placar e mando batem exatamente com o CSV.',
    notes_append: 'Estádio confirmado via Futebol de Goyaz (ficha 48725), 2026-09-28.'
  },
  'hist-f80-0214': {
    venue_name: 'Olímpico', venue_city: 'Goiânia', venue_state: 'GO', venue_confidence: 'HIGH',
    source_secondary: 'Futebol de Goyaz',
    source_url: 'https://www.futeboldegoyaz.com.br/partidas/48727/partida',
    conflict_note: 'Ficha 48727 (Citadino 1954, 18a rodada, 05/12/1954, domingo): "Goiás 0 x 2 Sírio Libanês" — mesma data e placar do CSV (Botafogo de Goiânia-GO). Mesma situação de alias da ficha 48709 (edição 1954 não lista Botafogo entre os 5 clubes participantes).',
    notes_append: 'Estádio confirmado via Futebol de Goyaz (ficha 48727), 2026-09-28.'
  },
};

let changed = 0;
for (const r of table.slice(1)) {
  const id = r[idx.id];
  const u = updates[id];
  if (!u) continue;
  r[idx.venue_name] = u.venue_name;
  r[idx.venue_city] = u.venue_city;
  r[idx.venue_state] = u.venue_state;
  r[idx.venue_confidence] = u.venue_confidence;
  r[idx.source_secondary] = u.source_secondary;
  const oldUrl = r[idx.source_url];
  r[idx.source_url] = oldUrl ? oldUrl : u.source_url;
  // keep Futebol80 URL as primary source_url (already there), store FdG link if source_url empty
  if (!oldUrl) r[idx.source_url] = u.source_url;
  r[idx.conflict_note] = u.conflict_note;
  const oldNotes = r[idx.notes];
  r[idx.notes] = oldNotes ? (oldNotes + ' ' + u.notes_append) : u.notes_append;
  changed++;
}

console.log('changed rows:', changed);

const outLines = table.map(r => r.map(csvField).join(',')).join('\r\n');
fs.writeFileSync('passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1229.csv', '﻿' + outLines + '\r\n', 'utf8');
console.log('wrote CHECKPOINT_1229.csv');
