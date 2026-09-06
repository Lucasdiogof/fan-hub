// Parser reproduzível da tabela "todos os jogos" do oGol
// (ogol.com.br/equipe/<slug>/todos-os-jogos?compet_id_jogos=<id>&epoca_id=<id>)
// — extrai cada `<tr data-lj="h2" id="<oGolMatchId>" class="parent">` via
// regex sobre o HTML bruto (não precisa de DOM/browser: a tabela é
// HTML estático servido no primeiro load). Uso:
//   node parse_ogol_matches.mjs <arquivo.html>
//
// Documentado aqui de propósito pra poder auditar/corrigir no futuro sem
// re-descobrir a estrutura da fonte:
//   - a página é UTF-8 de verdade (`curl` sem tratamento especial já lê
//     certo) — só cuidado se salvar/reabrir o HTML com uma ferramenta que
//     tente "adivinhar" outro charset, aí vira mojibake (ex.: "GrÃªmio").
//   - cada linha de partida é uma <tr class="parent"> com, nesta ordem:
//     forma (V/E/D), data (YYYY-MM-DD), hora (HH:MM), marcador casa/fora
//     "(C)"/"(F)", crest+nome do ADVERSÁRIO, link de resultado
//     (/jogo/<data>-<slug-mandante>-<slug-visitante>/<id>) com o placar
//     como texto ("2-1"), e o nome da edição da competição
//     (/edicao/<slug>-<ano>/<id>) como texto ("Paulista 2025").
//   - mandante/visitante são derivados da ORDEM dos times no slug da URL
//     de resultado (sempre <mandante>-<visitante>), não do marcador
//     "(C)"/"(F)" (mantido só como campo de conferência cruzada).
//   - o placar do link de resultado ("2-0") está SEMPRE na mesma ordem
//     <mandante>-<visitante> (confirmado direto no HTML: mandante=Botafogo,
//     "2-0", Botafogo venceu de fato por 2-0) — nunca "time da página
//     primeiro". Um bug anterior aqui assumia essa segunda leitura pra
//     jogos fora de casa e invertia o placar; não reintroduzir.
import fs from 'fs';

const ROW_RE = /<tr data-lj="h2" id="(\d+)" class="parent">([\s\S]*?)<\/tr>/g;
const DATE_RE = /<td class="double"\s*>(\d{4}-\d{2}-\d{2})<\/td>/;
const TIME_RE = /<td class="double"\s*>\d{4}-\d{2}-\d{2}<\/td><td>(\d{2}:\d{2})<\/td>/;
const HOME_AWAY_MARK_RE = /<td>\((C|F)\)<\/td>/;
// Clubes grandes (Corinthians, Santos, São Paulo, Palmeiras...) têm URL
// SEM id numérico (`/equipe/corinthians`); os demais têm
// `/equipe/<slug>/<id>`. O `?epoca_id=` está sempre presente no link com
// texto visível (o primeiro `<a>` da linha só tem o `<img>`, sem texto).
const OPPONENT_RE = /<a href="\/equipe\/([a-z0-9-]+)(?:\/(\d+))?\?epoca_id=\d+">([^<]+)<\/a>/;
// Jogos decididos na prorrogação/pênaltis têm atributos extras antes do
// href (ex.: `<a class="prol" href="...">`) e um `<span>` com o placar da
// disputa de pênaltis depois do placar normal (ex.: "1-2<span>(5-4
// Pen.)</span>") — sem esses dois ajustes a partida inteira some do parse.
const RESULT_RE = /<a\s+(?:\w+="[^"]*"\s+)*href="\/jogo\/(\d{4}-\d{2}-\d{2})-([a-z0-9-]+)\/(\d+)">([^<]*)(?:<span>\(([^)]*)\)<\/span>)?<\/a>/;
const COMPETITION_RE = /<a href="\/edicao\/([a-z0-9-]+)-(\d{4})\/(\d+)">([^<]+)<\/a>/;

function decodeEntities(str) {
  return str
    .replace(/&aacute;/g, 'á').replace(/&eacute;/g, 'é').replace(/&iacute;/g, 'í')
    .replace(/&oacute;/g, 'ó').replace(/&uacute;/g, 'ú').replace(/&atilde;/g, 'ã')
    .replace(/&otilde;/g, 'õ').replace(/&acirc;/g, 'â').replace(/&ecirc;/g, 'ê')
    .replace(/&ocirc;/g, 'ô').replace(/&ccedil;/g, 'ç').replace(/&Aacute;/g, 'Á')
    .replace(/&Eacute;/g, 'É').replace(/&Oacute;/g, 'Ó').replace(/&Atilde;/g, 'Ã')
    .replace(/&Ccedil;/g, 'Ç').replace(/&amp;/g, '&').replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ');
}

/** Slug em minúsculas/sem acento (como aparece na URL) -> nome legível. Só
 * usado quando o texto do link do adversário não bate com o slug (raro) —
 * o texto do `<a>` já vem legível na maioria dos casos. */
function titleFromSlug(slug) {
  return slug.split('-').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

export function parseOgolTeamMatches(html, { teamSlug }) {
  const matches = [];
  let m;
  ROW_RE.lastIndex = 0;
  while ((m = ROW_RE.exec(html))) {
    const [, ogolMatchId, rowHtml] = m;
    const dateMatch = DATE_RE.exec(rowHtml);
    const timeMatch = TIME_RE.exec(rowHtml);
    const markMatch = HOME_AWAY_MARK_RE.exec(rowHtml);
    const opponentMatch = OPPONENT_RE.exec(rowHtml);
    const resultMatch = RESULT_RE.exec(rowHtml);
    const competitionMatch = COMPETITION_RE.exec(rowHtml);

    if (!dateMatch || !resultMatch) continue; // linha não é uma partida de verdade (raro, defensivo)

    const [, resultDate, homeAwaySlug, matchId, scoreRaw, penaltyRaw] = resultMatch;
    // slug do resultado é sempre "<mandante>-<visitante>" — o time da CASA
    // vem primeiro. `teamSlug` (ex.: "red-bull-bragantino") aparece nessa
    // posição quando o clube joga em casa.
    const homeIsClub = homeAwaySlug.startsWith(`${teamSlug}-`) || homeAwaySlug === teamSlug;
    const awayIsClub = homeAwaySlug.endsWith(`-${teamSlug}`) || homeAwaySlug === teamSlug;

    const opponentName = opponentMatch ? decodeEntities(opponentMatch[3]) : null;
    const score = scoreRaw && /^\d+-\d+$/.test(scoreRaw.trim()) ? scoreRaw.trim().split('-').map(Number) : null;
    // Mesma ordem <mandante>-<visitante> do placar normal (confirmado no
    // HTML bruto: mandante Corinthians, "5-4 Pen.", Corinthians venceu de
    // fato a disputa por 5-4 — ver imprensa externa, jogo de 21/08/2024).
    const penalties = penaltyRaw && /^\d+-\d+\s*Pen\.?$/i.test(penaltyRaw.trim())
      ? penaltyRaw.trim().split(/\s+/)[0].split('-').map(Number)
      : null;

    matches.push({
      source: 'ogol',
      source_match_id: matchId,
      ogol_internal_id: ogolMatchId,
      // A URL de resultado (`resultDate`) é a data real da partida — a
      // coluna "double" da tabela (`dateMatch`) pode vir 1 dia adiantada
      // pra jogos que começam perto da meia-noite (visto em 2 casos: este
      // aqui e um jogo do Bragantino contra o Flamengo em 2025). Usa
      // sempre `resultDate` pra não depender de redirect 301 do oGol.
      date: resultDate,
      time: timeMatch ? timeMatch[1] : null,
      home_away_marker: markMatch ? markMatch[1] : null, // 'C' ou 'F' — só conferência cruzada
      club_is_home: homeIsClub && !awayIsClub ? true : awayIsClub && !homeIsClub ? false : null,
      opponent: opponentName,
      home_score: score?.[0] ?? null,
      away_score: score?.[1] ?? null,
      penalty_home_score: penalties?.[0] ?? null,
      penalty_away_score: penalties?.[1] ?? null,
      competition_edition_slug: competitionMatch ? `${competitionMatch[1]}-${competitionMatch[2]}` : null,
      competition_display: competitionMatch ? decodeEntities(competitionMatch[4]) : null,
      source_url: `https://www.ogol.com.br/jogo/${resultDate}-${homeAwaySlug}/${matchId}`,
      raw_result_text: scoreRaw ? scoreRaw.trim() : null,
    });
  }
  return matches;
}

// CLI: node parse_ogol_matches.mjs <arquivo.html> [teamSlug]
const isMain = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (isMain) {
  const file = process.argv[2];
  const teamSlug = process.argv[3] ?? 'red-bull-bragantino';
  if (!file) {
    console.error('Uso: node parse_ogol_matches.mjs <arquivo.html> [teamSlug]');
    process.exit(1);
  }
  const html = fs.readFileSync(file, 'utf8');
  const matches = parseOgolTeamMatches(html, { teamSlug });
  console.log(`Encontradas ${matches.length} partidas em ${file}`);
  for (const mt of matches) {
    console.log(
      `${mt.date} ${mt.time ?? '--:--'} [${mt.competition_display}] ${mt.club_is_home ? teamSlug : mt.opponent} ${mt.home_score ?? '-'}x${mt.away_score ?? '-'} ${mt.club_is_home ? mt.opponent : teamSlug} (id=${mt.source_match_id}, marker=${mt.home_away_marker})`,
    );
  }
}
