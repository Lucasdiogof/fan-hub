// Parser reproduzível da tabela "todos os jogos" da rede oGol/ZeroZero.
// Aceita tanto ogol.com.br/equipe/.../todos-os-jogos quanto o espelho
// zerozero.pt/equipa/.../jogos. A estrutura das linhas e os IDs de partida
// são compartilhados entre os domínios. Uso:
//   node parse_ogol_matches.mjs <arquivo.html>
//
// Regras críticas:
//   - cada linha de partida é uma <tr data-lj="h2" id="..." class="parent">;
//   - a data LOCAL exibida na coluna é a autoridade de calendário;
//   - a data embutida no href pode estar +1 dia em jogos noturnos e é
//     preservada só como auditoria (`source_url_date`/`date_href_mismatch`);
//   - mandante/visitante são derivados da ordem dos times no slug do jogo;
//   - o placar segue sempre a ordem mandante-visitante;
//   - links com class="prol" (prorrogação/pênaltis) não podem ser descartados.
import fs from 'fs';

const ROW_RE = /<tr data-lj="h2" id="(\d+)" class="parent">([\s\S]*?)<\/tr>/g;
const DATE_RE = /<td class="double"\s*>(\d{4}-\d{2}-\d{2})<\/td>/;
const TIME_RE = /<td class="double"\s*>\d{4}-\d{2}-\d{2}<\/td><td>(\d{2}:\d{2})<\/td>/;
const HOME_AWAY_MARK_RE = /<td>\((C|F)\)<\/td>/;
const ABS = '(?:https?:\\/\\/[^"\\s]+)?';
// `equipe` no Brasil; `equipa` em Portugal. O id numérico do clube pode ou
// não aparecer antes de ?epoca_id=.
const OPPONENT_RE = new RegExp(`<a href="${ABS}\\/(?:equipe|equipa)\\/([a-z0-9-]+)(?:\\/(\\d+))?\\?epoca_id=\\d+">([^<]+)<\\/a>`);
// Jogos decididos na prorrogação/pênaltis podem ter atributos extras antes
// do href (ex.: `<a class="prol" href="...">`).
const RESULT_RE = new RegExp(`<a\\s+(?:\\w+="[^"]*"\\s+)*href="(${ABS})\\/jogo\\/(\\d{4}-\\d{2}-\\d{2})-([a-z0-9-]+)\\/(\\d+)">([^<]*)(?:<span>\\(([^)]*)\\)<\\/span>)?<\\/a>`);
const COMPETITION_RE = new RegExp(`<a href="${ABS}\\/edicao\\/([a-z0-9-]+)-(\\d{4})\\/(\\d+)">([^<]+)<\\/a>`);

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

    if (!dateMatch || !resultMatch) continue;

    const displayedDate = dateMatch[1];
    const [, sourceOriginRaw, resultDate, homeAwaySlug, matchId, scoreRaw, penaltyRaw] = resultMatch;
    const sourceOrigin = sourceOriginRaw || '';
    const homeIsClub = homeAwaySlug.startsWith(`${teamSlug}-`) || homeAwaySlug === teamSlug;
    const awayIsClub = homeAwaySlug.endsWith(`-${teamSlug}`) || homeAwaySlug === teamSlug;

    const opponentName = opponentMatch ? decodeEntities(opponentMatch[3]) : null;
    const score = scoreRaw && /^\d+-\d+$/.test(scoreRaw.trim())
      ? scoreRaw.trim().split('-').map(Number)
      : null;
    const penalties = penaltyRaw && /^\d+-\d+\s*Pen\.?$/i.test(penaltyRaw.trim())
      ? penaltyRaw.trim().split(/\s+/)[0].split('-').map(Number)
      : null;

    matches.push({
      source: sourceOrigin.includes('zerozero.pt') ? 'zerozero' : 'ogol',
      source_match_id: matchId,
      ogol_internal_id: ogolMatchId,
      date: displayedDate,
      source_url_date: resultDate,
      date_href_mismatch: displayedDate !== resultDate,
      time: timeMatch ? timeMatch[1] : null,
      home_away_marker: markMatch ? markMatch[1] : null,
      club_is_home: homeIsClub && !awayIsClub ? true : awayIsClub && !homeIsClub ? false : null,
      opponent: opponentName,
      home_score: score?.[0] ?? null,
      away_score: score?.[1] ?? null,
      penalty_home_score: penalties?.[0] ?? null,
      penalty_away_score: penalties?.[1] ?? null,
      competition_edition_slug: competitionMatch ? `${competitionMatch[1]}-${competitionMatch[2]}` : null,
      competition_display: competitionMatch ? decodeEntities(competitionMatch[4]) : null,
      source_url: `${sourceOrigin || 'https://www.ogol.com.br'}/jogo/${resultDate}-${homeAwaySlug}/${matchId}`,
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
    const dateAudit = mt.date_href_mismatch ? ` hrefDate=${mt.source_url_date}` : '';
    console.log(
      `${mt.date}${dateAudit} ${mt.time ?? '--:--'} [${mt.competition_display}] ${mt.club_is_home ? teamSlug : mt.opponent} ${mt.home_score ?? '-'}x${mt.away_score ?? '-'} ${mt.club_is_home ? mt.opponent : teamSlug} (id=${mt.source_match_id}, marker=${mt.home_away_marker})`,
    );
  }
}
