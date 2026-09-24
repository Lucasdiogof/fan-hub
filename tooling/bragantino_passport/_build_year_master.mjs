import fs from 'fs';
import { parseOgolTeamMatches } from './parse_ogol_matches.mjs';

const year = process.argv[2];
const filesArg = process.argv.slice(3); // pairs: label file label file ...
const files = {};
for (let i = 0; i < filesArg.length; i += 2) files[filesArg[i]] = filesArg[i + 1];

const all = [];
for (const [label, f] of Object.entries(files)) {
  const html = fs.readFileSync(f, 'utf8');
  const matches = parseOgolTeamMatches(html, { teamSlug: 'red-bull-bragantino' });
  for (const m of matches) all.push({ ...m, competition_group: label });
}

const byId = new Map();
for (const m of all) {
  if (byId.has(m.source_match_id)) console.error('DUPLICATE', m.source_match_id, m.date, m.opponent);
  byId.set(m.source_match_id, m);
}

const list = [...byId.values()].sort((a, b) => a.date.localeCompare(b.date));
fs.writeFileSync(`source/bragantino_${year}_master_raw.json`, JSON.stringify(list, null, 2));
console.log('total unique matches:', list.length);
console.log(Object.fromEntries(Object.keys(files).map((label) => [label, list.filter((m) => m.competition_group === label).length])));
console.log(JSON.stringify(list.map((m) => m.source_url)));
