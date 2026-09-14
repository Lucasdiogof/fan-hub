import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_cubit.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _eligible1 = GuessPlayer(
  id: 'p1',
  name: 'Harlei',
  displayName: 'Harlei',
  position: PlayerPosition.gol,
  shirtNumber: 1,
  academyClub: 'Goiás',
  clubDebutYear: 2010,
  imageUrl: 'harlei.png',
  dataStatus: GuessPlayerDataStatus.verified,
);
const _eligible2 = GuessPlayer(
  id: 'p2',
  name: 'Rafael Moura',
  displayName: 'Rafael Moura',
  position: PlayerPosition.ata,
  shirtNumber: 9,
  academyClub: 'Goiás',
  clubDebutYear: 2011,
  imageUrl: 'rafael.png',
  dataStatus: GuessPlayerDataStatus.verified,
);
const _incomplete = GuessPlayer(
  id: 'p3',
  name: 'Sem Dado',
  displayName: 'Sem Dado',
  dataStatus: GuessPlayerDataStatus.incomplete,
);

class _RecordScoreCall {
  _RecordScoreCall(this.eventType, this.attemptNumber, this.wasRevealed);
  final String eventType;
  final int? attemptNumber;
  final bool wasRevealed;
}

class _SpyArenaRankingRepository implements ArenaRankingRepository {
  final calls = <_RecordScoreCall>[];

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
    calls.add(_RecordScoreCall(eventType, attemptNumber, wasRevealed));
    return const Success(
      ScoreResult(pointsEarned: 0, itemScore: 0, totalScore: 0, gameScore: 0),
    );
  }

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) => throw UnimplementedError();

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) => throw UnimplementedError();

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) =>
      throw UnimplementedError();
}

class _RecordRoundResultCall {
  _RecordRoundResultCall(this.won);
  final bool won;
}

GuessPlayerCubit _buildCubit({
  List<GuessPlayer>? catalog,
  _SpyArenaRankingRepository? ranking,
  GuessPlayerRoundState? savedRound,
  Set<String>? seenIds,
  String? seenSignature,
  List<_RecordRoundResultCall>? recordRoundResultCalls,
}) {
  final seen = seenIds ?? <String>{};
  var round = savedRound;
  var signature = seenSignature;
  return GuessPlayerCubit(
    catalog: catalog ?? const [_eligible1, _eligible2],
    ranking: ranking ?? _SpyArenaRankingRepository(),
    loadRound: () async => round,
    saveRound: (r) async => round = r,
    clearRound: () async => round = null,
    recordRoundResult: ({required won}) async =>
        recordRoundResultCalls?.add(_RecordRoundResultCall(won)),
    loadSeenIds: () async => seen,
    addSeenId: (id) async => seen.add(id),
    clearSeenIds: () async => seen.clear(),
    loadSeenSignature: () async => signature,
    saveSeenSignature: (s) async => signature = s,
  );
}

void main() {
  test('catálogo sem elegível nenhum emite LoadStatus.empty', () async {
    final cubit = _buildCubit(catalog: const [_incomplete]);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.empty);
    expect(cubit.hasEligibleSecret, isFalse);
  });

  test(
    'ao criar, sorteia um secreto elegível e começa uma rodada nova',
    () async {
      final cubit = _buildCubit();
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.secretPlayer, isNotNull);
      expect([
        _eligible1.id,
        _eligible2.id,
      ], contains(cubit.state.secretPlayer!.id));
      expect(cubit.state.round?.guessedPlayerIds, isEmpty);
    },
  );

  test(
    'rodada salva com secreto ainda existente no catálogo é retomada',
    () async {
      final saved = const GuessPlayerRoundState(
        secretPlayerId: 'p1',
        guessedPlayerIds: ['p2'],
      );
      final cubit = _buildCubit(savedRound: saved);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.secretPlayer?.id, 'p1');
      expect(cubit.state.round?.guessedPlayerIds, ['p2']);
    },
  );

  group('submitGuess', () {
    test(
      'acerto de primeira marca won, limpa a rodada salva e registra first_try_correct',
      () async {
        final ranking = _SpyArenaRankingRepository();
        final recorded = <_RecordRoundResultCall>[];
        final cubit = _buildCubit(
          catalog: const [_eligible1],
          ranking: ranking,
          recordRoundResultCalls: recorded,
        );
        addTearDown(cubit.close);
        await Future<void>.delayed(Duration.zero);

        await cubit.submitGuess(_eligible1);

        expect(cubit.state.round?.won, isTrue);
        expect(ranking.calls.single.eventType, 'first_try_correct');
        expect(recorded.single.won, isTrue);
      },
    );

    test('errar sem esgotar as 7 tentativas mantém a rodada aberta', () async {
      const wrongGuess = GuessPlayer(
        id: 'errado',
        name: 'Errado',
        displayName: 'Errado',
      );
      final cubit = _buildCubit(catalog: const [_eligible1]);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      await cubit.submitGuess(wrongGuess);

      expect(cubit.state.round?.isOver, isFalse);
      expect(cubit.state.round?.guessedPlayerIds, ['errado']);
    });

    test(
      'esgotar as 7 tentativas marca lost e registra attempts_exhausted',
      () async {
        final ranking = _SpyArenaRankingRepository();
        final wrongGuess = GuessPlayer(
          id: 'errado',
          name: 'Errado',
          displayName: 'Errado',
        );
        final cubit = _buildCubit(
          catalog: const [_eligible1],
          ranking: ranking,
        );
        addTearDown(cubit.close);
        await Future<void>.delayed(Duration.zero);

        for (var i = 0; i < maxGuessAttempts; i++) {
          await cubit.submitGuess(wrongGuess);
        }

        expect(cubit.state.round?.lost, isTrue);
        expect(ranking.calls.single.eventType, 'attempts_exhausted');
        expect(ranking.calls.single.wasRevealed, isTrue);
      },
    );

    test('palpite depois da rodada já ter terminado não faz nada', () async {
      final cubit = _buildCubit(catalog: const [_eligible1]);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      await cubit.submitGuess(_eligible1);
      final wonRound = cubit.state.round;

      await cubit.submitGuess(_eligible1);

      expect(cubit.state.round, wonRound);
    });
  });

  test('nextPlayer limpa a rodada e começa uma nova', () async {
    final cubit = _buildCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    final firstSecretId = cubit.state.secretPlayer?.id;

    await cubit.nextPlayer();

    expect(cubit.state.round?.guessedPlayerIds, isEmpty);
    expect(cubit.state.status, LoadStatus.success);
    // Com só 2 elegíveis e o "visto" já marcado, o próximo é o outro.
    expect(cubit.state.secretPlayer?.id, isNot(firstSecretId));
  });
}
