import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parseOgolTeamMatches } from './parse_ogol_matches.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SOURCE_DIR = path.join(__dirname, 'source');

const EXPECTED = new Map([
  [2000,38],[2001,56],[2002,41],[2003,26],[2004,14],[2005,36],[2006,41],[2007,65],
  [2008,61],[2009,57],[2010,57],[2011,57],[2012,61],[2013,59],[2014,62],[2015,56],
  [2016,84],[2017,42],[2018,40],[2019,52],[2020,44],[2021,80],[2022,60],
]);

const EPoca = (year) => year + 129 - 2000;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function stripYear(s, year) {
  return (s ?? 'Competição').replace(new RegExp(`\\s+${year}$`), '').trim();
}
function competitionCode(name) {
  return name.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase().replace(/[^A-Z0-9]+/g,'_').replace(/^_|_$/g,'');
}
function weekday(date) {
  return new Intl.DateTimeFormat('pt-BR',{weekday:'long',timeZone:'UTC'}).format(new Date(`${date}T12:00:00Z`));
}
function dayType(date) {
  const d = new Date(`${date}T12:00:00Z`).getUTCDay();
  return d === 0 || d === 6 ? 'WEEKEND' : 'WEEKDAY';
}
function dayPeriod(time) {
  if (!time) return 'UNKNOWN';
  const h = Number(time.slice(0,2));
  if (h < 6) return 'DAWN';
  if (h < 12) return 'MORNING';
  if (h < 18) return 'AFTERNOON';
  return 'NIGHT';
}
function clubName(year) { return year <= 2019 ? 'Bragantino' : 'Red Bull Bragantino'; }
function normalizeMatch(m, year) {
  if (m.club_is_home === null || !m.opponent) throw new Error(`${year}/${m.source_match_id}: mandante ou adversário não resolvido`);
  const club = clubName(year);
  const homeTeam = m.club_is_home ? club : m.opponent;
  const awayTeam = m.club_is_home ? m.opponent : club;
  const clubScore = m.club_is_home ? m.home_score : m.away_score;
  const opponentScore = m.club_is_home ? m.away_score : m.home_score;
  if (clubScore === null || opponentScore === null) throw new Error(`${year}/${m.source_match_id}: placar ausente`);
  const outcome = clubScore > opponentScore ? 'WIN' : clubScore < opponentScore ? 'LOSS' : 'DRAW';
  const comp = stripYear(m.competition_display, year);
  return {
    id: `pb_ogol_${m.source_match_id}`,
    calendar_year: year,
    competition: comp,
    competition_code: competitionCode(comp),
    competition_edition: m.competition_display,
    round: null,
    phase_status: 'ROUND_NOT_EXPOSED_BY_SOURCE',
    date: m.date,
    time: m.time,
    weekday: weekday(m.date),
    day_type: dayType(m.date),
    day_period: dayPeriod(m.time),
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
    neutral_site: false,
    stadium: null,
    stadium_status: 'UNKNOWN',
    source_provider: m.source === 'zerozero' ? 'ZeroZero/oGol network' : 'oGol',
    source_match_id: m.source_match_id,
    source_url: m.source_url,
    source_confidence: 'HIGH',
    data_notes: m.date_href_mismatch ? `Data exibida ${m.date}; slug da URL ${m.source_url_date}. Data exibida é canônica.` : null,
    source_url_date: m.source_url_date,
    date_href_mismatch: m.date_href_mismatch,
  };
}

async function fetchText(url) {
  let last;
  for (let attempt=1; attempt<=4; attempt++) {
    try {
      const res = await fetch(url, {headers:{
        'user-agent':'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/152 Safari/537.36',
        'accept-language':'pt-BR,pt;q=0.9,en;q=0.7',
        'accept':'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      }});
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.text();
    } catch (e) {
      last = e;
      await sleep(1400 * attempt);
    }
  }
  throw last;
}

function sourceCandidates(epocaId, page) {
  const suffix = `epoca_id=${epocaId}&grp=1${page===1?'':`&page=${page}`}`;
  return [
    {provider:'oGol', url:`https://www.ogol.com.br/equipe/red-bull-bragantino/todos-os-jogos?${suffix}`},
    {provider:'ZeroZero', url:`https://www.zerozero.pt/equipa/red-bull-bragantino/jogos?${suffix}`},
  ];
}

async function fetchPage(epocaId, page) {
  const errors = [];
  for (const candidate of sourceCandidates(epocaId, page)) {
    try {
      const html = await fetchText(candidate.url);
      return {...candidate, html};
    } catch (e) {
      errors.push(`${candidate.provider}: ${e.message}`);
    }
  }
  throw new Error(`fontes indisponíveis para epoca=${epocaId} page=${page}: ${errors.join(' | ')}`);
}

async function collectYear(year) {
  const expected = EXPECTED.get(year);
  if (!expected) throw new Error(`Ano sem contagem auditada: ${year}`);
  const epocaId = EPoca(year);
  const dedup = new Map();
  const pages = [];
  for (let page=1; page<=4 && dedup.size < expected; page++) {
    const fetched = await fetchPage(epocaId, page);
    const parsed = parseOgolTeamMatches(fetched.html,{teamSlug:'red-bull-bragantino'});
    pages.push({page,url:fetched.url,provider:fetched.provider,parsed:parsed.length});
    for (const m of parsed) dedup.set(m.source_match_id,m);
    await sleep(1100);
  }
  const raw = [...dedup.values()].filter((m)=>m.date?.startsWith(`${year}-`));
  if (raw.length !== expected) {
    throw new Error(`${year}: esperado ${expected}, obtido ${raw.length}. páginas=${JSON.stringify(pages)}`);
  }
  const rows = raw.map((m)=>normalizeMatch(m,year)).sort((a,b)=>a.date.localeCompare(b.date)||a.source_match_id.localeCompare(b.source_match_id));
  const ids = new Set(rows.map((r)=>r.source_match_id));
  if (ids.size !== expected) throw new Error(`${year}: IDs não únicos`);
  const wrapper = {
    schema_version:'1.0.0-bragantino-historical',
    dataset:'bragantino_passport_matches',
    generated_at:new Date().toISOString(),
    scope:'Partidas oficiais do time profissional masculino principal; amistosos/base/B/U23 excluídos.',
    source:{provider:'oGol/ZeroZero network',epoca_id:epocaId,pages},
    reconciliation:{expected_matches:expected,materialized_matches:rows.length,status:'CLOSED'},
    data_quality:{stadium_rule:'UNKNOWN até confirmação match-specific; nunca inferido.',date_rule:'data exibida na tabela é canônica; data do slug preservada apenas para auditoria.',date_href_mismatches:rows.filter((r)=>r.date_href_mismatch).length},
    year_status:'CLOSED',
    matches:rows,
  };
  const out = path.join(SOURCE_DIR,`bragantino_passport_${year}.json`);
  fs.writeFileSync(out,JSON.stringify(wrapper,null,2)+'\n');
  console.log(`CLOSED ${year}: ${rows.length}/${expected} -> ${out}`);
}

const start = Number(process.argv[2] ?? 2000);
const end = Number(process.argv[3] ?? 2022);
for (let year=start; year<=end; year++) await collectYear(year);
console.log(`Materialização concluída ${start}-${end}.`);
