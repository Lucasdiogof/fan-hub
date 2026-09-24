import fs from 'fs';
import { parseOgolTeamMatches } from './parse_ogol_matches.mjs';

const files = {
  'Brasileirao2021raw': 'source/ogol_2021_brasileirao_raw.html',
  'Brasileirao2020ed': 'source/ogol_2021_brasileirao2020ed.html',
  'Sudamericana': 'source/ogol_2021_sudamericana.html',
  'CopadoBrasil': 'source/ogol_2021_copadobrasil.html',
  'Paulista': 'source/ogol_2021_paulista.html',
};

const all = [];
for (const [label, f] of Object.entries(files)) {
  const html = fs.readFileSync(f, 'utf8');
  const matches = parseOgolTeamMatches(html, { teamSlug: 'red-bull-bragantino' });
  for (const m of matches) all.push({ ...m, competition_group: label });
}

// So o que aconteceu em 2021 entra neste lote (calendar_year=2021, mesmo
// pra jogos da edicao "Brasileirao 2020" que sobraram pra jan/fev/2021 -
// mesma regra do audit_manifest_v4).
const in2021 = all.filter((m) => m.date.startsWith('2021'));

const byId = new Map();
for (const m of in2021) {
  if (byId.has(m.source_match_id)) console.error('DUPLICATE', m.source_match_id, m.date, m.opponent);
  byId.set(m.source_match_id, m);
}

const list = [...byId.values()].sort((a, b) => a.date.localeCompare(b.date));
fs.writeFileSync('source/bragantino_2021_master_raw.json', JSON.stringify(list, null, 2));
console.log('total unique matches:', list.length);
const byComp = {};
for (const m of list) byComp[m.competition_display] = (byComp[m.competition_display] || 0) + 1;
console.log(byComp);
console.log(JSON.stringify(list.map((m) => m.source_url)));
