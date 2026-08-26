import { readFileSync } from 'node:fs';

const src = readFileSync('lib/features/arena/games/career_path/career_players.dart', 'utf8');

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
  // Splits a comma-separated list of `Foo(...)` calls, respecting nesting.
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

function parseCall(call) {
  // call looks like: _goias('1996–2002', 61, 11) or _club('2004', 'Toulouse', 16, 3, loan: true)
  const nameMatch = call.match(/^(_goias|_club|_nat)\(/);
  const fnName = nameMatch[1];
  const openParen = call.indexOf('(');
  const closeParen = findMatchingBracket(call, openParen, '(', ')');
  const inner = call.slice(openParen + 1, closeParen);
  const args = splitTopLevel(inner);

  const positional = [];
  let loan = false;
  for (const arg of args) {
    const loanMatch = arg.match(/^loan:\s*(true|false)/);
    if (loanMatch) {
      loan = loanMatch[1] === 'true';
      continue;
    }
    positional.push(arg.trim());
  }

  const parseStr = (s) => s.replace(/^'/, '').replace(/'$/, '');
  const parseIntOrNull = (s) => (s === 'null' ? null : parseInt(s, 10));

  if (fnName === '_goias') {
    const [period, apps, goals] = positional;
    return {
      period: parseStr(period),
      team: 'Goiás',
      appearances: parseIntOrNull(apps),
      goals: parseIntOrNull(goals),
      loan,
      is_goias: true,
    };
  }
  if (fnName === '_club') {
    const [period, team, apps, goals] = positional;
    return {
      period: parseStr(period),
      team: parseStr(team),
      appearances: parseIntOrNull(apps),
      goals: parseIntOrNull(goals),
      loan,
      is_goias: false,
    };
  }
  // _nat
  const [period, team, apps, goals] = positional;
  return {
    period: parseStr(period),
    team: parseStr(team),
    appearances: parseIntOrNull(apps),
    goals: parseIntOrNull(goals),
    loan: false,
    is_goias: false,
  };
}

function parseEntryCalls(listBody) {
  return splitTopLevel(listBody).map(parseCall);
}

function extractBracketBlock(text, label) {
  const idx = text.indexOf(label);
  if (idx === -1) return null;
  const openIdx = text.indexOf('[', idx);
  const closeIdx = findMatchingBracket(text, openIdx, '[', ']');
  return text.slice(openIdx + 1, closeIdx);
}

function extractQuotedList(text, label) {
  const body = extractBracketBlock(text, label);
  if (body === null) return [];
  const matches = [...body.matchAll(/'((?:[^'\\]|\\.)*)'/g)];
  return matches.map((m) => m[1]);
}

// Split top-level CareerPlayer( ... ) blocks inside the outer array.
const arrayBody = extractBracketBlock(src, 'final List<CareerPlayer> careerPlayers = ');
const playerBlocks = splitTopLevel(arrayBody).filter((b) => b.startsWith('CareerPlayer('));

const players = playerBlocks.map((block) => {
  const idMatch = block.match(/id:\s*'([^']+)'/);
  const answerMatch = block.match(/answer:\s*'([^']+)'/);
  const positionMatch = block.match(/position:\s*'([^']+)'/);
  const acceptedAnswers = extractQuotedList(block, 'acceptedAnswers:');
  const clubCareerBody = extractBracketBlock(block, 'clubCareer:');
  const nationalTeamsBody = extractBracketBlock(block, 'nationalTeams:');

  return {
    id: idMatch[1],
    answer: answerMatch[1],
    acceptedAnswers,
    position: positionMatch ? positionMatch[1] : null,
    clubCareer: clubCareerBody ? parseEntryCalls(clubCareerBody) : [],
    nationalTeams: nationalTeamsBody ? parseEntryCalls(nationalTeamsBody) : [],
  };
});

console.error(`Parsed ${players.length} players`);

function sqlStringLiteral(s) {
  return "'" + s.replace(/'/g, "''") + "'";
}

function jsonbLiteral(value) {
  const json = JSON.stringify(value);
  return sqlStringLiteral(json) + '::jsonb';
}

const rows = players.map((p, i) => {
  const cols = [
    sqlStringLiteral(p.id),
    sqlStringLiteral(p.answer),
    jsonbLiteral(p.acceptedAnswers),
    p.position ? sqlStringLiteral(p.position) : 'null',
    jsonbLiteral(p.clubCareer),
    jsonbLiteral(p.nationalTeams),
    String(i + 1),
  ];
  return '(' + cols.join(', ') + ')';
});

const sql = `-- ============================================================================
-- Adivinhe o Jogador — dataset de carreiras. Rode no SQL Editor do Supabase.
-- A tabela vira a fonte da verdade; o app cai no banco local
-- (const careerPlayers) se a tabela estiver vazia ou sem rede. Leitura é
-- pública; escrita só pelo dashboard/admin. Nunca reaproveitar um \`id\`
-- pra outro jogador (progresso do usuário é rastreado por id).
-- ============================================================================

create table if not exists public.career_players (
  id text primary key,
  answer text not null,
  accepted_answers jsonb not null default '[]'::jsonb,
  position text,
  club_career jsonb not null,
  national_teams jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.career_players enable row level security;

drop policy if exists "read career players" on public.career_players;
create policy "read career players" on public.career_players
  for select using (true);

insert into public.career_players (id, answer, accepted_answers, position, club_career, national_teams, sort_order) values
${rows.join(',\n')}
on conflict (id) do nothing;
`;

console.log(sql);
