// Gera a SQL de seed de um lote a partir do JSON fonte já validado — nunca
// refaz pesquisa, só serializa pro schema `passport_matches` (ver
// supabase/bragantino_passport_matches.sql). Uso: node generate_seed_sql.mjs 2026
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const year = process.argv[2];
if (!year) {
  console.error('Uso: node generate_seed_sql.mjs <ano>');
  process.exit(1);
}

const jsonPath = path.join(ROOT, 'tooling/bragantino_passport/source', `bragantino_passport_${year}.json`);
const sqlPath = path.join(ROOT, 'supabase', `bragantino_passport_matches_${year}_seed.sql`);

const wrapper = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const rows = wrapper.matches;

function sqlStr(v) {
  return v === null || v === undefined ? 'null' : `'${String(v).replace(/'/g, "''")}'`;
}
function sqlInt(v) {
  return v === null || v === undefined ? 'null' : String(v);
}
function sqlBool(v) {
  return v === null || v === undefined ? 'null' : v ? 'true' : 'false';
}
function sqlDate(v) {
  return v === null || v === undefined ? 'null' : `'${v}'`;
}
function sqlTime(v) {
  return v === null || v === undefined ? 'null' : `'${v}:00'`;
}

const cols = [
  'id', 'season', 'match_date', 'match_time', 'status', 'competition',
  'competition_code', 'competition_edition', 'round', 'phase_status',
  'opponent', 'club_is_home', 'neutral_site', 'home_team', 'away_team',
  'home_score', 'away_score', 'club_score', 'opponent_score',
  'score_display', 'outcome', 'stadium', 'stadium_status', 'venue_city',
  'venue_state', 'venue_country', 'weekday', 'day_type', 'day_period',
  'source_provider', 'source_match_id', 'source_url', 'source_confidence',
  'data_notes',
];

function rowValues(m) {
  const opponent = m.club_is_home ? m.away_team : m.home_team;
  return [
    sqlStr(m.id), sqlInt(m.calendar_year), sqlDate(m.date), sqlTime(m.time),
    sqlStr(m.score_status), sqlStr(m.competition), sqlStr(m.competition_code),
    sqlStr(m.competition_edition), sqlStr(m.round), sqlStr(m.phase_status),
    sqlStr(opponent), sqlBool(m.club_is_home), sqlBool(m.neutral_site ?? false),
    sqlStr(m.home_team), sqlStr(m.away_team), sqlInt(m.home_score),
    sqlInt(m.away_score), sqlInt(m.club_score), sqlInt(m.opponent_score),
    sqlStr(m.score_display), sqlStr(m.outcome), sqlStr(m.stadium),
    sqlStr(m.stadium_status), sqlStr(m.venue_city), sqlStr(m.venue_state),
    sqlStr(m.venue_country), sqlStr(m.weekday), sqlStr(m.day_type),
    sqlStr(m.day_period), sqlStr(m.source_provider), sqlStr(m.source_match_id),
    sqlStr(m.source_url), sqlStr(m.source_confidence), sqlStr(m.data_notes),
  ].join(', ');
}

const updateSet = cols
  .filter((c) => c !== 'id')
  .map((c) => `${c} = excluded.${c}`)
  .concat(['updated_at = now()'])
  .join(',\n    ');

let sql = `-- Lote gerado automaticamente a partir de tooling/bragantino_passport/
-- source/bragantino_passport_${year}.json (node generate_seed_sql.mjs ${year}) —
-- nunca edite este arquivo à mão, regenere a partir do JSON fonte.
--
-- Rode DEPOIS de bragantino_passport_matches.sql, no projeto Supabase do
-- BRAGANTINO — NÃO no do Goiás. Idempotente (ON CONFLICT DO UPDATE).

insert into public.passport_matches (
  ${cols.join(', ')}
) values
`;

sql += rows.map((m) => `  (${rowValues(m)})`).join(',\n');
sql += `\non conflict (id) do update set\n    ${updateSet};\n`;

fs.writeFileSync(sqlPath, sql);
console.log(`Gerado: ${rows.length} linhas em ${sqlPath}`);
