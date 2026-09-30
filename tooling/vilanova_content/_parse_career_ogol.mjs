// Parser do bloco "HISTÓRICO"/"TRANSFERÊNCIAS" do ogol.com.br (texto colado
// do innerText da página, já recortado entre 'HISTÓRICO' e 'RETROSPECTO')
// pra gerar club_history no formato usado pelo squad_current.json/app.
//
// Regras:
//  - Ignora linhas de categoria de base/reserva ([S15]..[S23], [B]) — o
//    projeto já só lista clubes do futebol profissional sênior no
//    club_history (confirmado comparando com os dados já existentes de
//    Dalberson/Anderson Jesus).
//  - "(E)\n[Clube Pai]" = empréstimo; o clube que aparece é o time em que
//    jogou (cedido), o [Clube Pai] vai pra nota.
//  - Linhas consecutivas do MESMO clube (adjacentes na lista, sem outro
//    clube sênior no meio) viram um único período; soma J/G quando todas
//    as temporadas mescladas têm número, senão marca 'partial'.
//  - ogol só dá precisão de ANO (ou "2021/22" pra temporadas européias) —
//    nunca mês; period fica só em anos, diferente do formato mês/ano usado
//    nos dados antigos do Goiás.
import fs from 'fs';

// Máquina de estados linha a linha — o innerText do ogol NÃO separa
// registros de forma regular (a linha de estatísticas "J\tG\tASS" também
// começa colada, então um split por "linha que começa com tab" corta no
// lugar errado). Cada registro é, na ordem: [linha de temporada ou
// continuação em branco] -> linha do time (+ "(E)" se empréstimo) -> 0+
// linhas "[tag]" -> linha final "J\tG\tASS".
function parseHistorico(raw) {
  const text = raw;
  const tableStart = text.indexOf('TEMPORADA\tEQUIPE\tJ\tG\tASS');
  const transfersStart = text.indexOf('TRANSFERÊNCIAS');
  const body = text.slice(
    tableStart === -1 ? 0 : tableStart + 'TEMPORADA\tEQUIPE\tJ\tG\tASS'.length,
    transfersStart === -1 ? undefined : transfersStart,
  );
  const lines = body.split('\n').map((l) => l.trim());

  const rows = [];
  let currentSeason = null;
  let pendingTeam = null;
  let pendingLoan = false;
  let pendingTags = [];

  function flushIfComplete(jStr, gStr, assStr) {
    if (pendingTeam == null) return;
    const isYouth = pendingTags.some((t) => /^S\d+$/.test(t) || t === 'B');
    const parent = pendingTags.find((t) => !/^S\d+$/.test(t) && t !== 'B') || null;
    rows.push({
      season: currentSeason,
      team: pendingTeam,
      loan: pendingLoan,
      parent,
      isYouth,
      appearances: jStr === '-' ? null : Number(jStr),
      goals: gStr === '-' ? null : Number(gStr),
    });
    pendingTeam = null;
    pendingLoan = false;
    pendingTags = [];
  }

  for (const line of lines) {
    if (!line) continue; // "continuação" de mesma temporada, sem info nova
    const seasonOnly = line.match(/^(\d{4}(?:\/\d{2})?)$/);
    if (seasonOnly) {
      currentSeason = seasonOnly[1];
      continue;
    }
    const statsLine = line.match(/^(-|\d+)\t(-|\d+)\t(-|\d+)$/);
    if (statsLine) {
      flushIfComplete(statsLine[1], statsLine[2], statsLine[3]);
      continue;
    }
    const bracket = line.match(/^\[(.+)\]$/);
    if (bracket) {
      pendingTags.push(bracket[1]);
      continue;
    }
    // linha de time, possivelmente "Time\t<J>\t<G>\t<ASS>" tudo junto
    // (acontece quando não há linha de tag entre o time e os números)
    const teamWithStats = line.match(/^(.*?)\t(-|\d+)\t(-|\d+)\t(-|\d+)$/);
    if (teamWithStats) {
      pendingLoan = /\(E\)$/.test(teamWithStats[1]);
      pendingTeam = teamWithStats[1].replace(/\(E\)$/, '').trim();
      flushIfComplete(teamWithStats[2], teamWithStats[3], teamWithStats[4]);
      continue;
    }
    // só o nome do time, números vêm em linha futura
    pendingLoan = /\(E\)$/.test(line);
    pendingTeam = line.replace(/\(E\)$/, '').trim();
    pendingTags = [];
  }
  return rows;
}

function mergeSpells(rows) {
  // rows vem do mais recente pro mais antigo (ordem do ogol). Categoria de
  // base/reserva NÃO é descartada (o padrão já existente no
  // squad_current.json mantém "Clube (base)", ex.: Gabriel Átila e Samuel)
  // — só vira uma entry separada da passagem sênior do mesmo clube, nunca
  // mesclada com ela.
  const groupKey = (r) => r.team + (r.isYouth ? ' (base)' : '');
  const groups = [];
  for (const row of rows) {
    const key = groupKey(row);
    const last = groups[groups.length - 1];
    if (last && last.key === key) {
      last.rows.push(row);
    } else {
      groups.push({ key, team: groupKey(row), rows: [row] });
    }
  }
  // cada group -> 1 entry
  const entries = groups.map((g) => {
    const seasons = g.rows.map((r) => r.season).filter(Boolean);
    const first = seasons[seasons.length - 1]; // mais antiga (rows vieram desc)
    const last = seasons[0]; // mais recente
    const period = first === last || !last ? first : `${first}–${last}`;
    const anyMissing = g.rows.some((r) => r.appearances == null);
    const allMissing = g.rows.every((r) => r.appearances == null);
    const appearances = allMissing
      ? null
      : g.rows.reduce((acc, r) => acc + (r.appearances || 0), 0);
    const goals = allMissing
      ? null
      : g.rows.reduce((acc, r) => acc + (r.goals || 0), 0);
    const loan = g.rows.some((r) => r.loan);
    const parent = g.rows.find((r) => r.parent)?.parent || null;
    let notes = null;
    if (anyMissing && !allMissing) {
      notes = 'Totais incompletos: alguma(s) temporada(s) sem J/G na tabela consultada.';
    } else if (allMissing) {
      notes = 'Passagem identificada; totais não exibidos na tabela consultada.';
    }
    if (loan && parent) {
      notes = (notes ? notes + ' ' : '') + `Emprestado por ${parent}.`;
    }
    return {
      period,
      team: g.team,
      appearances,
      goals,
      loan,
      data_quality: allMissing || anyMissing ? 'partial' : 'verified',
      notes,
    };
  });
  // volta pra ordem cronológica (mais antigo primeiro), igual ao padrão
  // já usado no squad_current.json
  return entries.reverse();
}

const RAW_DIR = process.argv[2];
const OUT_PATH = process.argv[3];
if (!RAW_DIR || !OUT_PATH) {
  console.error('uso: node _parse_career_ogol.mjs <dir com .txt por jogador> <saida.json>');
  process.exit(1);
}

const files = fs.readdirSync(RAW_DIR).filter((f) => f.endsWith('.txt'));
const result = {};
for (const file of files) {
  const id = file.replace(/\.txt$/, '');
  const raw = fs.readFileSync(`${RAW_DIR}/${file}`, 'utf8');
  const rows = parseHistorico(raw);
  const entries = mergeSpells(rows);
  result[id] = entries;
}
fs.writeFileSync(OUT_PATH, JSON.stringify(result, null, 2), 'utf8');
console.log(`Gerado ${OUT_PATH} com ${Object.keys(result).length} jogadores.`);
