import { readFileSync } from 'node:fs';

const src = readFileSync('lib/features/arena/games/lineup/lineup_matches.dart', 'utf8');

function findMatchingBracket(text, openIdx, openChar, closeChar) {
  let depth = 0;
  for (let i = openIdx; i < text.length; i++) {
    if (text[i] === openChar) depth++;
    else if (text[i] === closeChar) {
      depth--;
      if (depth === 0) return i;
    }
  }
  throw new Error('unbalanced brackets from ' + openIdx);
}

function splitTopLevel(text) {
  const parts = [];
  let depth = 0;
  let start = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '(' || c === '[') depth++;
    else if (c === ')' || c === ']') depth--;
    else if (c === ',' && depth === 0) {
      const chunk = text.slice(start, i).trim();
      if (chunk) parts.push(chunk);
      start = i + 1;
    }
  }
  const last = text.slice(start).trim();
  if (last) parts.push(last);
  return parts;
}

function unquote(s) {
  const t = s.trim();
  if (t.startsWith("'") && t.endsWith("'")) return t.slice(1, -1);
  if (t.startsWith('"') && t.endsWith('"')) return t.slice(1, -1);
  return t;
}

function parseQuotedListLiteral(s) {
  // s like: ['J. Batata'] or ['Túlio Maravilha']
  const matches = [...s.matchAll(/'((?:[^'\\]|\\.)*)'/g)];
  return matches.map((m) => m[1]);
}

function parseRow(call) {
  // _Row('GOL', null, 'Eduardo Heuser', 'EDUARDO') or with a 5th list arg
  const openParen = call.indexOf('(');
  const closeParen = findMatchingBracket(call, openParen, '(', ')');
  const inner = call.slice(openParen + 1, closeParen);
  const args = splitTopLevel(inner);
  const pos = unquote(args[0]);
  const no = args[1].trim() === 'null' ? null : parseInt(args[1].trim(), 10);
  const name = unquote(args[2]);
  const answer = unquote(args[3]);
  const aliases = args[4] ? parseQuotedListLiteral(args[4]) : [];
  return { pos, no, name, answer, aliases };
}

function extractNamedArg(callInnerParts, name) {
  const prefix = name + ':';
  const found = callInnerParts.find((p) => p.trim().startsWith(prefix));
  if (found === undefined) return null;
  return found.trim().slice(prefix.length).trim();
}

// Extract each top-level `_m(...)` call from the `lineupMatches` array literal.
const arrayStart = src.indexOf('final lineupMatches = <LineupMatch>[');
const openBracket = src.indexOf('[', arrayStart);
const closeBracket = findMatchingBracket(src, openBracket, '[', ']');
const arrayBody = src.slice(openBracket + 1, closeBracket);
const matchCalls = splitTopLevel(arrayBody).filter((c) => c.startsWith('_m('));

// Extract the curated display order list.
const orderStart = src.indexOf('const _displayOrder = [');
const orderOpenBracket = src.indexOf('[', orderStart);
const orderCloseBracket = findMatchingBracket(src, orderOpenBracket, '[', ']');
const orderBody = src.slice(orderOpenBracket + 1, orderCloseBracket);
const displayOrder = parseQuotedListLiteral(orderBody);

const matches = matchCalls.map((call) => {
  const openParen = call.indexOf('(');
  const closeParen = findMatchingBracket(call, openParen, '(', ')');
  const inner = call.slice(openParen + 1, closeParen);
  const parts = splitTopLevel(inner);

  const id = unquote(extractNamedArg(parts, 'id'));
  const competition = unquote(extractNamedArg(parts, 'competition'));
  const season = unquote(extractNamedArg(parts, 'season'));
  const phase = unquote(extractNamedArg(parts, 'phase'));
  const dateRaw = extractNamedArg(parts, 'date');
  const dateMatch = dateRaw.match(
    /DateTime\((\d+)(?:,\s*(\d+))?(?:,\s*(\d+))?\)/,
  );
  if (!dateMatch) throw new Error(`unparseable date for ${id}: ${dateRaw}`);
  const [, y, m = '1', d = '1'] = dateMatch;
  const isoDate = `${y.padStart(4, '0')}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
  const venueRaw = extractNamedArg(parts, 'venue');
  const venue = venueRaw ? unquote(venueRaw) : null;
  const home = unquote(extractNamedArg(parts, 'home'));
  const homeScore = parseInt(extractNamedArg(parts, 'homeScore'), 10);
  const away = unquote(extractNamedArg(parts, 'away'));
  const awayScore = parseInt(extractNamedArg(parts, 'awayScore'), 10);
  const formation = unquote(extractNamedArg(parts, 'formation'));
  const confidenceRaw = extractNamedArg(parts, 'confidence');
  const confidence = confidenceRaw.replace('FormationConfidence.', '').trim();

  const lineupRaw = extractNamedArg(parts, 'lineup');
  const lineupOpen = lineupRaw.indexOf('[');
  const lineupClose = findMatchingBracket(lineupRaw, lineupOpen, '[', ']');
  const lineupBody = lineupRaw.slice(lineupOpen + 1, lineupClose);
  const rows = splitTopLevel(lineupBody).map(parseRow);

  if (rows.length !== 11) {
    throw new Error(`${id}: expected 11 players, got ${rows.length}`);
  }

  return {
    id,
    competition,
    season,
    phase,
    date: isoDate,
    venue,
    home,
    homeScore,
    away,
    awayScore,
    formation,
    confidence,
    rows,
  };
});

console.error(`Parsed ${matches.length} matches`);

const orderIndex = new Map(displayOrder.map((id, i) => [id, i + 1]));
let nextOrder = displayOrder.length + 1;
for (const match of matches) {
  if (!orderIndex.has(match.id)) {
    orderIndex.set(match.id, nextOrder++);
  }
}

function sqlStringLiteral(s) {
  return "'" + s.replace(/'/g, "''") + "'";
}

function jsonbLiteral(value) {
  return sqlStringLiteral(JSON.stringify(value)) + '::jsonb';
}

const rowsSql = matches.map((match) => {
  const lineupJson = match.rows.map((r) => ({
    pos: r.pos,
    no: r.no,
    name: r.name,
    answer: r.answer,
    aliases: r.aliases,
  }));
  const cols = [
    sqlStringLiteral(match.id),
    sqlStringLiteral(match.competition),
    sqlStringLiteral(match.season),
    sqlStringLiteral(match.phase),
    sqlStringLiteral(match.date),
    match.venue ? sqlStringLiteral(match.venue) : 'null',
    sqlStringLiteral(match.home),
    String(match.homeScore),
    sqlStringLiteral(match.away),
    String(match.awayScore),
    sqlStringLiteral(match.formation),
    sqlStringLiteral(match.confidence),
    jsonbLiteral(lineupJson),
    String(orderIndex.get(match.id)),
  ];
  return '(' + cols.join(', ') + ')';
});

const sql = `-- ============================================================================
-- Adivinhe a Escalação — dataset de partidas históricas. Rode no SQL Editor
-- do Supabase. A tabela vira a fonte da verdade; o app cai no banco local
-- (const lineupMatches) se a tabela estiver vazia ou sem rede. Leitura é
-- pública; escrita só pelo dashboard/admin. \`lineup\` guarda só o que foi
-- curado à mão (posição, número, nome, resposta, apelidos) — as coordenadas
-- de campo e a resposta normalizada continuam sendo calculadas no Flutter a
-- partir da formação, nunca duplicadas aqui. Nunca reaproveitar um \`id\`
-- pra outra partida (progresso do usuário é rastreado por id).
-- ============================================================================

create table if not exists public.lineup_matches (
  id text primary key,
  competition text not null,
  season text not null,
  phase text not null,
  match_date date not null,
  venue text,
  home_team text not null,
  away_team text not null,
  home_score int not null,
  away_score int not null,
  formation text not null,
  formation_confidence text not null check (formation_confidence in ('confirmed','probable','estimated')),
  lineup jsonb not null,
  display_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.lineup_matches enable row level security;

drop policy if exists "read lineup matches" on public.lineup_matches;
create policy "read lineup matches" on public.lineup_matches
  for select using (true);

insert into public.lineup_matches (id, competition, season, phase, match_date, venue, home_team, home_score, away_team, away_score, formation, formation_confidence, lineup, display_order) values
${rowsSql.join(',\n')}
on conflict (id) do nothing;
`;

console.log(sql);
