// Extrai a escalação (titulares + reservas, com camisa e nome) embutida na
// própria ficha de partida do oGol (`id="game_report"`) — não precisa de
// nenhuma request nova além da já feita pra `parse_ogol_matches.mjs`
// (mesma página, seção mais pra baixo no HTML). Uso:
//   node parse_ogol_lineup.mjs <arquivo.html>
//
// Estrutura da fonte (documentado pra poder auditar/corrigir no futuro):
//   - `<div class="zz-tpl-row game_report">` — 1 linha com 2 colunas
//     (`zz-tpl-col is-6 fl-c`), uma por time; a 1ª linha é sempre a
//     titular, uma 2ª linha com `class="zz-tpl-row game_report mt"` traz
//     os reservas (mesma estrutura de coluna por time).
//   - cada coluna abre com `<div class="subtitle">` = nome do time (nas
//     linhas de reservas o subtitle costuma ser "Reservas", não repete o
//     nome do time — por isso o nome do time vem sempre da linha de
//     titulares, nunca da de reservas).
//   - cada jogador é um `<div class="player fl-r-cen">` (titular) ou
//     `<div class="player inactive fl-r-cen">` (reserva — a classe extra
//     "inactive" é o único sinal, o `subtitle` sozinho não basta já que
//     nem sempre diz "Reservas" de forma previsível em times menores).
//   - camisa: texto do `<div class="number ...">` (às vezes com
//     `data-player-id="<id>"` — visto ausente em algumas fichas, então o
//     id fica `null` nesses casos, nunca inventado); nome:
//     `<a href="/jogador/<slug>/<id>">Nome</a>` dentro do mesmo bloco.
//   - CRÍTICO pro "onze inicial" de verdade: a linha de titulares na
//     verdade lista todo mundo que ENTROU EM CAMPO (titulares + reservas
//     que jogaram), não só quem começou — reservas que nunca entraram é
//     que ficam de fora, na linha separada "Reservas". Quem veio do banco
//     tem um evento com `title="Entrou"` (`<span class="icn_zerozero
//     grey">7</span>`) na minuta que entrou; titulares nunca têm esse
//     evento (só "Saiu", ícone "8", quando são substituídos). Sem checar
//     isso, TODOS os jogadores que jogaram (18+) apareceriam como
//     "titulares", inflando o onze inicial de verdade.
import fs from 'fs';

function decodeEntities(str) {
  return str
    .replace(/&aacute;/g, 'á').replace(/&eacute;/g, 'é').replace(/&iacute;/g, 'í')
    .replace(/&oacute;/g, 'ó').replace(/&uacute;/g, 'ú').replace(/&atilde;/g, 'ã')
    .replace(/&otilde;/g, 'õ').replace(/&acirc;/g, 'â').replace(/&ecirc;/g, 'ê')
    .replace(/&ocirc;/g, 'ô').replace(/&ccedil;/g, 'ç').replace(/&Aacute;/g, 'Á')
    .replace(/&Eacute;/g, 'É').replace(/&Oacute;/g, 'Ó').replace(/&Atilde;/g, 'Ã')
    .replace(/&Ccedil;/g, 'Ç').replace(/&amp;/g, '&').replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const SUBTITLE_RE = /<div class="subtitle">([^<]*)<\/div>/;
const NUMBER_RE = /<div class="number[^"]*"(?:\s+data-player-id="(\d+)")?[^>]*>(\d+)<\/div>/;
const NAME_RE = /<a href="\/jogador\/[^"]+\/\d+">([^<]+)<\/a>/;
const ENTERED_RE = /title="Entrou"/;

function splitColumns(rowHtml) {
  const idx = rowHtml.indexOf('<div class="zz-tpl-col is-6 fl-c">');
  if (idx === -1) return [rowHtml];
  const rest = rowHtml.slice(idx);
  return rest.split('<div class="zz-tpl-col is-6 fl-c">').filter(Boolean);
}

function parseColumn(colHtml) {
  const subtitleMatch = SUBTITLE_RE.exec(colHtml);
  const subtitle = subtitleMatch ? subtitleMatch[1].trim() : null;

  const chunks = colHtml.split('<div class="player').slice(1);
  const players = [];
  for (const chunk of chunks) {
    const numberMatch = NUMBER_RE.exec(chunk);
    const nameMatch = NAME_RE.exec(chunk);
    if (!numberMatch || !nameMatch) continue; // linha não é um jogador de verdade (raro, defensivo)
    const decodedName = decodeEntities(nameMatch[1]);
    const captain = /\(C\)\s*$/.test(decodedName);
    players.push({
      inactive: chunk.trimStart().startsWith('inactive'),
      enteredAsSubstitute: ENTERED_RE.test(chunk),
      player_id: numberMatch[1] ?? null,
      number: Number(numberMatch[2]),
      name: captain ? decodedName.replace(/\s*\(C\)\s*$/, '') : decodedName,
      captain,
    });
  }
  return { subtitle, players };
}

/**
 * `starters`: só quem jogou desde o início de verdade (exclui reservas
 * usados — ver `usedSubstitutes` — e reservas que nunca entraram).
 * `usedSubstitutes`: veio do banco e jogou (tem evento "Entrou").
 * `unusedBench`: ficou no banco o jogo inteiro (nunca entrou).
 */
export function parseOgolLineup(html) {
  const gameReportIdx = html.indexOf('id="game_report"');
  if (gameReportIdx === -1) return null;
  // Janela generosa (uma escalação completa + reservas cabe bem dentro
  // disso) — corta antes da próxima seção "card-data" pra não vazar pro
  // resto da página.
  const nextSection = html.indexOf('<div class="card-data ">', gameReportIdx);
  const section = html.slice(
    gameReportIdx,
    nextSection === -1 ? gameReportIdx + 60000 : nextSection,
  );

  const rows = section.split('<div class="zz-tpl-row game_report');
  rows.shift(); // antes da 1ª row, lixo (o próprio </h2> etc.)

  let homeTeam = null;
  let awayTeam = null;
  const starters = { home: [], away: [] };
  const usedSubstitutes = { home: [], away: [] };
  const unusedBench = { home: [], away: [] };

  rows.forEach((rowHtml, rowIndex) => {
    const columns = splitColumns(rowHtml);
    columns.slice(0, 2).forEach((colHtml, colIndex) => {
      const { subtitle, players } = parseColumn(colHtml);
      const side = colIndex === 0 ? 'home' : 'away';
      if (rowIndex === 0 && subtitle) {
        if (side === 'home') homeTeam = subtitle;
        else awayTeam = subtitle;
      }
      for (const p of players) {
        const { inactive, enteredAsSubstitute, ...player } = p;
        if (inactive) unusedBench[side].push(player);
        else if (enteredAsSubstitute) usedSubstitutes[side].push(player);
        else starters[side].push(player);
      }
    });
  });

  return { homeTeam, awayTeam, starters, usedSubstitutes, unusedBench };
}

const isMain =
  process.argv[1] &&
  import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (isMain) {
  const file = process.argv[2];
  if (!file) {
    console.error('Uso: node parse_ogol_lineup.mjs <arquivo.html>');
    process.exit(1);
  }
  const html = fs.readFileSync(file, 'utf8');
  const lineup = parseOgolLineup(html);
  console.log(JSON.stringify(lineup, null, 2));
}
