// Auditoria de TODAS as identidades de partida existentes no projeto —
// antes de desenhar canonical_match_id pra player_match_appearances.
// Não modifica nada, só lê e reporta. Achados vêm de leitura direta dos
// arquivos-fonte + do código do Worker (src/football/), não de suposição.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const OUT_DIR = path.join(DATA, 'player_reconciliation');

const passportMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'passport_matches.json'), 'utf8'));
const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));

// ---------------------------------------------------------------------------
// 1. Inventário de namespaces de ID — preenchido a partir de leitura direta
//    do código-fonte (src/football/*) e dos JSONs, nunca suposição.
// ---------------------------------------------------------------------------
const idNamespaces = [
  {
    source: 'passport_matches.json / public.passport_matches',
    idType: 'text opaco "pe_<hash16>" — fornecido pelo usuário no JSON de origem, NUNCA gerado por script deste repo',
    example: 'pe_cb52680435343cc4',
    stable: true,
    stableReason: 'README confirma: "que nunca muda numa reimportação" — reimportar o JSON faz UPDATE, nunca troca o id.',
    global: false,
    globalReason: 'Namespace isolado — não tem NENHUMA referência cruzada com lineup_matches.id nem com nenhum id de provider (OneFootball). Cada fonte tem seu próprio id sem ponte.',
    goiasSpecific: true,
    goiasSpecificReason: 'Schema é construído do ponto de vista do Goiás: goias_is_home, goias_score, opponent, opponent_score — não tem home_club_id/away_club_id simétricos. Um 2º clube que jogasse a MESMA partida não teria como apontar pra esta linha sem reinterpretar os campos.',
    servesAsCanonical: false,
    servesAsCanonicalReason: 'Estável, mas não é multi-clube-safe (goiasSpecific=true) — reutilizar direto criaria uma identidade de partida enviesada pro Goiás desde a fundação.',
  },
  {
    source: 'lineup_matches.json (Adivinhe a Escalação)',
    idType: 'slug legível "<temporada>_<oponente-slug>_<competição-código>_<fase-slug>", curado à mão',
    example: '2021_guarani_brB_acesso',
    stable: true,
    stableReason: 'Arquivo versionado no git, nunca regenerado por script — muda só se editado manualmente.',
    global: false,
    globalReason: 'Namespace PRÓPRIO, desconectado de passport_matches e de qualquer provider — confirmado por cross-check de (match_date, oponente): só 15 das 31 partidas batem 1:1 com uma linha de passport_matches por data+oponente; as outras 16 não têm par claro (10 delas têm match_date "-01-01", indício de dia-placeholder, não uma partida real de 1º de janeiro).',
    goiasSpecific: true,
    goiasSpecificReason: 'home_team/away_team são STRINGS de nome, sem club_id nenhum — e o dataset inteiro só existe porque é "escalação do Goiás", nunca pensado como partida de 2 clubes peers.',
    servesAsCanonical: false,
    servesAsCanonicalReason: 'Mesma limitação de passport_matches — estável dentro do próprio arquivo, mas não é uma identidade neutra de partida.',
  },
  {
    source: 'src/football/providers/onefootball_provider.ts (Worker, OneFootballMatchCard.matchId)',
    idType: 'string numérica própria do provider OneFootball',
    example: '(id interno do OneFootball, não exposto cru pro Flutter — o Worker prefixa "onef-<id>" antes de devolver)',
    stable: false,
    stableReason: 'Amarrado a UM provider específico — troca de provider troca o id inteiro. O próprio comentário do código diz: "id vem prefixado (onef-<id>) — o Flutter nunca precisa entender o prefixo".',
    global: false,
    globalReason: 'Cobre SÓ 1 competição por vez (ONEFOOTBALL_COMPETITION_SLUG fixo no wrangler.toml, hoje Brasileirão Série B) — não cobre Goiano/Copa do Brasil/Libertadores/etc., e não tem histórico (só partidas atuais/recentes do provider).',
    goiasSpecific: false,
    goiasSpecificReason: 'Tecnicamente é uma partida entre 2 times quaisquer (formato provider genérico), mas na prática o Worker só busca partidas do Goiás.',
    servesAsCanonical: false,
    servesAsCanonicalReason: 'Nem estável (amarrado a provider) nem coberto historicamente — inadequado como fundação, só serve pro "próximo jogo/últimos resultados" do momento.',
  },
  {
    source: 'src/football/normalize/match_lineup.ts + onefootball_provider.ts (jogador)',
    idType: 'NENHUM — só name/jerseyNumber/image.path',
    example: '{ name: "Fulano", jerseyNumber: 9, image: {...} }',
    stable: false,
    stableReason: 'Não existe id de jogador em lugar nenhum do tipo OneFootballLineupPlayer nem em OneFootballMatchEvent (goal.scorer/card.player/substitution.playerIn/playerOut — todos só {name}).',
    global: false, goiasSpecific: false,
    servesAsCanonical: false,
    servesAsCanonicalReason: 'N/A pra jogador — não existe ID nenhum a reaproveitar. Ver decisão sobre player_external_ids no relatório.',
  },
];

// ---------------------------------------------------------------------------
// 2. Cross-check real lineup_matches x passport_matches (data + oponente)
// ---------------------------------------------------------------------------
const crossCheck = [];
for (const m of lineupMatches) {
  const opponent = m.home_team === 'Goiás' ? m.away_team : m.home_team;
  const candidates = passportMatches.filter((p) => p.match_date === m.match_date && (p.opponent === opponent || p.home_team === opponent || p.away_team === opponent));
  const suspectPlaceholderDay = /-01$/.test(m.match_date);
  crossCheck.push({
    lineupMatchId: m.id,
    matchDate: m.match_date,
    opponent,
    passportMatchesCandidates: candidates.length,
    linkedPassportMatchId: candidates.length === 1 ? candidates[0].id : null,
    suspectPlaceholderDay,
  });
}
const linkedCount = crossCheck.filter((c) => c.linkedPassportMatchId).length;

const auditReport = {
  idNamespaces,
  crossCheckLineupVsPassport: crossCheck,
  linkedCount,
  unlinkedCount: crossCheck.length - linkedCount,
  totalLineupMatches: lineupMatches.length,
  totalPassportMatches: passportMatches.length,
};

fs.writeFileSync(path.join(OUT_DIR, 'match_identity_audit.json'), JSON.stringify(auditReport, null, 2) + '\n');
console.log(JSON.stringify({ linkedCount, unlinkedCount: auditReport.unlinkedCount, totalLineupMatches: lineupMatches.length, totalPassportMatches: passportMatches.length }, null, 2));
console.log('\nEscrito em:', path.join(OUT_DIR, 'match_identity_audit.json'));
