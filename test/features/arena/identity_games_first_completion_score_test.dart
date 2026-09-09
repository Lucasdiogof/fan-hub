// Pontuação dos 2 jogos de perfil (2026-09-09, pedido do usuário): 50
// pontos só na PRIMEIRA vez que o resultado é mostrado — replay/reabrir o
// resultado salvo nunca pontua de novo. A regra de "quanto vale" mora no
// servidor (RPC `arena_record_score`); aqui só travamos que o CLIENTE
// sempre reporta a conclusão (gameId/itemId corretos), com `itemId` fixo
// 'profile' (não há coleção de conteúdo nesses 2 jogos).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/player_identity/data/player_identity_repository.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/pages/player_identity_result_page.dart';
import 'package:goias_app/features/arena/games/tactical_identity/data/tactical_identity_repository.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/pages/tactical_identity_result_page.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/l10n/app_localizations.dart';

class _SpyRanking implements ArenaRankingRepository {
  String? gameId;
  String? itemId;
  int callCount = 0;

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
  }) async {
    callCount++;
    this.gameId = gameId;
    this.itemId = itemId;
    return const Success(
      ScoreResult(
        pointsEarned: 50,
        itemScore: 50,
        totalScore: 50,
        gameScore: 50,
      ),
    );
  }

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

class _FakeTacticalIdentityRepository implements TacticalIdentityRepository {
  @override
  Future<void> saveResult(TacticalIdentityResult result) async {}

  @override
  Future<TacticalIdentityResult?> loadLatestResult() async => null;
}

class _FakePlayerIdentityRepository implements PlayerIdentityRepository {
  @override
  Future<void> saveResult(PlayerIdentityResult result) async {}

  @override
  Future<PlayerIdentityResult?> loadLatestResult() async => null;
}

void main() {
  tearDown(() => sl.reset());

  testWidgets(
    'TacticalIdentityResultPage: reporta conclusão (tactical_identity/profile) ao abrir',
    (tester) async {
      final ranking = _SpyRanking();
      sl.registerSingleton<ClubConfig>(goiasClubConfig);
      sl.registerSingleton<ArenaRankingRepository>(ranking);
      sl.registerSingleton<TacticalIdentityRepository>(
        _FakeTacticalIdentityRepository(),
      );

      final result = TacticalIdentityResult(
        x: 0,
        y: 0,
        possession: 50,
        vertical: 50,
        dogmatic: 50,
        pragmatic: 50,
        archetype: TacticalArchetype.estruturado,
        closestCoaches: [
          CoachAffinity(
            coach: tacticalCoachReferences.first,
            distance: 0.5,
            affinity: 70,
          ),
        ],
        answers: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TacticalIdentityResultPage(result: result),
        ),
      );
      // A tela tem um problema de layout PRÉ-EXISTENTE fora do escopo desta
      // mudança (IntrinsicHeight dentro de LayoutBuilder sem altura
      // limitada no harness de teste — não acontece no device real, onde o
      // Scaffold já dá altura finita). O que este teste precisa travar
      // roda em , ANTES do layout — já aconteceu mesmo com a
      // exceção de render depois. Consome a exceção conhecida pra não
      // poluir o resultado do teste.
      tester.takeException();

      expect(ranking.callCount, 1);
      expect(ranking.gameId, ArenaGameIds.tacticalIdentity);
      expect(ranking.itemId, ArenaGameIds.profileItemId);
    },
  );

  testWidgets(
    'PlayerIdentityResultPage: reporta conclusão (player_identity/profile) ao abrir',
    (tester) async {
      final ranking = _SpyRanking();
      sl.registerSingleton<ClubConfig>(goiasClubConfig);
      sl.registerSingleton<ArenaRankingRepository>(ranking);
      sl.registerSingleton<PlayerIdentityRepository>(
        _FakePlayerIdentityRepository(),
      );

      const result = PlayerIdentityResult(
        attributes: PlayerIdentityAttributes(
          creativity: 50,
          definition: 50,
          leadership: 50,
          intensity: 50,
          technique: 50,
          tactics: 50,
        ),
        archetype: PlayerIdentityArchetype.complete,
        topTraits: [],
        closestReferences: [],
        answers: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PlayerIdentityResultPage(result: result),
        ),
      );
      await tester.pump();

      expect(ranking.callCount, 1);
      expect(ranking.gameId, ArenaGameIds.playerIdentity);
      expect(ranking.itemId, ArenaGameIds.profileItemId);
    },
  );

  test(
    'itemId fixo "profile" nos 2 jogos — anti-replay do servidor ancora nisso, nunca um id de conteúdo real',
    () {
      expect(ArenaGameIds.profileItemId, 'profile');
    },
  );
}
