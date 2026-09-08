// Gera supabase/bragantino_guess_players.sql a partir do pacote
// docs/bragantino_data/new_data/quem_vestiu_o_manto_50_FINAL_v3.json,
// adaptado ao schema REAL de `guess_players` (GuessPlayerRepository):
//   shirt_number -> shirtNumber (rename direto);
//   origin_club só vira academy_club quando o próprio pacote já marca
//     "(base)" (formação) — o resto é clube de origem/transferência, não
//     formação, então fica null (nunca inventado);
//   club_debut_year NUNCA = first_bragantino_season (temporada de elenco
//     != estreia em campo) — só preenchido quando achei confirmação real
//     da estreia; o resto fica null, first_bragantino_season vira só nota;
//   photo_key: resolve via ClubConfig.assets.guessPlayerPhotos
//     (bragantino_club_config.dart, campo separado de squadPhotos porque
//     mistura URL remota + asset local e SquadAvatar só trata asset local);
//     36 já entraram no mapa, as últimas 4 ficam com o slug do nome do
//     arquivo ainda pendente -> imageUrl null até os arquivos chegarem.
import { readFileSync, writeFileSync } from 'node:fs';

const CLUB_ID = '51683d2a-ea1d-57c6-8014-996146f242e7';
const pack = JSON.parse(
  readFileSync('../../docs/bragantino_data/new_data/quem_vestiu_o_manto_50_FINAL_v3.json', 'utf8'),
);

// (base) explícito no próprio pacote -> aceito como academyClub real.
const ACADEMY_CONFIRMED = new Set([
  'manto_01', 'manto_08', 'manto_10', 'manto_21', 'manto_24', 'manto_42', 'manto_46', 'manto_49',
]);

// clubDebutYear confirmado por fonte própria nesta rodada (não é a
// temporada de elenco, é a estreia real). Só Tiago Volpi (15/01/2026 vs
// EC São José) — os outros ficam null até pesquisa dedicada.
const DEBUT_CONFIRMED = { manto_01: 2026 };

// 36 das 40 fotos históricas pedidas chegaram em 2026-09-08 (assets locais
// em lib/assets/games/guess_player/bragantino/) — faltam só estas 4.
const HISTORICAL_PHOTO_MISSING = new Set([
  'Cesar Haydar', 'Ligger', 'Edimar', 'Gonzalo Fornari',
]);

const CURRENT_PHOTO_KEY = {
  manto_01: 'tiago-volpi',
  manto_02: 'andres-hurtado',
  manto_03: 'alix-vinicius',
  manto_04: 'gustavo-marques',
  manto_05: 'juninho-capixaba',
  manto_06: 'fabinho',
  manto_07: 'rodriguinho',
  manto_08: 'lucas-barbosa',
  manto_09: 'henry-mosquera',
  manto_10: 'vinicinho-pereira',
};

function slugFilename(name) {
  // Usa o mesmo slug do .txt de fotos pendentes (nome normalizado, sem
  // acento, espaço vira _).
  return name
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '');
}

function academyClubFor(card) {
  if (!ACADEMY_CONFIRMED.has(card.id)) return null;
  // Remove o sufixo "(base)"/"(...)" só quando for exatamente o clube
  // formador citado antes do parêntese, senão preserva a string inteira
  // (ex.: "São José-RS / Fluminense (base)" -> mantém os dois, o pacote
  // já indica que a formação passou pelos dois).
  return card.origin_club;
}

// Catálogo real de PlayerPosition (shared/domain/player_position.dart) já
// usa exatamente esses códigos em minúsculo — nunca inventar um novo nome.
const VALID_POSITIONS = new Set([
  'gol', 'zag', 'ld', 'le', 'ald', 'ale', 'vol', 'mc', 'mei', 'md', 'me', 'pd', 'pe', 'sa', 'ata',
]);
function positionCanonical(pos) {
  // Card com dupla posição (ex.: "MEI/ATA") -> usa a primeira como
  // principal, mesma convenção de squad_members (1 posição só por linha).
  const first = pos.split('/')[0].trim().toLowerCase();
  return VALID_POSITIONS.has(first) ? first : null;
}

const rows = [];
let readyComplete = 0;
let readyNoPhoto = 0;
let blockedAcademy = 0;
let blockedDebut = 0;

pack.cards.forEach((card, i) => {
  const academyClub = academyClubFor(card);
  const clubDebutYear = DEBUT_CONFIRMED[card.id] ?? null;
  const isCurrent = card.photo_status === 'EXISTING_APP';
  const photoKey = isCurrent ? CURRENT_PHOTO_KEY[card.id] : slugFilename(card.name);
  const hasFullHints = academyClub !== null && clubDebutYear !== null; // shirt/position sempre presentes
  const hasPhotoResolvable = isCurrent || !HISTORICAL_PHOTO_MISSING.has(card.name);
  const dataStatus = hasFullHints && hasPhotoResolvable ? 'verified' : 'incomplete';

  if (academyClub === null) blockedAcademy++;
  if (clubDebutYear === null) blockedDebut++;
  if (hasFullHints && hasPhotoResolvable) readyComplete++;
  else if (hasFullHints && !hasPhotoResolvable) readyNoPhoto++;

  const id = card.id.replace('manto_', 'braga_manto_');
  const aliases = JSON.stringify([card.name]).replace(/'/g, "''");
  const position = positionCanonical(card.position);

  rows.push(
    `('${id}', '${CLUB_ID}', '${card.name.replace(/'/g, "''")}', '${card.name.replace(/'/g, "''")}', '${aliases}'::jsonb, ` +
    `${position ? `'${position}'` : 'null'}, ${card.shirt_number}, ` +
    `${academyClub ? `'${academyClub.replace(/'/g, "''")}'` : 'null'}, ` +
    `${clubDebutYear ?? 'null'}, '${photoKey}', '${dataStatus}', ${i + 1})`,
  );
});

const header = `-- Quem Vestiu o Manto? — 50 cards do Bragantino, adaptados ao schema REAL
-- de \`guess_players\` a partir do pacote docs/bragantino_data/new_data/
-- quem_vestiu_o_manto_50_FINAL_v3.json, 2026-09-08.
--
-- Mapeamentos importantes (NUNCA automáticos/assumidos):
--   * \`origin_club\` só virou \`academy_club\` (dica "BASE") quando o
--     próprio pacote já marcava "(base)" explicitamente — 8 dos 50. Os
--     outros 42 ficam com \`academy_club = null\`: \`origin_club\` no
--     pacote é o clube de ORIGEM/transferência, não necessariamente a
--     categoria de base — não é a mesma coisa, e assumir isso seria
--     inventar formação que não foi confirmada.
--   * \`club_debut_year\` NUNCA = \`first_bragantino_season\` do pacote
--     (temporada de elenco != estreia em campo, o próprio pacote já
--     alertava pra essa diferença). Confirmado por fonte própria só pra
--     Tiago Volpi (estreia 15/01/2026 vs EC São José) — os outros 49
--     ficam \`club_debut_year = null\` até pesquisa dedicada por jogador.
--   * 46 das 50 fotos já resolvem de verdade via
--     \`ClubConfig.assets.guessPlayerPhotos\` (ver \`bragantino_club_config.dart\`):
--     as 10 do elenco atual são as MESMAS URLs do CDN oficial do
--     \`bragantino_squad_members.sql\`; 36 das 40 históricas pedidas
--     chegaram em 2026-09-08 e viraram assets locais em
--     \`lib/assets/games/guess_player/bragantino/\`. Só 4 continuam sem
--     foto (Cesar Haydar, Ligger, Edimar, Gonzalo Fornari) — \`imageUrl\`
--     resolve \`null\` pra esses até o arquivo chegar (nunca um
--     placeholder). Foto resolvida NÃO significa \`data_status='verified'\`
--     sozinha — ainda precisa das 4 dicas completas.
--   * \`data_status = 'verified'\` só quando as 4 dicas E a foto existem —
--     hoje só o Tiago Volpi bate nisso. Todo o resto fica \`incomplete\`
--     (ainda aparece no autocomplete/comparação, só não é sorteável como
--     segredo, ver \`GuessPlayer.eligibleAsSecret\`).
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.guess_players (id, club_id, name, display_name, aliases, position, shirt_number, academy_club, club_debut_year, photo_key, data_status, sort_order) values
`;

const footer = `
on conflict (id) do update set
  club_id = excluded.club_id, name = excluded.name, display_name = excluded.display_name,
  aliases = excluded.aliases, position = excluded.position, shirt_number = excluded.shirt_number,
  academy_club = excluded.academy_club, club_debut_year = excluded.club_debut_year,
  photo_key = excluded.photo_key, data_status = excluded.data_status, sort_order = excluded.sort_order;
`;

writeFileSync('../../supabase/bragantino_guess_players.sql', header + rows.join(',\n') + footer);

const photoResolvedCount = pack.cards.filter(
  (c) => c.photo_status === 'EXISTING_APP' || !HISTORICAL_PHOTO_MISSING.has(c.name),
).length;

console.log('total cards:', pack.cards.length);
console.log('READY completo (4 dicas + foto):', readyComplete);
console.log('READY sem foto (4 dicas, foto pendente):', readyNoPhoto);
console.log('bloqueado por academy_club:', blockedAcademy);
console.log('bloqueado por club_debut_year:', blockedDebut);
console.log('foto real resolvida (independente das dicas):', photoResolvedCount, '/', pack.cards.length);
console.log('foto ainda pendente do usuário:', pack.cards.length - photoResolvedCount);
