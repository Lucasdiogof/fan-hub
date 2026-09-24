import fs from 'fs';
import path from 'path';

const year = process.argv[2];
if (!year) { console.error('uso: node _build_year_final.mjs <ano>'); process.exit(1); }

const master = JSON.parse(fs.readFileSync(`source/bragantino_${year}_master_raw.json`, 'utf8'));

const venueFiles = fs.readdirSync('source').filter((f) => f.startsWith(`ogol_${year}_venues_`) && f.endsWith('.json'));
const venueByUrl = new Map();
for (const f of venueFiles) {
  for (const v of JSON.parse(fs.readFileSync(`source/${f}`, 'utf8'))) venueByUrl.set(v.url, v);
}

// Geografia herdada de TODOS os lotes ja fechados (2023-2026) - cresce a
// cada lote novo, nunca reinventa cidade/pais de um estadio ja visto.
const existingYears = fs.readdirSync('source').filter((f) => /^bragantino_passport_\d{4}\.json$/.test(f));
const VENUE_GEO = {};
for (const f of existingYears) {
  const wrapper = JSON.parse(fs.readFileSync(`source/${f}`, 'utf8'));
  for (const m of wrapper.matches) {
    if (m.stadium && !VENUE_GEO[m.stadium]) {
      VENUE_GEO[m.stadium] = { city: m.venue_city, state: m.venue_state, country: m.venue_country };
    }
  }
}

// Estadios que aparecem pela 1a vez neste lote e ainda nao estao em nenhum
// lote anterior - preencher AQUI antes de rodar, com fonte confirmada
// (catalogo do Goias quando a mesma casa ja existe la, ou fato publico
// estavel e sem ambiguidade).
const NEW_VENUE_GEO = JSON.parse(fs.readFileSync(`source/new_venue_geo_${year}.json`, 'utf8'));
Object.assign(VENUE_GEO, NEW_VENUE_GEO);

const COMP_META = {
  'Paulista': { competition: 'Paulista', competition_code: 'PAULISTA' },
  'Paulistão': { competition: 'Paulista', competition_code: 'PAULISTA' },
  'Paulista Série A2': { competition: 'Paulista Série A2', competition_code: 'PAULISTA_A2' },
  'Paulista A2': { competition: 'Paulista Série A2', competition_code: 'PAULISTA_A2' },
  'Copa Paulista': { competition: 'Copa Paulista', competition_code: 'COPA_PAULISTA' },
  'Brasileirão': { competition: 'Brasileirão Série A', competition_code: 'BRASILEIRAO_A' },
  'Copa João Havelange': { competition: 'Brasileirão Série A', competition_code: 'BRASILEIRAO_A' },
  'Brasileirão Série A': { competition: 'Brasileirão Série A', competition_code: 'BRASILEIRAO_A' },
  'Brasileirão Série B': { competition: 'Brasileirão Série B', competition_code: 'BRASILEIRAO_B' },
  'Copa do Brasil': { competition: 'Copa do Brasil', competition_code: 'COPA_DO_BRASIL' },
  'Copa Brasil': { competition: 'Copa do Brasil', competition_code: 'COPA_DO_BRASIL' },
  'Sudamericana': { competition: 'CONMEBOL Sudamericana', competition_code: 'SUDAMERICANA' },
  'Copa Sudamericana': { competition: 'CONMEBOL Sudamericana', competition_code: 'SUDAMERICANA' },
  'Copa Sul-Americana': { competition: 'CONMEBOL Sudamericana', competition_code: 'SUDAMERICANA' },
  'Série B': { competition: 'Brasileirão Série B', competition_code: 'BRASILEIRAO_B' },
  'Série C': { competition: 'Brasileirão Série C', competition_code: 'BRASILEIRAO_C' },
  'Serie C': { competition: 'Brasileirão Série C', competition_code: 'BRASILEIRAO_C' },
  'Copa Paulista': { competition: 'Copa Paulista', competition_code: 'COPA_PAULISTA' },
  'Libertadores': { competition: 'CONMEBOL Libertadores', competition_code: 'LIBERTADORES' },
  'Copa Libertadores': { competition: 'CONMEBOL Libertadores', competition_code: 'LIBERTADORES' },
};

const WEEKDAYS = ['domingo', 'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado'];
function dayPeriod(time) {
  const [h] = time.split(':').map(Number);
  if (h < 12) return 'MORNING';
  if (h < 18) return 'AFTERNOON';
  return 'NIGHT';
}

// Partidas com resultado administrativo (W.O./desistência do adversário,
// nunca jogadas de verdade) -- a fonte não guarda placar nenhum pra elas
// (ex.: "Bragantino DA São José", 2006-08-25 -- "DA" = decisão
// administrativa, times nem entraram em campo pro 2º tempo, "Int: 0-0").
// Excluídas do lote: nenhum torcedor "esteve" numa partida que não
// aconteceu, e forçar um placar fabricado (0-0, 3-0 etc.) violaria a regra
// de nunca inventar dado. Reduz o total oficial do ano abaixo do que o
// audit_manifest_v4 registrou -- documentado como reconciliação nova.
const ADMIN_RESULT_EXCLUSIONS = {
  '11004630': 'W.O./decisão administrativa (Copa Paulista 2006) -- fonte não registra placar; partida interrompida no intervalo 0-0 (ver "Int: 0-0" na ficha) e resultado dado por desistência do adversário.',
};

const missing = [];
const geoWarnings = [];
const excludedAdmin = [];
const enriched = master
  .filter((m) => {
    const reason = ADMIN_RESULT_EXCLUSIONS[m.source_match_id];
    if (reason) {
      excludedAdmin.push(`${m.source_match_id} ${m.date} ${m.opponent} -- ${reason}`);
      return false;
    }
    return true;
  })
  .map((m) => {
  const v = venueByUrl.get(m.source_url);
  // `v` ausente = esquecemos de buscar essa ficha (erro, aborta). `v`
  // presente com `location` null/vazio = a propria fonte nao sabe o
  // estadio dessa partida (legitimo - vira UNKNOWN, nao inferido).
  if (!v) missing.push(`${m.source_match_id} ${m.date} ${m.opponent}`);
  // Alguns edicoes do oGol (ex.: "Copa Paulista 16", visto no lote 2016) usam
  // ano com 2 digitos em vez de 4 - a mesma edicao/slug que causou o bug do
  // COMPETITION_RE la no master raw (ver nota no build do 2016).
  const compKey = m.competition_display.replace(/\s+\d{2,4}$/, '');
  const meta = COMP_META[compKey];
  if (!meta) throw new Error(`competicao sem meta: "${m.competition_display}" (chave derivada: "${compKey}")`);

  let time = m.time;
  if (v?.startDate) {
    const d = new Date(v.startDate);
    const br = new Date(d.getTime() - 3 * 3600 * 1000);
    time = `${String(br.getUTCHours()).padStart(2, '0')}:${String(br.getUTCMinutes()).padStart(2, '0')}`;
  }

  const date = new Date(`${m.date}T12:00:00Z`);
  const weekday = WEEKDAYS[date.getUTCDay()];
  const day_type = date.getUTCDay() === 0 || date.getUTCDay() === 6 ? 'WEEKEND' : 'WEEKDAY';

  const clubScore = m.club_is_home ? m.home_score : m.away_score;
  const opponentScore = m.club_is_home ? m.away_score : m.home_score;
  const outcome = clubScore > opponentScore ? 'WIN' : clubScore < opponentScore ? 'LOSS' : 'DRAW';

  const homeTeam = m.club_is_home ? 'Red Bull Bragantino' : m.opponent;
  const awayTeam = m.club_is_home ? m.opponent : 'Red Bull Bragantino';

  const stadium = v?.location || null; // "" (JSON-LD com o campo vazio) e null viram a mesma coisa: UNKNOWN
  const geo = stadium ? VENUE_GEO[stadium] : null;
  if (stadium && !geo) geoWarnings.push(stadium);

  return {
    id: `pb_ogol_${m.source_match_id}`,
    calendar_year: Number(year),
    competition: meta.competition,
    competition_code: meta.competition_code,
    competition_edition: m.competition_display,
    round: null,
    phase_status: 'ROUND_NOT_EXPOSED_BY_SOURCE',
    date: m.date,
    time,
    weekday,
    day_type,
    day_period: time ? dayPeriod(time) : 'UNKNOWN',
    home_team: homeTeam,
    away_team: awayTeam,
    club_is_home: m.club_is_home,
    home_score: m.home_score,
    away_score: m.away_score,
    club_score: clubScore,
    opponent_score: opponentScore,
    score_display: `${m.home_score}–${m.away_score}`,
    score_status: 'FINISHED',
    outcome,
    penalty_home_score: m.penalty_home_score,
    penalty_away_score: m.penalty_away_score,
    stadium,
    stadium_status: stadium ? 'MATCH_SPECIFIC' : 'UNKNOWN',
    venue_city: geo?.city ?? null,
    venue_state: geo?.state ?? null,
    venue_country: geo?.country ?? null,
    source_provider: 'oGol (ogol.com.br)',
    source_match_id: m.source_match_id,
    source_url: m.source_url,
    source_confidence: 'HIGH',
    data_notes: v?.note ?? null,
  };
});

if (missing.length) { console.error('MISSING VENUE FOR:', missing); process.exit(1); }
if (geoWarnings.length) { console.error('SEM GEOGRAFIA PARA:', [...new Set(geoWarnings)]); process.exit(1); }
if (excludedAdmin.length) {
  console.log(`\nEXCLUÍDAS (W.O./decisão administrativa, ${excludedAdmin.length}):`);
  for (const line of excludedAdmin) console.log('  ' + line);
}

const byCompetition = {};
for (const m of enriched) byCompetition[m.competition] = (byCompetition[m.competition] || 0) + 1;
console.log('by competition:', byCompetition);
console.log('outcomes:', enriched.reduce((acc, m) => ((acc[m.outcome] = (acc[m.outcome] || 0) + 1), acc), {}));

const final = {
  schema_version: '1.0.0-bragantino',
  dataset: 'bragantino_passport_matches',
  club: {
    code: 'bragantino',
    display_name: 'Red Bull Bragantino',
    historical_name: 'Clube Atlético Bragantino',
    identity_note: 'Uma unica historia de clube (Clube Atletico Bragantino ate 2019-12-31, Red Bull Bragantino desde 2020-01-01) - nunca modelado como dois clubes.',
    canonical_club_id: '51683d2a-ea1d-57c6-8014-996146f242e7',
    onefootball_team_id: 4734,
    onefootball_team_slug: 'rb-bragantino-4734',
  },
  generated_at: new Date().toISOString(),
  cutoff_date: '2026-09-18',
  scope: `Lote retrocedendo ano a ano (2000-2026) - temporada ${year} completa e encerrada. Reconciliado por competicao contra o total oficial do audit_manifest_v4 antes de fechar o lote.`,
  eligibility_rule: 'Somente partidas profissionais oficiais do time principal. Exclui amistosos/base/equipes B.',
  sources: [
    {
      provider: 'oGol (ogol.com.br)',
      base_url: 'https://www.ogol.com.br',
      team_internal_id: 3156,
      endpoints_used: [
        `equipe/red-bull-bragantino/todos-os-jogos?epoca_id=<id>&compet_id_jogos=<id> (por competicao, ${year})`,
        'jogo/<slug>/<id> (por partida, JSON-LD schema.org/SportsEvent -> estadio + startDate real, via fetch() dentro da propria pagina do navegador)',
      ],
      note: 'View geral "todos-os-jogos?epoca_id=<id>&grp=1" (sem compet_id_jogos) pode renderizar so uma fatia da tabela (visto em 2023: 40/62) - lote sempre fechado buscando cada competicao separadamente e reconciliando contra o total oficial.',
    },
  ],
  data_quality: {
    stadium_rule: 'CRITICO: estadio NUNCA inferido pelo mandante. Toda partida usa o local do proprio JSON-LD da ficha (schema.org SportsEvent, location.name).',
    time_rule: 'Horario do startDate do JSON-LD (instante com offset real) convertido pra hora local do Brasil (UTC-3), nunca do texto de hora solto da tabela.',
    round_rule: 'phase_status=ROUND_NOT_EXPOSED_BY_SOURCE - o parser nao extrai o texto de rodada (ex. "R38").',
    geo_provenance: 'city/state/country: reaproveitados de lotes ja fechados quando a mesma casa ja aparecia la; estadios novos confirmados contra data_export/goias/venues.json (mesma casa documentada em partida do Goias) ou fato publico estavel e sem ambiguidade - ver source/new_venue_geo_' + year + '.json.',
  },
  summary: {
    total_matches: enriched.length,
    by_competition: byCompetition,
  },
  matches: enriched,
};

fs.writeFileSync(`source/bragantino_passport_${year}.json`, JSON.stringify(final, null, 2));
console.log(`WROTE source/bragantino_passport_${year}.json with ${enriched.length} matches`);
