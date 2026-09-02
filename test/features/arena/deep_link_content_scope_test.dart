// M3.1 (rodada de revisão) — prova em nível de widget, não só de grep
// estático, que `CareerPathPage`/`GuessPlayerPage`/`LineupPage` abertas
// SEM `cubit` preloaded (o caminho de deep link) realmente CONSOMEM o
// retorno do repository — usando dado SENTINELA, claramente diferente do
// fallback do Goiás, então o teste quebra se alguém reintroduzir
// `CareerPathCubit(players: careerPlayers)` (ou equivalente) no futuro.
//
// Também prova o inverso: quando a Arena já fornece um Cubit preloaded,
// a página NUNCA busca de novo (sem fetch duplicado).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/games/career_path/data/career_player_repository.dart';
import 'package:goias_app/features/arena/games/career_path/data/supabase_career_path_storage.dart';
import 'package:goias_app/features/arena/games/career_path/pages/career_path_page.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_cubit.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_catalog.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_repository.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_storage.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/features/arena/games/guess_player/pages/guess_player_page.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/data/lineup_match_repository.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _dummyClient() => SupabaseClient(
  'https://example.supabase.co',
  'anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

class _FakeRanking implements ArenaRankingRepository {
  int recordScoreCallCount = 0;

  @override
  Future<Result<ScoreResult>> recordScore({
    required String gameId,
    required String itemId,
    required String eventType,
    int? attemptNumber,
    String? difficulty,
    int? wrongCount,
    int? foundCount,
    int? totalCount,
    bool wasRevealed = false,
    bool wasAbandoned = false,
  }) async => const Success(
    ScoreResult(pointsEarned: 0, itemScore: 0, totalScore: 0, gameScore: 0),
  );

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) async => const Success([]);

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) async => const Success(null);

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------
// Dados sentinela — claramente diferentes de qualquer entrada real do
// fallback do Goiás (id/nome inconfundíveis).
// ---------------------------------------------------------------------
const _sentinelCareerPlayers = [
  CareerPlayer(
    id: 'sentinel-career-player',
    answer: 'SENTINELA',
    acceptedAnswers: ['SENTINELA'],
    clubCareer: [CareerEntry(period: '2020-2021', team: 'Sentinela FC')],
  ),
];

const _sentinelGuessCatalog = [
  GuessPlayer(id: 'sentinel-guess-player', name: 'Sentinela', displayName: 'Sentinela'),
];

final _sentinelLineupMatches = [
  LineupMatch(
    id: 'sentinel-lineup-match',
    competition: 'Sentinela Cup',
    season: '2020',
    phase: 'final',
    date: DateTime(2020),
    homeTeam: 'Sentinela',
    awayTeam: 'Adversário',
    homeScore: 1,
    awayScore: 0,
    teamToGuess: 'Sentinela',
    formation: '4-3-3',
    formationConfidence: FormationConfidence.confirmed,
    players: List.generate(
      11,
      (i) => LineupPlayer(
        id: 'sentinel-p$i',
        position: 'GK',
        x: 0.5,
        y: 0.5,
        shirtNumber: i + 1,
        fullName: 'Sentinela $i',
        displayName: 'Sentinela $i',
        puzzleAnswer: 'ABC',
        answerParts: const [3],
        normalizedAnswer: 'ABC',
      ),
    ),
  ),
];

class _SentinelCareerPlayerRepository extends CareerPlayerRepository {
  _SentinelCareerPlayerRepository() : super(_dummyClient(), goiasClubConfig);
  int loadCallCount = 0;

  @override
  Future<List<CareerPlayer>> load() async {
    loadCallCount++;
    return _sentinelCareerPlayers;
  }
}

class _SentinelGuessPlayerRepository extends GuessPlayerRepository {
  _SentinelGuessPlayerRepository() : super(_dummyClient(), goiasClubConfig);
  int loadCallCount = 0;

  @override
  Future<List<GuessPlayer>> load() async {
    loadCallCount++;
    return _sentinelGuessCatalog;
  }
}

class _SentinelLineupMatchRepository extends LineupMatchRepository {
  _SentinelLineupMatchRepository() : super(_dummyClient(), goiasClubConfig);
  int loadCallCount = 0;

  @override
  Future<List<LineupMatch>> load() async {
    loadCallCount++;
    return _sentinelLineupMatches;
  }
}

class _FakeCareerPathStorage extends SupabaseCareerPathStorage {
  _FakeCareerPathStorage() : super(_dummyClient());
  @override
  Future<CareerRoundState?> load(String playerId) async => null;
  @override
  Future<void> save(CareerRoundState round) async {}
  @override
  Future<String?> loadSelectedPlayerId() async => null;
  @override
  Future<void> saveSelectedPlayerId(String playerId) async {}
  @override
  Future<Set<String>> completedIds() async => const {};
}

class _FakeGuessPlayerStorage extends GuessPlayerStorage {
  @override
  Future<GuessPlayerRoundState?> loadActiveRound() async => null;
  @override
  Future<void> saveActiveRound(GuessPlayerRoundState round) async {}
  @override
  Future<void> clearActiveRound() async {}
  @override
  Future<void> recordRoundResult({required bool won}) async {}
  @override
  Future<Set<String>> loadSeenIds() async => const {};
  @override
  Future<void> addSeenId(String id) async {}
  @override
  Future<void> clearSeenIds() async {}
  @override
  Future<String?> loadSeenSignature() async => null;
  @override
  Future<void> saveSeenSignature(String signature) async {}
}

class _FakeLineupStorage extends SupabaseLineupStorage {
  _FakeLineupStorage() : super(_dummyClient());
  @override
  Future<LineupGameState?> load(String matchId) async => null;
  @override
  Future<void> save(LineupGameState state) async {}
  @override
  Future<String?> loadSelectedMatchId() async => null;
  @override
  Future<void> saveSelectedMatchId(String matchId) async {}
  @override
  Future<Set<String>> completedIds() async => const {};
}

Widget _wrap(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ArenaRankingRepository>(_FakeRanking.new);
  });

  group('CareerPathPage', () {
    testWidgets('deep link (sem cubit preloaded) consome o dado do repository, NUNCA careerPlayers (fallback)', (tester) async {
      sl.registerLazySingleton<SupabaseCareerPathStorage>(_FakeCareerPathStorage.new);
      sl.registerLazySingleton<CareerPlayerRepository>(_SentinelCareerPlayerRepository.new);

      await tester.pumpWidget(_wrap(const CareerPathPage()));
      await tester.pumpAndSettle();

      final cubit = BlocProvider.of<CareerPathCubit>(
        tester.element(find.byType(Scaffold).first),
      );
      expect(cubit.state.players.map((p) => p.id), contains('sentinel-career-player'));
      expect(cubit.state.players, isNot(same(careerPlayers)));
      expect((sl<CareerPlayerRepository>() as _SentinelCareerPlayerRepository).loadCallCount, 1);
    });

    testWidgets('com cubit preloaded, NUNCA busca de novo no repository (0 fetch duplicado)', (tester) async {
      final spyRepo = _SentinelCareerPlayerRepository();
      sl.registerLazySingleton<SupabaseCareerPathStorage>(_FakeCareerPathStorage.new);
      sl.registerLazySingleton<CareerPlayerRepository>(() => spyRepo);

      final storage = _FakeCareerPathStorage();
      final preloadedCubit = CareerPathCubit(
        players: _sentinelCareerPlayers,
        loadRound: storage.load,
        saveRound: storage.save,
        loadSelectedId: storage.loadSelectedPlayerId,
        saveSelectedId: storage.saveSelectedPlayerId,
        loadCompletedIds: storage.completedIds,
        ranking: sl<ArenaRankingRepository>(),
      );
      unawaited(preloadedCubit.loadSelected());

      await tester.pumpWidget(_wrap(CareerPathPage(cubit: preloadedCubit)));
      await tester.pumpAndSettle();

      expect(spyRepo.loadCallCount, 0, reason: 'CareerPathPage com cubit preloaded não deveria chamar o repository');
    });
  });

  group('GuessPlayerPage', () {
    testWidgets('deep link (sem cubit preloaded) consome o dado do repository, NUNCA guessPlayerCatalog (fallback)', (tester) async {
      sl.registerLazySingleton<GuessPlayerStorage>(_FakeGuessPlayerStorage.new);
      sl.registerLazySingleton<GuessPlayerRepository>(_SentinelGuessPlayerRepository.new);

      await tester.pumpWidget(_wrap(const GuessPlayerPage()));
      await tester.pumpAndSettle();

      final cubit = BlocProvider.of<GuessPlayerCubit>(
        tester.element(find.byType(Scaffold).first),
      );
      expect(cubit.catalog.map((p) => p.id), contains('sentinel-guess-player'));
      expect(cubit.catalog, isNot(same(guessPlayerCatalog)));
      expect((sl<GuessPlayerRepository>() as _SentinelGuessPlayerRepository).loadCallCount, 1);
    });

    testWidgets('com cubit preloaded, NUNCA busca de novo no repository (0 fetch duplicado)', (tester) async {
      final spyRepo = _SentinelGuessPlayerRepository();
      sl.registerLazySingleton<GuessPlayerStorage>(_FakeGuessPlayerStorage.new);
      sl.registerLazySingleton<GuessPlayerRepository>(() => spyRepo);

      final storage = _FakeGuessPlayerStorage();
      final preloadedCubit = GuessPlayerCubit(
        catalog: _sentinelGuessCatalog,
        loadRound: storage.loadActiveRound,
        saveRound: storage.saveActiveRound,
        clearRound: storage.clearActiveRound,
        recordRoundResult: storage.recordRoundResult,
        ranking: sl<ArenaRankingRepository>(),
        loadSeenIds: storage.loadSeenIds,
        addSeenId: storage.addSeenId,
        clearSeenIds: storage.clearSeenIds,
        loadSeenSignature: storage.loadSeenSignature,
        saveSeenSignature: storage.saveSeenSignature,
      );

      await tester.pumpWidget(_wrap(GuessPlayerPage(cubit: preloadedCubit)));
      await tester.pumpAndSettle();

      expect(spyRepo.loadCallCount, 0, reason: 'GuessPlayerPage com cubit preloaded não deveria chamar o repository');
    });
  });

  group('LineupPage', () {
    testWidgets('deep link (sem cubit preloaded) consome o dado do repository, NUNCA orderedLineupMatches (fallback)', (tester) async {
      sl.registerLazySingleton<SupabaseLineupStorage>(_FakeLineupStorage.new);
      sl.registerLazySingleton<LineupMatchRepository>(_SentinelLineupMatchRepository.new);

      await tester.pumpWidget(_wrap(const LineupPage()));
      await tester.pumpAndSettle();

      final cubit = BlocProvider.of<LineupCubit>(
        tester.element(find.byType(Scaffold).first),
      );
      expect(cubit.state.matches.map((m) => m.id), contains('sentinel-lineup-match'));
      expect(cubit.state.matches, isNot(same(orderedLineupMatches)));
      expect((sl<LineupMatchRepository>() as _SentinelLineupMatchRepository).loadCallCount, 1);
    });

    testWidgets('com cubit preloaded, NUNCA busca de novo no repository (0 fetch duplicado)', (tester) async {
      final spyRepo = _SentinelLineupMatchRepository();
      sl.registerLazySingleton<SupabaseLineupStorage>(_FakeLineupStorage.new);
      sl.registerLazySingleton<LineupMatchRepository>(() => spyRepo);

      final storage = _FakeLineupStorage();
      final preloadedCubit = LineupCubit(
        matches: _sentinelLineupMatches,
        loadState: storage.load,
        saveState: storage.save,
        loadSelectedMatchId: storage.loadSelectedMatchId,
        saveSelectedMatchId: storage.saveSelectedMatchId,
        loadCompletedIds: storage.completedIds,
        ranking: sl<ArenaRankingRepository>(),
      );
      unawaited(preloadedCubit.loadSelectedMatch());

      await tester.pumpWidget(_wrap(LineupPage(cubit: preloadedCubit)));
      await tester.pumpAndSettle();

      expect(spyRepo.loadCallCount, 0, reason: 'LineupPage com cubit preloaded não deveria chamar o repository');
    });
  });
}
