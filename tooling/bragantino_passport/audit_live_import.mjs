// Auditoria AO VIVO do Passaporte do Bragantino, depois que os SQLs foram
// aplicados. Só leitura — este script nunca escreve no banco.
//
//   node tooling/bragantino_passport/audit_live_import.mjs
//
// Compara o que está NO BANCO com o que está nos JSON fonte deste repositório.
// Não confia em nenhum dos dois sozinho: divergência entre eles é justamente o
// que precisa aparecer.
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SOURCE_DIR = path.join(__dirname, 'source');

const URL_BASE = 'https://yrgyzkaaudyzmsqwzecj.supabase.co';
const KEY = 'sb_publishable_pa2JzbHgClEqRBAajsPjig_uvL5Ntcc';

// O projeto do Goiás. Aparece aqui só pra provar que NADA foi tocado nele.
const GOIAS_URL = 'https://yonozsdgyrhgqrvydbnr.supabase.co';

const problems = [];
function check(label, ok, detail = '') {
  console.log(`${ok ? 'PASS' : 'FAIL'} — ${label}${detail ? ` :: ${detail}` : ''}`);
  if (!ok) problems.push(label + (detail ? ` :: ${detail}` : ''));
}

async function rpc(fn, args = {}) {
  const res = await fetch(`${URL_BASE}/rest/v1/rpc/${fn}`, {
    method: 'POST',
    headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify(args),
  });
  const body = await res.text();
  try {
    return { status: res.status, json: JSON.parse(body) };
  } catch {
    return { status: res.status, json: null, body };
  }
}

/// Total de linhas sem baixar as linhas.
async function countRows(table, filter = '') {
  const res = await fetch(
    `${URL_BASE}/rest/v1/${table}?select=*${filter}&limit=1`,
    { headers: { apikey: KEY, Prefer: 'count=exact', Range: '0-0' } },
  );
  const range = res.headers.get('content-range') ?? '';
  const total = Number(range.split('/')[1]);
  return Number.isFinite(total) ? total : null;
}

/// PostgREST pagina em 1000 por padrão — busca tudo em fatias.
async function fetchAll(table, select) {
  const out = [];
  const page = 1000;
  for (let from = 0; ; from += page) {
    const res = await fetch(
      `${URL_BASE}/rest/v1/${table}?select=${select}&order=id.asc`,
      { headers: { apikey: KEY, Range: `${from}-${from + page - 1}` } },
    );
    const rows = await res.json();
    if (!Array.isArray(rows)) throw new Error(JSON.stringify(rows));
    out.push(...rows);
    if (rows.length < page) return out;
  }
}

function loadSourceMatches() {
  return fs
    .readdirSync(SOURCE_DIR)
    .filter((f) => /^bragantino_passport_\d{4}\.json$/.test(f))
    .sort()
    .flatMap(
      (f) =>
        JSON.parse(fs.readFileSync(path.join(SOURCE_DIR, f), 'utf8')).matches,
    );
}

async function main() {
  const source = loadSourceMatches();
  const sourceById = new Map(source.map((m) => [m.id, m]));

  // ---- 1. as 186 partidas entraram ---------------------------------------
  console.log('\n== 1. importacao ==');
  const total = await countRows('passport_matches');
  check(
    `${source.length} partidas importadas`,
    total === source.length,
    `banco tem ${total}`,
  );

  // ---- 2. total por ano ---------------------------------------------------
  console.log('\n== 2. total por ano ==');
  const bySourceYear = source.reduce((acc, m) => {
    acc[m.calendar_year] = (acc[m.calendar_year] ?? 0) + 1;
    return acc;
  }, {});
  for (const year of Object.keys(bySourceYear).sort()) {
    const live = await countRows('passport_matches', `&season=eq.${year}`);
    check(
      `${year}: ${bySourceYear[year]} partidas`,
      live === bySourceYear[year],
      `banco tem ${live}`,
    );
  }

  // ---- 3. venue_id e catálogo --------------------------------------------
  console.log('\n== 3. estadios ==');
  const { buildVenues } = await import(
    pathToFileURL(path.join(__dirname, 'build_venues.mjs')).href
  );
  const expectedVenues = buildVenues(source).venues;
  const liveVenues = await fetchAll('venues', 'id,display_name,city,aliases');
  check(
    `catalogo com ${expectedVenues.length} estadios`,
    liveVenues.length === expectedVenues.length,
    `banco tem ${liveVenues.length}`,
  );

  const liveVenueIds = new Set(liveVenues.map((v) => v.id));
  const missingVenues = expectedVenues.filter((v) => !liveVenueIds.has(v.id));
  check(
    'todo estadio esperado existe no banco',
    missingVenues.length === 0,
    missingVenues.map((v) => v.id).join(', '),
  );

  const matches = await fetchAll(
    'passport_matches',
    'id,season,match_date,match_time,kickoff_at,date_precision,display_timezone,status,competition,competition_code,opponent,club_is_home,club_score,opponent_score,outcome,stadium,stadium_status,venue_id,weekday,day_type,day_period,source_provider,source_url',
  );

  const orphans = matches.filter((m) => m.stadium && !m.venue_id);
  check(
    'nenhuma partida com estadio ficou sem venue_id',
    orphans.length === 0,
    orphans.map((m) => m.id).join(', '),
  );

  const danglingFk = matches.filter(
    (m) => m.venue_id && !liveVenueIds.has(m.venue_id),
  );
  check(
    'todo venue_id aponta pra um estadio existente',
    danglingFk.length === 0,
    danglingFk.map((m) => m.id).join(', '),
  );

  // ---- 4. evidência de estádio -------------------------------------------
  console.log('\n== 4. evidencia de estadio ==');
  const VALID = ['MATCH_SPECIFIC', 'HISTORICAL_RECONSTRUCTION', 'UNKNOWN'];
  const dist = matches.reduce((acc, m) => {
    acc[m.stadium_status] = (acc[m.stadium_status] ?? 0) + 1;
    return acc;
  }, {});
  console.log('     distribuicao:', JSON.stringify(dist));
  check(
    'todo stadium_status esta no vocabulario',
    Object.keys(dist).every((k) => VALID.includes(k)),
  );

  const brokenInvariant = matches.filter((m) =>
    m.stadium ? m.stadium_status === 'UNKNOWN' : m.stadium_status !== 'UNKNOWN',
  );
  check(
    'estadio e evidencia andam juntos nos dois sentidos',
    brokenInvariant.length === 0,
    brokenInvariant.map((m) => m.id).join(', '),
  );

  const promoted = matches.filter((m) => {
    const src = sourceById.get(m.id);
    if (!src) return false;
    const expected =
      src.stadium_status === 'NEEDS_SOURCE' ? 'UNKNOWN' : src.stadium_status;
    return m.stadium_status !== expected;
  });
  check(
    'nenhuma evidencia foi promovida na importacao',
    promoted.length === 0,
    promoted.map((m) => `${m.id}: ${m.stadium_status}`).join(', '),
  );

  // ---- 4b. o dado bate campo a campo com a fonte --------------------------
  console.log('\n== 4b. fidelidade a fonte ==');
  const drift = [];
  for (const m of matches) {
    const src = sourceById.get(m.id);
    if (!src) {
      drift.push(`${m.id}: nao existe na fonte`);
      continue;
    }
    const cmp = {
      season: [m.season, src.calendar_year],
      match_date: [m.match_date, src.date],
      status: [m.status, src.score_status],
      club_is_home: [m.club_is_home, src.club_is_home],
      club_score: [m.club_score, src.club_score],
      opponent_score: [m.opponent_score, src.opponent_score],
      outcome: [m.outcome, src.outcome],
      stadium: [m.stadium, src.stadium],
      day_period: [m.day_period, src.day_period],
      day_type: [m.day_type, src.day_type],
      weekday: [m.weekday, src.weekday],
      source_url: [m.source_url, src.source_url],
    };
    for (const [field, [live, want]] of Object.entries(cmp)) {
      if ((live ?? null) !== (want ?? null)) {
        drift.push(`${m.id}.${field}: banco=${live} fonte=${want}`);
      }
    }
    const wantPrecision = src.time ? 'datetime' : 'date_only';
    if (m.date_precision !== wantPrecision) {
      drift.push(
        `${m.id}.date_precision: banco=${m.date_precision} esperado=${wantPrecision}`,
      );
    }
    if (!src.time && m.kickoff_at !== null) {
      drift.push(`${m.id}.kickoff_at: sem horario na fonte mas preenchido`);
    }
    if (m.display_timezone !== 'America/Sao_Paulo') {
      drift.push(`${m.id}.display_timezone: ${m.display_timezone}`);
    }
  }
  check(
    'nenhum campo divergiu da fonte',
    drift.length === 0,
    drift.slice(0, 8).join(' | '),
  );

  check(
    'todos os ids preservaram o prefixo pb_onef_/pb_ogol_',
    matches.every((m) => /^pb_(onef|ogol)_/.test(m.id)),
  );

  const goiasLeak = matches.filter((m) =>
    /goi[áa]s esporte|hail[ée] pinheiro|serrinha/i.test(JSON.stringify(m)),
  );
  check(
    'nenhum rastro de dado do Goias',
    goiasLeak.length === 0,
    goiasLeak.map((m) => m.id).join(', '),
  );

  // `competition_code` é o que monta os chips de filtro da tela
  // (passport_state.dart). Duas grafias do mesmo código viram DOIS chips pra
  // mesma competição — foi assim que SUDAMERICANA/SULAMERICANA passou batido
  // na primeira auditoria. O sinal é o nome de exibição repetido sob códigos
  // diferentes.
  const codesByName = new Map();
  for (const m of matches) {
    if (!codesByName.has(m.competition)) codesByName.set(m.competition, new Set());
    codesByName.get(m.competition).add(m.competition_code);
  }
  const split = [...codesByName.entries()].filter(([, codes]) => codes.size > 1);
  check(
    'nenhuma competicao aparece com mais de um competition_code',
    split.length === 0,
    split.map(([name, c]) => `${name}: ${[...c].join('/')}`).join(' | '),
  );

  // ---- 5. RPCs reais ------------------------------------------------------
  console.log('\n== 5. RPCs ==');
  const seasons = await rpc('passport_seasons');
  const seasonMap = Object.fromEntries(
    (seasons.json ?? []).map((s) => [s.season, s]),
  );
  check(
    'passport_seasons lista todos os anos',
    Object.keys(bySourceYear).every((y) => seasonMap[y]),
    JSON.stringify(seasons.json),
  );

  for (const year of Object.keys(bySourceYear).sort()) {
    const r = await rpc('passport_matches_for_year', { p_season: Number(year) });
    const rows = r.json ?? [];
    check(
      `passport_matches_for_year(${year}) devolve ${bySourceYear[year]} partidas`,
      rows.length === bySourceYear[year],
      `devolveu ${rows.length}`,
    );
    // O contrato NÃO é "toda partida tem estádio" — é "partida com evidência
    // resolve o nome, partida UNKNOWN legitimamente não resolve". Exigir
    // venue_name de todas seria pressão pra inventar estádio só pro teste
    // passar. Hoje as 186 são MATCH_SPECIFIC, então na prática dá 100%; a
    // assertiva certa é a que continua valendo quando isso mudar.
    const statusById = new Map(matches.map((m) => [m.id, m.stadium_status]));
    const semNome = rows.filter(
      (x) => statusById.get(x.id) !== 'UNKNOWN' && !x.venue_name,
    );
    const nomeIndevido = rows.filter(
      (x) => statusById.get(x.id) === 'UNKNOWN' && x.venue_name,
    );
    check(
      `  ...toda partida COM evidencia resolve venue_name`,
      semNome.length === 0,
      semNome.map((x) => x.id).join(', '),
    );
    check(
      `  ...nenhuma partida UNKNOWN ganhou estadio do nada`,
      nomeIndevido.length === 0,
      nomeIndevido.map((x) => x.id).join(', '),
    );
    const sample = rows[0];
    if (sample) {
      check(
        '  ...com mando e placar em nomes genericos',
        'club_is_home' in sample && 'club_score' in sample,
        Object.keys(sample).join(','),
      );
      check(
        '  ...attended false sem sessao',
        rows.every((x) => x.attended === false),
      );
    }
  }

  const ranking = await rpc('passport_ranking', { p_year: null, p_limit: 10 });
  check(
    'passport_ranking responde',
    ranking.status === 200,
    JSON.stringify(ranking.json).slice(0, 120),
  );

  // Guards de escrita: sem sessão TÊM que recusar.
  for (const [fn, args] of [
    ['passport_save_attendances', { p_changes: [] }],
    ['passport_set_memorable_match', { p_match_id: matches[0]?.id ?? 'x' }],
  ]) {
    const r = await rpc(fn, args);
    check(
      `${fn} recusa sem sessao`,
      r.json?.message === 'not authenticated',
      JSON.stringify(r.json).slice(0, 120),
    );
  }

  // ---- 9. estádio mais visitado (expectativa calculada da fonte) ----------
  console.log('\n== 9. estadio mais visitado (referencia) ==');
  const top = [...expectedVenues].sort((a, b) => b.match_count - a.match_count)[0];
  console.log(
    `     Marcando presenca em TODAS as partidas, o estadio mais visitado tem` +
      ` que ser "${top.display_name}" (${top.match_count} jogos).`,
  );

  // ---- 10. isolamento: o Goiás não foi tocado ----------------------------
  console.log('\n== 10. o banco do Goias segue intacto ==');
  const goiasRpc = await fetch(
    `${GOIAS_URL}/rest/v1/rpc/passport_matches_for_year`,
    {
      method: 'POST',
      headers: { apikey: KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_season: 2024 }),
    },
  );
  check(
    'a chave do Bragantino NAO abre o banco do Goias (isolamento por projeto)',
    goiasRpc.status === 401,
    `status ${goiasRpc.status}`,
  );

  console.log('\n' + '='.repeat(70));
  if (problems.length === 0) {
    console.log('AUDITORIA POS-IMPORTACAO: TUDO PASSOU');
  } else {
    console.log(`AUDITORIA POS-IMPORTACAO: ${problems.length} PROBLEMA(S)`);
    for (const p of problems) console.log(`  - ${p}`);
  }
  process.exit(problems.length === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('ERRO NA AUDITORIA:', e.message);
  process.exit(2);
});
