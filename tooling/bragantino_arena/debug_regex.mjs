import { readFileSync } from 'node:fs';
const sql = readFileSync('../../supabase/bragantino_guess_players.sql', 'utf8');
const clubId = '51683d2a-ea1d-57c6-8014-996146f242e7';
const re = new RegExp(
  `\\('(braga_manto_\\d+)', '${clubId}', '[^']*', '[^']*', '\\[[^\\]]*\\]'::jsonb, ` +
  `(?:'[a-z]+'|null), (\\d+), ('[^']*'|null), (\\d+|null), '([a-z_-]+)', '(verified|incomplete)', \\d+\\)`,
  'g',
);
let m, count = 0;
while ((m = re.exec(sql))) { count++; console.log(m[1], m[2], m[3], m[4], m[5], m[6]); }
console.log('total:', count);
