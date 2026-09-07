// Curadoria do "Adivinhe a Escalação" do Bragantino: pega o pool do
// LINEUP_SHORTLIST_V2 e decide QUAIS partidas podem virar desafio no app,
// aplicando as regras de publicabilidade e depois um balanceamento.
//
// Uso:
//   node tooling/bragantino_lineup/select_challenges.mjs [--target 24]
//
// Saídas (em tooling/bragantino_lineup/out/):
//   eligibility_report.json — toda partida avaliada, com motivo de rejeição
//   selection.json          — as partidas escolhidas, já balanceadas
// E, quando houver ao menos 1 publicável:
//   supabase/bragantino_lineup_matches_seed.sql
//
// POR QUE hoje o resultado é 0 publicável: o contrato do jogo (ver
// `LineupMatchRepository._map`) exige uma FORMAÇÃO (pra gerar os 11 slots
// via FormationLayoutService) e uma POSIÇÃO por jogador. A ficha do oGol,
// que é a fonte do pool, não traz nenhum dos dois — nem no HTML já
// baixado (conferido). Inferir a formação pela ordem em que o oGol lista
// os titulares seria exatamente o "encaixe visual forçado" proibido: a
// ordem sugere GOL→defesa→meio→ataque, mas não diz quantos são de cada
// linha, então um zagueiro cairia desenhado no ataque. Assim que a
// pesquisa trouxer formação+posições, este script publica sem nenhuma
// mudança de código do app.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(__dirname, 'out');

/// Mesmo catálogo do app (`lib/features/squad/domain/position_groups.dart`
/// + os rótulos curtos usados no dataset do Goiás). Nenhuma nomenclatura
/// nova pro Bragantino.
export const CANONICAL_POSITIONS = [
  'GOL',
  'LD',
  'ZAG',
  'LE',
  'VOL',
  'MC',
  'MEI',
  'ATA',
];

/// Formações que o `FormationLayoutService` conhece de verdade. Uma
/// formação fora daqui cai num fallback genérico no app — pra publicar,
/// exigimos uma conhecida.
export const KNOWN_FORMATIONS = [
  '4-4-2',
  '4-3-3',
  '3-5-2',
  '4-2-3-1',
  '4-1-2-1-2',
  '5-3-2',
  '3-4-3',
  '4-5-1',
];

export const REJECTION = {
  notEleven: 'XI_INCOMPLETO',
  missingFormation: 'SEM_FORMACAO',
  unknownFormation: 'FORMACAO_DESCONHECIDA',
  missingPositions: 'SEM_POSICAO_POR_JOGADOR',
  invalidPosition: 'POSICAO_FORA_DO_CATALOGO',
  formationMismatch: 'POSICOES_NAO_BATEM_COM_A_FORMACAO',
  missingAnswer: 'SEM_NOME_PARA_RESPOSTA',
};

/// Decide se UMA partida do pool pode virar desafio. Nunca "conserta" o
/// que falta — devolve o motivo e deixa a partida de fora.
export function evaluateMatch(match) {
  const reasons = [];
  const xi = match.starting_xi ?? [];

  if (xi.length !== 11) reasons.push(REJECTION.notEleven);

  const formation = match.formation ?? null;
  if (!formation) {
    reasons.push(REJECTION.missingFormation);
  } else if (!KNOWN_FORMATIONS.includes(formation)) {
    reasons.push(REJECTION.unknownFormation);
  }

  const withPosition = xi.filter((p) => p.position);
  if (withPosition.length !== xi.length) {
    reasons.push(REJECTION.missingPositions);
  } else if (!xi.every((p) => CANONICAL_POSITIONS.includes(p.position))) {
    reasons.push(REJECTION.invalidPosition);
  } else if (formation && KNOWN_FORMATIONS.includes(formation)) {
    // A ordem do XI precisa bater com as linhas da formação: 1 goleiro
    // primeiro e a contagem por linha igual à formação declarada.
    const lines = [1, ...formation.split('-').map(Number)];
    if (lines.reduce((a, b) => a + b, 0) !== 11) {
      reasons.push(REJECTION.formationMismatch);
    } else if (xi[0].position !== 'GOL') {
      reasons.push(REJECTION.formationMismatch);
    }
  }

  if (!xi.every((p) => p.name && p.name.trim().length > 0)) {
    reasons.push(REJECTION.missingAnswer);
  }

  return { publishable: reasons.length === 0, reasons };
}

/// Assinatura do XI pra medir repetição — duas partidas com o mesmo time
/// inteiro não devem virar dois desafios.
function lineupSignature(match) {
  return match.starting_xi
    .map((p) => p.name.toLowerCase())
    .sort()
    .join('|');
}

function overlap(a, b) {
  const setA = new Set(a.starting_xi.map((p) => p.name.toLowerCase()));
  const shared = b.starting_xi.filter((p) => setA.has(p.name.toLowerCase()));
  return shared.length / 11;
}

/// Escolhe até [target] partidas priorizando variedade — nunca só por
/// data. Pontua cada candidata pelo quanto ela ADICIONA de diversidade
/// (adversário/competição/ano/mando ainda pouco representados) e descarta
/// escalações quase idênticas às já escolhidas.
export function selectBalanced(publishable, { target = 24, maxOverlap = 0.8 } = {}) {
  const chosen = [];
  const seenSignatures = new Set();
  const count = { opponent: {}, competition: {}, year: {}, home: {} };
  const bump = (bucket, key) => {
    count[bucket][key] = (count[bucket][key] ?? 0) + 1;
  };
  const score = (m) => {
    const opponent = count.opponent[m.opponent] ?? 0;
    const competition = count.competition[m.competition] ?? 0;
    const year = count.year[m.calendar_year] ?? 0;
    const home = count.home[String(m.club_is_home)] ?? 0;
    // Quanto menos representado, melhor. Adversário pesa mais: repetir
    // competição é natural, repetir adversário empobrece o jogo.
    return opponent * 3 + competition + year + home * 0.5;
  };

  const remaining = [...publishable];
  while (chosen.length < target && remaining.length > 0) {
    remaining.sort((a, b) => score(a) - score(b));
    let picked = null;
    for (let i = 0; i < remaining.length; i++) {
      const candidate = remaining[i];
      const signature = lineupSignature(candidate);
      if (seenSignatures.has(signature)) continue;
      if (chosen.some((c) => overlap(c, candidate) > maxOverlap)) continue;
      picked = candidate;
      remaining.splice(i, 1);
      break;
    }
    if (!picked) break; // resto é repetição demais — para em vez de encher
    chosen.push(picked);
    seenSignatures.add(lineupSignature(picked));
    bump('opponent', picked.opponent);
    bump('competition', picked.competition);
    bump('year', picked.calendar_year);
    bump('home', String(picked.club_is_home));
  }
  return chosen;
}

function distribution(matches, key) {
  return matches.reduce((acc, m) => {
    const value = typeof key === 'function' ? key(m) : m[key];
    acc[value] = (acc[value] ?? 0) + 1;
    return acc;
  }, {});
}

function main() {
  const targetArg = process.argv.indexOf('--target');
  const target = targetArg > -1 ? Number(process.argv[targetArg + 1]) : 24;

  const poolPath = path.join(
    ROOT,
    'tooling/bragantino_passport/source/lineup_shortlist_v2.json',
  );
  const pool = JSON.parse(fs.readFileSync(poolPath, 'utf8'));
  const recent = pool.recent_lineups?.matches ?? [];
  const historical = pool.historical_lineups?.matches ?? [];
  const candidates = [...recent, ...historical];

  const evaluated = candidates.map((match) => ({
    source_match_id: match.source_match_id,
    date: match.date,
    competition: match.competition,
    opponent: match.opponent,
    category: match.category ?? 'RECENT',
    ...evaluateMatch(match),
  }));

  const publishable = candidates.filter(
    (m) => evaluateMatch(m).publishable,
  );
  const selection = selectBalanced(publishable, { target });

  const reasonCounts = {};
  for (const row of evaluated) {
    for (const reason of row.reasons) {
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.writeFileSync(
    path.join(OUT_DIR, 'eligibility_report.json'),
    JSON.stringify(
      {
        generated_at: new Date().toISOString(),
        pool_source: 'tooling/bragantino_passport/source/lineup_shortlist_v2.json',
        avaliadas: candidates.length,
        publicaveis: publishable.length,
        rejeitadas: candidates.length - publishable.length,
        motivos: reasonCounts,
        por_categoria: distribution(candidates, (m) => m.category ?? 'RECENT'),
        detalhe: evaluated,
      },
      null,
      2,
    ),
  );
  fs.writeFileSync(
    path.join(OUT_DIR, 'selection.json'),
    JSON.stringify(
      {
        generated_at: new Date().toISOString(),
        target,
        selecionadas: selection.length,
        por_ano: distribution(selection, 'calendar_year'),
        por_competicao: distribution(selection, 'competition'),
        por_adversario: distribution(selection, 'opponent'),
        por_mando: distribution(selection, (m) =>
          m.club_is_home ? 'mandante' : 'visitante',
        ),
        matches: selection,
      },
      null,
      2,
    ),
  );

  console.log(`avaliadas: ${candidates.length}`);
  console.log(`publicáveis: ${publishable.length}`);
  console.log(`rejeitadas: ${candidates.length - publishable.length}`);
  console.log('motivos:', reasonCounts);
  console.log(`selecionadas (alvo ${target}): ${selection.length}`);
  if (selection.length === 0) {
    console.log(
      '\nNenhum desafio publicável — NÃO gere seed nem ligue o jogo pro clube.',
    );
  }
}

const isMain =
  process.argv[1] &&
  import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (isMain) main();
