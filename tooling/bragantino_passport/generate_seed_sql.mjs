// Gera a SQL de seed de um lote a partir do JSON fonte já validado — nunca
// refaz pesquisa, só serializa pro schema `passport_matches` que JÁ EXISTE no
// projeto Supabase do Bragantino (verificado ao vivo; ver
// supabase/bragantino_passport_infra.sql). Uso: node generate_seed_sql.mjs 2026
//
// `venue_city`/`venue_state`/`venue_country` NÃO vão pra cá: a localização do
// estádio mora em `venues`, que é de onde a RPC lê `venue_city`. Duplicar
// aqui criaria duas versões do mesmo fato, que uma hora divergem.
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

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

// Liga cada partida ao estádio normalizado usando exatamente a mesma
// normalização do catálogo — sem isso o seed e o `venues` divergiriam.
const { buildVenues } = await import(
  pathToFileURL(path.join(__dirname, 'build_venues.mjs')).href
);
const venueByRawStadium = new Map();
for (const venue of buildVenues(rows).venues) {
  for (const raw of [venue.canonical_name, ...venue.aliases]) {
    venueByRawStadium.set(raw, venue.id);
  }
}
function venueIdFor(m) {
  if (!m.stadium) return null;
  const id = venueByRawStadium.get(m.stadium.trim());
  if (!id) throw new Error(`estádio sem venue no catálogo: ${m.stadium}`);
  return id;
}

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
// Instante absoluto do apito inicial. A fonte dá hora LOCAL de Brasília, então
// converto explicitamente — nada de assumir que o banco está em UTC-3. Sem
// horário conhecido não há instante: fica null, não meia-noite.
function sqlKickoff(m) {
  if (!m.time) return 'null';
  return `(timestamp '${m.date} ${m.time}:00' at time zone 'America/Sao_Paulo')`;
}

const cols = [
  'id', 'season', 'match_date', 'match_time', 'status', 'competition',
  'competition_code', 'competition_edition', 'round', 'phase_status',
  'opponent', 'club_is_home', 'neutral_site', 'home_team', 'away_team',
  'home_score', 'away_score', 'club_score', 'opponent_score',
  'score_display', 'outcome', 'stadium', 'stadium_status', 'venue_id',
  'weekday', 'day_type', 'day_period', 'kickoff_at', 'display_timezone',
  'date_precision', 'source_provider', 'source_match_id', 'source_url',
  'source_confidence', 'data_notes',
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
    sqlStr(m.stadium_status === 'NEEDS_SOURCE' ? 'UNKNOWN' : m.stadium_status),
    sqlStr(venueIdFor(m)), sqlStr(m.weekday), sqlStr(m.day_type),
    sqlStr(m.day_period), sqlKickoff(m), sqlStr('America/Sao_Paulo'),
    sqlStr(m.time ? 'datetime' : 'date_only'), sqlStr(m.source_provider),
    sqlStr(m.source_match_id), sqlStr(m.source_url),
    sqlStr(m.source_confidence), sqlStr(m.data_notes),
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
-- Rode no projeto Supabase do BRAGANTINO — NÃO no do Goiás — nesta ordem:
--   1. bragantino_passport_infra.sql       (colunas de enriquecimento)
--   2. bragantino_passport_venues_seed.sql (catálogo de estádios)
--   3. este arquivo
-- Idempotente (ON CONFLICT DO UPDATE): reexecutar atualiza, nunca duplica, e
-- não encosta em presença de usuário.

insert into public.passport_matches (
  ${cols.join(', ')}
) values
`;

sql += rows.map((m) => `  (${rowValues(m)})`).join(',\n');
sql += `\non conflict (id) do update set\n    ${updateSet};\n`;

// Falha alto se alguma partida com estádio ficou sem catálogo: melhor a
// importação parar do que o app mostrar partida sem estádio em silêncio.
sql += `
do $$
declare v_orphans int;
begin
  select count(*) into v_orphans from public.passport_matches
   where season = ${Number(year)} and stadium is not null and venue_id is null;
  if v_orphans > 0 then
    raise exception 'ha % partidas de ${year} com estadio sem venue_id -- rode bragantino_passport_venues_seed.sql', v_orphans;
  end if;
end $$;
`;

fs.writeFileSync(sqlPath, sql);
console.log(`Gerado: ${rows.length} linhas em ${sqlPath}`);
