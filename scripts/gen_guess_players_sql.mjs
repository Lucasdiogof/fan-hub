import { readFileSync } from 'node:fs';

const src = readFileSync(
  'lib/features/arena/games/guess_player/data/guess_player_catalog.dart',
  'utf8',
);

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
  const matches = [...s.matchAll(/'((?:[^'\\]|\\.)*)'/g)];
  return matches.map((m) => m[1]);
}

function extractNamedArg(parts, name) {
  const prefix = name + ':';
  const found = parts.find((p) => p.trim().startsWith(prefix));
  if (found === undefined) return null;
  return found.trim().slice(prefix.length).trim();
}

// Extract each top-level `GuessPlayer(...)` / `const GuessPlayer(...)` entry.
const arrayStart = src.indexOf('final guessPlayerCatalog = <GuessPlayer>[');
const openBracket = src.indexOf('[', arrayStart);
const closeBracket = findMatchingBracket(src, openBracket, '[', ']');
const arrayBody = src.slice(openBracket + 1, closeBracket);
const entryCalls = splitTopLevel(arrayBody).filter((c) => c.includes('GuessPlayer('));

const players = entryCalls.map((call, index) => {
  const openParen = call.indexOf('(');
  const closeParen = findMatchingBracket(call, openParen, '(', ')');
  const inner = call.slice(openParen + 1, closeParen);
  const parts = splitTopLevel(inner);

  const id = unquote(extractNamedArg(parts, 'id'));
  const name = unquote(extractNamedArg(parts, 'name'));
  const displayName = unquote(extractNamedArg(parts, 'displayName'));
  const aliasesRaw = extractNamedArg(parts, 'aliases');
  const aliases = aliasesRaw ? parseQuotedListLiteral(aliasesRaw) : [];

  const positionRaw = extractNamedArg(parts, 'position');
  const position = positionRaw ? positionRaw.replace('PlayerPosition.', '').trim() : null;

  const shirtNumberRaw = extractNamedArg(parts, 'shirtNumber');
  const shirtNumber = shirtNumberRaw ? parseInt(shirtNumberRaw, 10) : null;

  const academyClubRaw = extractNamedArg(parts, 'academyClub');
  const academyClub = academyClubRaw ? unquote(academyClubRaw) : null;

  const nationalityCodeRaw = extractNamedArg(parts, 'nationalityCode');
  const nationalityCode = nationalityCodeRaw ? unquote(nationalityCodeRaw) : null;

  const nationalityNameRaw = extractNamedArg(parts, 'nationalityName');
  const nationalityName = nationalityNameRaw ? unquote(nationalityNameRaw) : null;

  const goiasDebutYearRaw = extractNamedArg(parts, 'goiasDebutYear');
  const goiasDebutYear = goiasDebutYearRaw ? parseInt(goiasDebutYearRaw, 10) : null;

  const imageUrlRaw = extractNamedArg(parts, 'imageUrl');
  let photoKey = null;
  if (imageUrlRaw) {
    const m = imageUrlRaw.match(/squadPhotoAssets\['([^']+)'\]/);
    if (!m) throw new Error(`${id}: unparseable imageUrl expression: ${imageUrlRaw}`);
    photoKey = m[1];
  }

  const dataStatusRaw = extractNamedArg(parts, 'dataStatus');
  const dataStatus = dataStatusRaw
    ? dataStatusRaw.replace('GuessPlayerDataStatus.', '').trim()
    : 'incomplete';

  if (!id || !name || !displayName) {
    throw new Error(`entry #${index}: missing id/name/displayName`);
  }

  return {
    id,
    name,
    displayName,
    aliases,
    position,
    shirtNumber,
    academyClub,
    nationalityCode,
    nationalityName,
    goiasDebutYear,
    photoKey,
    dataStatus,
  };
});

console.error(`Parsed ${players.length} players`);

function sqlStringLiteral(s) {
  return "'" + s.replace(/'/g, "''") + "'";
}

function jsonbLiteral(value) {
  return sqlStringLiteral(JSON.stringify(value)) + '::jsonb';
}

const rowsSql = players.map((p, i) => {
  const cols = [
    sqlStringLiteral(p.id),
    sqlStringLiteral(p.name),
    sqlStringLiteral(p.displayName),
    jsonbLiteral(p.aliases),
    p.position ? sqlStringLiteral(p.position) : 'null',
    p.shirtNumber !== null ? String(p.shirtNumber) : 'null',
    p.academyClub ? sqlStringLiteral(p.academyClub) : 'null',
    p.nationalityCode ? sqlStringLiteral(p.nationalityCode) : 'null',
    p.nationalityName ? sqlStringLiteral(p.nationalityName) : 'null',
    p.goiasDebutYear !== null ? String(p.goiasDebutYear) : 'null',
    p.photoKey ? sqlStringLiteral(p.photoKey) : 'null',
    sqlStringLiteral(p.dataStatus),
    String(i + 1),
  ];
  return '(' + cols.join(', ') + ')';
});

const sql = `-- ============================================================================
-- Quem Vestiu o Manto — catálogo de jogadores. Rode no SQL Editor do
-- Supabase. A tabela vira a fonte da verdade; o app cai no banco local
-- (const guessPlayerCatalog) se a tabela estiver vazia ou sem rede. Leitura
-- é pública; escrita só pelo dashboard/admin. \`photo_key\` guarda só a
-- chave de \`squadPhotoAssets\` (só o elenco atual tem foto) — a URL real
-- continua resolvida no Flutter, nunca duplicada aqui. Nunca reaproveitar
-- um \`id\` pra outro jogador (progresso do usuário é rastreado por id).
-- ============================================================================

create table if not exists public.guess_players (
  id text primary key,
  name text not null,
  display_name text not null,
  aliases jsonb not null default '[]'::jsonb,
  position text,
  shirt_number int,
  academy_club text,
  nationality_code text,
  nationality_name text,
  goias_debut_year int,
  photo_key text,
  data_status text not null default 'incomplete' check (data_status in ('verified','review','incomplete')),
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.guess_players enable row level security;

drop policy if exists "read guess players" on public.guess_players;
create policy "read guess players" on public.guess_players
  for select using (true);

insert into public.guess_players (id, name, display_name, aliases, position, shirt_number, academy_club, nationality_code, nationality_name, goias_debut_year, photo_key, data_status, sort_order) values
${rowsSql.join(',\n')}
on conflict (id) do nothing;
`;

console.log(sql);
