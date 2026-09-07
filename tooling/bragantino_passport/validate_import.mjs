// Validação de IMPORTAÇÃO do Passaporte do Bragantino — roda sobre TODOS
// os lotes juntos (2024/2025/2026), não um ano isolado como o
// `validate_batch.mjs`. É o portão antes de aplicar qualquer seed no
// Supabase do clube.
//
//   node tooling/bragantino_passport/validate_import.mjs
//
// Nada aqui inventa ou "conserta" dado: quando algo não bate, falha e diz
// qual partida. Campos legitimamente desconhecidos (horário, estádio não
// confirmado, rodada) NÃO são erro — o que é erro é fingir que se sabe.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const SOURCE_DIR = path.join(ROOT, 'tooling/bragantino_passport/source');

const BRAGANTINO_CLUB_ID = '51683d2a-ea1d-57c6-8014-996146f242e7';
const CLUB_NAMES = [
  'RB Bragantino',
  'Bragantino',
  'Red Bull Bragantino',
  'Clube Atlético Bragantino',
  'Atlético Bragantino',
];

/// Qualquer rastro do Goiás no dataset é erro — nunca deve existir.
const GOIAS_MARKERS = [
  'goiás esporte clube',
  'goias esporte clube',
  'goiasec',
  'serrinha',
  'hailé pinheiro',
  'haile pinheiro',
];

const VALID_STATUS = ['FINISHED', 'SCHEDULED', 'POSTPONED', 'CANCELLED'];
const VALID_DAY_PERIOD = ['MORNING', 'AFTERNOON', 'NIGHT', 'UNKNOWN'];
const VALID_DAY_TYPE = ['WEEKDAY', 'WEEKEND'];
// Três níveis de evidência de estádio, iguais aos do banco:
//   MATCH_SPECIFIC            — a ficha da própria partida diz o estádio.
//   HISTORICAL_RECONSTRUCTION — deduzido de contexto histórico, com fonte,
//                               mas NÃO confirmado na ficha da partida.
//   UNKNOWN                   — não se sabe; o campo `stadium` fica null.
// `NEEDS_SOURCE` é o nome antigo de UNKNOWN, aceito pros datasets que já
// existiam antes do renomeio.
const STADIUM_STATUS_ALIASES = { NEEDS_SOURCE: 'UNKNOWN' };
const VALID_STADIUM_STATUS = [
  'MATCH_SPECIFIC',
  'HISTORICAL_RECONSTRUCTION',
  'UNKNOWN',
];
const EVIDENCE_STATUS = ['MATCH_SPECIFIC', 'HISTORICAL_RECONSTRUCTION'];

function loadBatches() {
  const files = fs
    .readdirSync(SOURCE_DIR)
    .filter((f) => /^bragantino_passport_\d{4}\.json$/.test(f))
    .sort();
  return files.map((file) => ({
    file,
    wrapper: JSON.parse(fs.readFileSync(path.join(SOURCE_DIR, file), 'utf8')),
  }));
}

export function validate(batches) {
  const problems = [];
  const fail = (check, detail) => problems.push({ check, detail });
  const all = batches.flatMap((b) => b.wrapper.matches);

  // --- IDs únicos, inclusive ENTRE lotes -----------------------------------
  const byId = new Map();
  for (const m of all) {
    if (byId.has(m.id)) {
      fail('IDS_UNICOS', `id repetido entre lotes: ${m.id}`);
    }
    byId.set(m.id, m);
  }

  // --- Duplicata de partida (mesma partida entrando 2x com ids diferentes) --
  const bySourceId = new Map();
  const byFixture = new Map();
  for (const m of all) {
    if (m.source_match_id) {
      if (bySourceId.has(m.source_match_id)) {
        fail(
          'DUPLICATAS',
          `mesma partida da fonte em 2 registros: ${m.source_match_id}`,
        );
      }
      bySourceId.set(m.source_match_id, m.id);
    }
    const fixture = `${m.date}|${m.home_team}|${m.away_team}`;
    if (byFixture.has(fixture)) {
      fail('DUPLICATAS', `mesmo confronto/data duplicado: ${fixture}`);
    }
    byFixture.set(fixture, m.id);
  }

  for (const m of all) {
    const where = `${m.id} (${m.date} ${m.home_team} x ${m.away_team})`;

    // --- clube correto ----------------------------------------------------
    const clubIsHome = CLUB_NAMES.includes(m.home_team);
    const clubIsAway = CLUB_NAMES.includes(m.away_team);
    if (clubIsHome === clubIsAway) {
      fail('CLUBE_CORRETO', `o Bragantino não está em exatamente 1 lado: ${where}`);
    }
    if (m.club_is_home !== clubIsHome) {
      fail('MANDO', `club_is_home não bate com os times: ${where}`);
    }

    // --- data válida ------------------------------------------------------
    if (!/^\d{4}-\d{2}-\d{2}$/.test(m.date) || Number.isNaN(Date.parse(m.date))) {
      fail('DATA_VALIDA', `data inválida: ${where}`);
    } else if (new Date(m.date).getUTCFullYear() !== m.calendar_year) {
      fail('DATA_VALIDA', `ano não bate com a data: ${where}`);
    }

    // --- adversário -------------------------------------------------------
    const opponent = m.club_is_home ? m.away_team : m.home_team;
    if (!opponent || opponent.trim().length === 0) {
      fail('ADVERSARIO', `adversário vazio: ${where}`);
    } else if (CLUB_NAMES.includes(opponent)) {
      fail('ADVERSARIO', `adversário é o próprio clube: ${where}`);
    }

    // --- status + placar coerente ----------------------------------------
    if (!VALID_STATUS.includes(m.score_status)) {
      fail('STATUS', `status fora do schema (${m.score_status}): ${where}`);
    }
    if (m.score_status === 'FINISHED') {
      if (m.home_score == null || m.away_score == null) {
        fail('PLACAR', `partida encerrada sem placar: ${where}`);
      } else {
        const expectedClub = m.club_is_home ? m.home_score : m.away_score;
        const expectedOpponent = m.club_is_home ? m.away_score : m.home_score;
        if (m.club_score !== expectedClub || m.opponent_score !== expectedOpponent) {
          fail('PLACAR', `club_score/opponent_score não batem com o mando: ${where}`);
        }
        if (m.home_score < 0 || m.away_score < 0) {
          fail('PLACAR', `placar negativo: ${where}`);
        }
        const expectedOutcome =
          expectedClub > expectedOpponent
            ? 'WIN'
            : expectedClub < expectedOpponent
              ? 'LOSS'
              : 'DRAW';
        if (m.outcome !== expectedOutcome) {
          fail('PLACAR', `outcome não bate com o placar: ${where}`);
        }
      }
    } else if (m.home_score != null || m.away_score != null) {
      fail('PLACAR', `partida não encerrada com placar preenchido: ${where}`);
    }

    // --- estádio / evidência ---------------------------------------------
    const stadiumStatus =
      STADIUM_STATUS_ALIASES[m.stadium_status] ?? m.stadium_status;
    if (!VALID_STADIUM_STATUS.includes(stadiumStatus)) {
      fail('ESTADIO_EVIDENCIA', `stadium_status inválido: ${where}`);
    }
    // Estádio e evidência andam juntos nos dois sentidos: sem evidência não
    // pode haver estádio, e com evidência ele não pode faltar.
    if (m.stadium && stadiumStatus === 'UNKNOWN') {
      fail('ESTADIO_EVIDENCIA', `estádio preenchido sem evidência: ${where}`);
    }
    if (!m.stadium && EVIDENCE_STATUS.includes(stadiumStatus)) {
      fail('ESTADIO_EVIDENCIA', `${stadiumStatus} sem estádio: ${where}`);
    }
    if (EVIDENCE_STATUS.includes(stadiumStatus) && !m.source_url) {
      fail('ESTADIO_EVIDENCIA', `estádio confirmado sem fonte rastreável: ${where}`);
    }

    // --- período do dia ---------------------------------------------------
    if (!VALID_DAY_PERIOD.includes(m.day_period)) {
      fail('PERIODO_DO_DIA', `day_period inválido (${m.day_period}): ${where}`);
    }
    if (!m.time && m.day_period !== 'UNKNOWN') {
      fail('PERIODO_DO_DIA', `sem horário mas com período definido: ${where}`);
    }
    if (m.time) {
      const hour = Number(m.time.slice(0, 2));
      const expected =
        hour >= 5 && hour < 12
          ? 'MORNING'
          : hour >= 12 && hour < 18
            ? 'AFTERNOON'
            : 'NIGHT';
      if (m.day_period !== expected) {
        fail('PERIODO_DO_DIA', `day_period não bate com ${m.time}: ${where}`);
      }
    }

    // --- weekday / weekend ------------------------------------------------
    if (!VALID_DAY_TYPE.includes(m.day_type)) {
      fail('WEEKDAY_WEEKEND', `day_type inválido: ${where}`);
    } else {
      const dow = new Date(`${m.date}T12:00:00Z`).getUTCDay();
      const expected = dow === 0 || dow === 6 ? 'WEEKEND' : 'WEEKDAY';
      if (m.day_type !== expected) {
        fail('WEEKDAY_WEEKEND', `day_type não bate com o dia da semana: ${where}`);
      }
    }

    // --- nenhum dado do Goiás --------------------------------------------
    const blob = JSON.stringify(m).toLowerCase();
    for (const marker of GOIAS_MARKERS) {
      if (blob.includes(marker)) {
        fail('SEM_DADO_DO_GOIAS', `"${marker}" aparece em ${where}`);
      }
    }
  }

  return { total: all.length, problems };
}

/// Checagens que dependem da SQL gerada, não do JSON.
export function validateSeeds() {
  const problems = [];
  const seeds = fs
    .readdirSync(path.join(ROOT, 'supabase'))
    .filter((f) => /^bragantino_passport_matches_\d{4}_seed\.sql$/.test(f));
  for (const seed of seeds) {
    const sql = fs.readFileSync(path.join(ROOT, 'supabase', seed), 'utf8');
    if (!/insert into public\.passport_matches\b/.test(sql)) {
      problems.push({
        check: 'SEED_TABELA',
        detail: `${seed} não insere em public.passport_matches`,
      });
    }
    if (!/on conflict \(id\) do update set/.test(sql)) {
      problems.push({
        check: 'SEED_IDEMPOTENTE',
        detail: `${seed} não é idempotente (falta ON CONFLICT DO UPDATE)`,
      });
    }
    if (sql.includes(BRAGANTINO_CLUB_ID)) {
      problems.push({
        check: 'SEED_SEM_CLUB_ID',
        detail:
          `${seed} traz club_id — a tabela do Passaporte não tem essa coluna ` +
          '(o isolamento é o projeto Supabase separado)',
      });
    }
  }
  return { seeds: seeds.length, problems };
}

const isMain =
  process.argv[1] &&
  import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (isMain) {
  const batches = loadBatches();
  console.log(
    `lotes: ${batches.length} (${batches.map((b) => b.file).join(', ')})`,
  );
  const dataset = validate(batches);
  const seeds = validateSeeds();
  const problems = [...dataset.problems, ...seeds.problems];

  console.log(`partidas validadas: ${dataset.total}`);
  console.log(`seeds conferidos: ${seeds.seeds}`);
  if (problems.length === 0) {
    console.log('\nTODAS AS VALIDAÇÕES DE IMPORTAÇÃO PASSARAM');
  } else {
    const byCheck = problems.reduce((acc, p) => {
      (acc[p.check] ??= []).push(p.detail);
      return acc;
    }, {});
    for (const [check, details] of Object.entries(byCheck)) {
      console.log(`\nFAIL — ${check} (${details.length})`);
      for (const detail of details.slice(0, 10)) console.log(`   ${detail}`);
      if (details.length > 10) console.log(`   ... +${details.length - 10}`);
    }
  }
  process.exit(problems.length === 0 ? 0 : 1);
}
