// Gera os seeds SQL do Passaporte do Vila Nova a partir do pacote de pesquisa
// JÁ auditado (`docs/vila_nova_data/passport/`). Nunca refaz pesquisa: só
// serializa pro schema `passport_matches`/`venues` do canonical baseline +
// as colunas de enriquecimento de `supabase/vilanova_passport_infra.sql`
// (as mesmas do Bragantino).
//
//   node tooling/vilanova_passport/generate_passport_sql.mjs
//
// Saída:
//   supabase/vilanova_passport_venues_seed.sql
//   supabase/vilanova_passport_matches_<ano>_seed.sql (um por ano do pacote)
//
// Diferenças em relação ao pipeline do Bragantino (mesmo contrato de banco):
//   * o catálogo de estádios já vem pronto no pacote (`venues.json`), então
//     aqui não há normalização: só ligação partida -> venue;
//   * ligação por nome é ambígua em alguns casos ("Castelão" é Fortaleza E São
//     Luís), então: nome oficial primeiro; nome de exibição/alias só se único;
//     empate desfeito pela cidade da partida; ainda ambíguo -> ERRO;
//   * weekday/day_type/day_period/phase_status não vêm no pacote e são
//     derivados de data/hora/rodada com as MESMAS regras do Bragantino;
//   * disputa de pênaltis (sem coluna no schema) vai pra `data_notes`, pra
//     não se perder — `outcome` continua sendo o do tempo normal.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const PKG = path.join(ROOT, 'docs/vila_nova_data/passport');
const OUT = path.join(ROOT, 'supabase');
const PROJECT_WARNING =
  'Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do Bragantino.';

// Toda SQL gerada começa provando que o banco é o do Vila (passport_matches e
// venues não têm club_id, então a linha de `clubs` é a única prova).
const GUARD = `do $$
begin
  if not exists (select 1 from public.clubs where slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;
`;

const venues = JSON.parse(fs.readFileSync(path.join(PKG, 'venues.json'), 'utf8')).venues;

// ---------------------------------------------------------------- ligação
const byCanonical = new Map();
const byOtherName = new Map();
for (const v of venues) {
  if (byCanonical.has(v.canonical_name)) {
    throw new Error(`canonical_name duplicado no catálogo: ${v.canonical_name}`);
  }
  byCanonical.set(v.canonical_name, v);
  for (const n of [v.display_name, ...(v.aliases ?? [])]) {
    if (!byOtherName.has(n)) byOtherName.set(n, []);
    byOtherName.get(n).push(v);
  }
}

export function venueFor(m) {
  if (!m.stadium) return null;
  const name = m.stadium.trim();
  if (byCanonical.has(name)) return byCanonical.get(name);
  let candidates = byOtherName.get(name) ?? [];
  if (candidates.length > 1) {
    candidates = candidates.filter((v) => v.city === m.venue_city);
  }
  if (candidates.length !== 1) {
    throw new Error(
      `estádio "${name}" (${m.venue_city}) em ${m.id}: ${candidates.length} venues possíveis`,
    );
  }
  return candidates[0];
}

// ----------------------------------------------------------- serialização
const sqlStr = (v) => (v === null || v === undefined ? 'null' : `'${String(v).replace(/'/g, "''")}'`);
const sqlInt = (v) => (v === null || v === undefined ? 'null' : String(Number(v)));
const sqlBool = (v) => (v === null || v === undefined ? 'null' : v ? 'true' : 'false');
const sqlDate = (v) => (v ? `'${v}'` : 'null');
const sqlTime = (v) => (v ? `'${v}:00'` : 'null');
const sqlTextArray = (arr) =>
  arr && arr.length ? `array[${arr.map(sqlStr).join(', ')}]` : `'{}'::text[]`;
// Hora da fonte é LOCAL de Brasília: converte explicitamente pro instante.
const sqlKickoff = (m) =>
  m.time ? `(timestamp '${m.date} ${m.time}:00' at time zone 'America/Sao_Paulo')` : 'null';

const WEEKDAYS = ['domingo', 'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado'];
function dayFields(m) {
  const d = new Date(`${m.date}T12:00:00Z`);
  const wd = d.getUTCDay();
  let period = 'UNKNOWN';
  if (m.time) {
    const h = Number(m.time.split(':')[0]);
    period = h < 12 ? 'MORNING' : h < 18 ? 'AFTERNOON' : 'NIGHT';
  }
  return { weekday: WEEKDAYS[wd], day_type: wd === 0 || wd === 6 ? 'WEEKEND' : 'WEEKDAY', day_period: period };
}

function notesWithPenalties(m) {
  if (m.penalty_home_score == null || /pênaltis/i.test(m.data_notes ?? '')) return m.data_notes ?? null;
  const pen = `Disputa de pênaltis: ${m.home_team} ${m.penalty_home_score}–${m.penalty_away_score} ${m.away_team}.`;
  return m.data_notes ? `${m.data_notes} ${pen}` : pen;
}

const COLS = [
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
  const venue = venueFor(m);
  const day = dayFields(m);
  return [
    sqlStr(m.id), sqlInt(m.calendar_year), sqlDate(m.date), sqlTime(m.time),
    sqlStr(m.status), sqlStr(m.competition), sqlStr(m.competition_code),
    sqlStr(m.competition_edition), sqlStr(m.round),
    sqlStr(m.round ? 'CONFIRMED' : 'ROUND_NOT_EXPOSED_BY_SOURCE'),
    sqlStr(opponent), sqlBool(m.club_is_home), sqlBool(m.neutral_site ?? false),
    sqlStr(m.home_team), sqlStr(m.away_team), sqlInt(m.home_score),
    sqlInt(m.away_score), sqlInt(m.club_score), sqlInt(m.opponent_score),
    sqlStr(m.score_display), sqlStr(m.outcome), sqlStr(m.stadium),
    sqlStr(m.stadium ? m.stadium_status : 'UNKNOWN'), sqlStr(venue?.id ?? null),
    sqlStr(day.weekday), sqlStr(day.day_type), sqlStr(day.day_period),
    sqlKickoff(m), sqlStr('America/Sao_Paulo'),
    sqlStr(m.time ? 'datetime' : 'date_only'), sqlStr(m.source_provider),
    sqlStr(m.source_match_id), sqlStr(m.source_url),
    sqlStr(m.source_confidence), sqlStr(notesWithPenalties(m)),
  ].join(', ');
}

// ------------------------------------------------------------- venues
function venuesSql(usedIds) {
  const used = venues.filter((v) => usedIds.has(v.id));
  const rows = used.map(
    (v) =>
      `  (${[
        sqlStr(v.id), sqlStr(v.canonical_name), sqlStr(v.display_name),
        sqlStr(v.city), sqlStr(v.state), sqlStr(v.country),
        v.latitude == null ? 'null' : String(v.latitude),
        v.longitude == null ? 'null' : String(v.longitude),
        sqlTextArray(v.aliases),
      ].join(', ')})`,
  );
  return `-- Catálogo de estádios do Passaporte do Vila Nova. GERADO por
-- \`node tooling/vilanova_passport/generate_passport_sql.mjs\` a partir de
-- docs/vila_nova_data/passport/venues.json — não edite à mão.
--
-- ${PROJECT_WARNING}
-- Ordem: vilanova_passport_infra.sql -> ESTE -> vilanova_passport_matches_<ano>_seed.sql.
-- Idempotente. ${used.length} estádios (só os usados por alguma partida do pacote).

${GUARD}
insert into public.venues
  (id, canonical_name, display_name, city, state, country, latitude, longitude, aliases)
values
${rows.join(',\n')}
on conflict (id) do update set
  canonical_name = excluded.canonical_name, display_name = excluded.display_name,
  city = excluded.city, state = excluded.state, country = excluded.country,
  latitude = excluded.latitude, longitude = excluded.longitude,
  aliases = excluded.aliases, updated_at = now();
`;
}

// ------------------------------------------------------------- partidas
function matchesSql(year, matches) {
  const updateSet = COLS.filter((c) => c !== 'id')
    .map((c) => `${c} = excluded.${c}`)
    .concat(['updated_at = now()'])
    .join(',\n    ');
  return `-- Passaporte do Vila Nova — temporada ${year}. GERADO por
-- \`node tooling/vilanova_passport/generate_passport_sql.mjs\` a partir de
-- docs/vila_nova_data/passport/passport_${year}.json — não edite à mão.
--
-- ${PROJECT_WARNING}
-- Ordem: vilanova_passport_infra.sql -> vilanova_passport_venues_seed.sql -> ESTE.
-- Idempotente (ON CONFLICT DO UPDATE): reexecutar atualiza, nunca duplica, e
-- não encosta em presença de usuário. ${matches.length} partidas.

${GUARD}
insert into public.passport_matches (
  ${COLS.join(', ')}
) values
${matches.map((m) => `  (${rowValues(m)})`).join(',\n')}
on conflict (id) do update set
    ${updateSet};

do $$
declare v_orphans int;
begin
  select count(*) into v_orphans from public.passport_matches
   where season = ${year} and stadium is not null and venue_id is null;
  if v_orphans > 0 then
    raise exception 'ha % partidas de ${year} com estadio sem venue_id -- rode vilanova_passport_venues_seed.sql antes', v_orphans;
  end if;
end $$;
`;
}

// ------------------------------------------------------------------ main
const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  const files = fs.readdirSync(PKG).filter((f) => /^passport_\d{4}\.json$/.test(f)).sort();
  const usedVenues = new Set();
  let total = 0;
  for (const f of files) {
    const year = Number(f.match(/\d{4}/)[0]);
    const matches = JSON.parse(fs.readFileSync(path.join(PKG, f), 'utf8')).matches.map((m) => ({
      ...m,
      // O pacote trouxe 3 jogos de 2026 com o ano em string ("2026").
      calendar_year: Number(m.calendar_year),
    }));
    for (const m of matches) {
      if (m.calendar_year !== year) throw new Error(`${m.id}: calendar_year ${m.calendar_year} em ${f}`);
      const v = venueFor(m);
      if (v) usedVenues.add(v.id);
    }
    fs.writeFileSync(path.join(OUT, `vilanova_passport_matches_${year}_seed.sql`), matchesSql(year, matches));
    total += matches.length;
    console.log(`${year}: ${matches.length} partidas`);
  }
  fs.writeFileSync(path.join(OUT, 'vilanova_passport_venues_seed.sql'), venuesSql(usedVenues));
  console.log(`venues: ${usedVenues.size} · total: ${total} partidas em ${files.length} anos`);
}
