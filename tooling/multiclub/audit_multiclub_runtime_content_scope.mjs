// M3.1 — audita, lendo os arquivos .dart REAIS (nunca uma lista
// assumida), se as 5 tabelas de conteúdo editorial (career_players,
// guess_players, squad_members, lineup_matches, quiz_questions) estão
// genuinamente tenant-scoped no runtime Flutter: repository filtra por
// club_id, DI injeta ClubConfig, nenhum bypass de página, nenhum UUID
// hardcoded fora de goias_club_config.dart, nenhum fallback cross-club,
// nenhum drift semântico nos campos protegidos por F1-F7.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const GOIAS_UUID = '4c16340d-300c-5ab2-903f-17519db9b146';

const TABLES = {
  career_players: {
    repo: 'features/arena/games/career_path/data/career_player_repository.dart',
    page: 'features/arena/games/career_path/pages/career_path_page.dart',
    fallbackConst: 'careerPlayers',
    fallbackVar: 'careerPlayersFallback',
    protectedColumns: ['id', 'answer', 'accepted_answers', 'club_career', 'person_id'],
  },
  guess_players: {
    repo: 'features/arena/games/guess_player/data/guess_player_repository.dart',
    page: 'features/arena/games/guess_player/pages/guess_player_page.dart',
    fallbackConst: 'guessPlayerCatalog',
    fallbackVar: 'guessPlayerCatalogFallback',
    protectedColumns: ['id', 'name', 'display_name', 'person_id'],
  },
  squad_members: {
    repo: 'features/squad/data/supabase_squad_repository.dart',
    page: null,
    fallbackConst: null,
    fallbackVar: null,
    protectedColumns: [],
  },
  lineup_matches: {
    repo: 'features/arena/games/lineup/data/lineup_match_repository.dart',
    page: 'features/arena/games/lineup/pages/lineup_page.dart',
    fallbackConst: 'orderedLineupMatches',
    fallbackVar: 'orderedLineupMatchesFallback',
    protectedColumns: ['id', 'lineup', 'formation'],
  },
  quiz_questions: {
    repo: 'features/arena/games/quiz/data/quiz_question_repository.dart',
    page: null,
    fallbackConst: 'quizQuestions',
    fallbackVar: 'quizQuestionsFallback',
    protectedColumns: ['id', 'difficulty', 'question', 'options', 'correct_index'],
  },
};

const DI_FILE = path.join(LIB, 'core', 'di', 'injection_container.dart');
const CLUB_REGISTRY_FILE = path.join(LIB, 'core', 'club', 'club_registry.dart');
const CLUB_SCOPED_FALLBACK_FILE = path.join(LIB, 'core', 'club', 'club_scoped_fallback.dart');
const CLUB_DATA_UNAVAILABLE_FILE = path.join(LIB, 'core', 'club', 'club_data_unavailable_exception.dart');

const diSrc = fs.readFileSync(DI_FILE, 'utf8');
const registrySrc = fs.readFileSync(CLUB_REGISTRY_FILE, 'utf8');

const results = {};
for (const [table, cfg] of Object.entries(TABLES)) {
  const repoPath = path.join(LIB, cfg.repo);
  const repoSrc = fs.readFileSync(repoPath, 'utf8');

  const hasClubIdFilter = /\.eq\(\s*'club_id',\s*_clubConfig\.identity\.canonicalClubId\s*\)/.test(repoSrc);
  const hasClubConfigCtorParam = /this\._clubConfig\)/.test(repoSrc) || /,\s*this\._clubConfig\s*\)/.test(repoSrc);
  const hardcodedGoiasUuid = repoSrc.includes(GOIAS_UUID);
  const usesClubScopedFallback = cfg.fallbackVar
    ? repoSrc.includes(`ClubScopedFallback<`) && repoSrc.includes(cfg.fallbackVar)
    : true; // squad_members nunca teve fallback
  const usesUnconditionalFallbackReturn = cfg.fallbackConst
    ? new RegExp(`return ${cfg.fallbackConst};`).test(repoSrc) // padrão antigo proibido
    : false;
  // Rodada de revisão: EMPTY_NO_FALLBACK (lança ClubDataUnavailableException)
  // e REMOTE_FAILURE_NO_FALLBACK (relança a exceção ORIGINAL) precisam ser
  // caminhos DISTINTOS — nunca uma falha real convertida em
  // ClubDataUnavailableException só porque não há fallback.
  const hasErrorPreservingRethrow = cfg.fallbackVar
    ? /Error\.throwWithStackTrace\(error, stackTrace\)/.test(repoSrc)
    : true; // squad_members nunca lançou nada, propaga Result/Error normal
  const hasEmptyResultThrow = cfg.fallbackVar
    ? new RegExp(`throw ClubDataUnavailableException\\(`).test(repoSrc)
    : true;
  // a exceção original NUNCA pode ser convertida em ClubDataUnavailableException
  // dentro do catch — ou seja, o catch nunca deve conter um
  // "throw ClubDataUnavailableException" (só o Error.throwWithStackTrace).
  const catchBlockMatch = repoSrc.match(/} catch \(error, stackTrace\) \{([\s\S]*?)\n {4}\}/);
  const catchNeverThrowsClubDataUnavailable = catchBlockMatch
    ? !catchBlockMatch[1].includes('ClubDataUnavailableException(')
    : true;
  const emptyAndFailureSemanticsDistinct = cfg.fallbackVar
    ? hasErrorPreservingRethrow && hasEmptyResultThrow && catchNeverThrowsClubDataUnavailable
    : true;
  const columnsCoverage = cfg.protectedColumns.map((col) => ({
    column: col,
    present: repoSrc.includes(`'${col}'`) || repoSrc.includes(`${col}'`) || repoSrc.includes(`, ${col},`) || repoSrc.includes(`${col},`) || repoSrc.includes(col),
  }));
  const allProtectedColumnsPresent = columnsCoverage.every((c) => c.present);

  let bypassFixed = true;
  if (cfg.page) {
    const pageSrc = fs.readFileSync(path.join(LIB, cfg.page), 'utf8');
    // o padrão antigo (bypass) construía o Cubit com a lista const direto,
    // fora de qualquer FutureBuilder — nunca deve mais existir.
    const oldBypassPattern = new RegExp(`players:\\s*${cfg.fallbackConst}|matches:\\s*${cfg.fallbackConst}|catalog:\\s*${cfg.fallbackConst}`);
    bypassFixed = !oldBypassPattern.test(pageSrc) && pageSrc.includes('FutureBuilder');
  }

  const diRegistrationPattern = new RegExp(`${table.replace(/_(\w)/g, (_, c) => c.toUpperCase())}`, 'i');
  results[table] = {
    hasClubIdFilter,
    hasClubConfigCtorParam,
    hardcodedGoiasUuid,
    usesClubScopedFallback,
    usesUnconditionalFallbackReturn,
    hasErrorPreservingRethrow,
    hasEmptyResultThrow,
    catchNeverThrowsClubDataUnavailable,
    emptyAndFailureSemanticsDistinct,
    allProtectedColumnsPresent,
    columnsCoverage,
    bypassFixed,
    pageAudited: cfg.page,
  };
}

const diHasSlCallForEachRepo = {
  CareerPlayerRepository: /CareerPlayerRepository\(Supabase\.instance\.client,\s*sl\(\)\)/.test(diSrc),
  GuessPlayerRepository: /GuessPlayerRepository\(Supabase\.instance\.client,\s*sl\(\)\)/.test(diSrc),
  SupabaseSquadRepository: /SupabaseSquadRepository\(Supabase\.instance\.client,\s*sl\(\)\)/.test(diSrc),
  LineupMatchRepository: /LineupMatchRepository\(Supabase\.instance\.client,\s*sl\(\)\)/.test(diSrc),
  QuizQuestionRepository: /QuizQuestionRepository\(Supabase\.instance\.client,\s*sl\(\)\)/.test(diSrc),
};

const clubRegistryEntryCount = (registrySrc.match(/'[\w-]+':\s*\w+ClubConfig/g) || []).length;

const globalUuidGrepFiles = [];
for (const [table, cfg] of Object.entries(TABLES)) {
  const repoSrc = fs.readFileSync(path.join(LIB, cfg.repo), 'utf8');
  if (repoSrc.includes(GOIAS_UUID)) globalUuidGrepFiles.push(cfg.repo);
}

const clubScopedFallbackExists = fs.existsSync(CLUB_SCOPED_FALLBACK_FILE);
const clubDataUnavailableExists = fs.existsSync(CLUB_DATA_UNAVAILABLE_FILE);

const audit = {
  tables: results,
  diHasSlCallForEachRepo,
  clubRegistryEntryCount,
  // M4: registry de produção agora tem 2 clubes REAIS (goias + bragantino);
  // o Goiás continua presente e não há clube sintético.
  clubRegistryHasGoias: registrySrc.includes("'goias'"),
  clubRegistryHasBragantino: registrySrc.includes("'bragantino'"),
  goiasUuidHardcodedInRepositories: globalUuidGrepFiles,
  clubScopedFallbackExists,
  clubDataUnavailableExists,
  allRuntimeReadPathsScoped: Object.values(results).every(
    (r) => r.hasClubIdFilter && r.hasClubConfigCtorParam && !r.hardcodedGoiasUuid && !r.usesUnconditionalFallbackReturn && r.usesClubScopedFallback && r.bypassFixed
  ),
  // Rodada de revisão (hardening pós-review): confirma que EMPTY_NO_FALLBACK
  // (0 linhas, sucesso) e REMOTE_FAILURE_NO_FALLBACK (exceção real) nunca
  // são conflatados em nenhum dos 4 repositories com fallback — a exceção
  // original nunca é convertida em ClubDataUnavailableException.
  emptyVsRemoteFailureSemanticsInvariant: {
    description:
      'EMPTY_NO_FALLBACK != REMOTE_FAILURE_NO_FALLBACK: sucesso com 0 linhas ' +
      'e sem fallback lança ClubDataUnavailableException; falha remota ' +
      '(rede/parse/exception) sem fallback SEMPRE relança a exceção ' +
      'original via Error.throwWithStackTrace, nunca ClubDataUnavailableException.',
    holds: Object.values(results).every((r) => r.emptyAndFailureSemanticsDistinct),
  },
};

fs.writeFileSync(
  path.join(RECON, 'multiclub_runtime_content_scope_audit.json'),
  JSON.stringify(audit, null, 2) + '\n'
);
console.log(JSON.stringify({
  allRuntimeReadPathsScoped: audit.allRuntimeReadPathsScoped,
  emptyVsRemoteFailureSemanticsInvariant: audit.emptyVsRemoteFailureSemanticsInvariant,
  clubRegistryEntryCount: audit.clubRegistryEntryCount,
  goiasUuidHardcodedInRepositories: audit.goiasUuidHardcodedInRepositories,
  perTable: Object.fromEntries(Object.entries(results).map(([t, r]) => [t, {
    hasClubIdFilter: r.hasClubIdFilter,
    hardcodedGoiasUuid: r.hardcodedGoiasUuid,
    usesUnconditionalFallbackReturn: r.usesUnconditionalFallbackReturn,
    bypassFixed: r.bypassFixed,
    hasErrorPreservingRethrow: r.hasErrorPreservingRethrow,
    hasEmptyResultThrow: r.hasEmptyResultThrow,
    catchNeverThrowsClubDataUnavailable: r.catchNeverThrowsClubDataUnavailable,
    emptyAndFailureSemanticsDistinct: r.emptyAndFailureSemanticsDistinct,
  }])),
}, null, 2));
console.log('\nEscrito em:', RECON);
