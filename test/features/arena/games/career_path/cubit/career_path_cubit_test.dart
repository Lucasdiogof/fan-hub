import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _player1 = CareerPlayer(
  id: 'p1',
  answer: 'Harlei',
  acceptedAnswers: ['harlei'],
  clubCareer: [CareerEntry(period: '2010-2015', team: 'Goiás', isGoias: true)],
);
const _player2 = CareerPlayer(
  id: 'p2',
  answer: 'Rafael Moura',
  acceptedAnswers: ['rafael moura', 'rafael'],
  clubCareer: [CareerEntry(period: '2011-2013', team: 'Goiás', isGoias: true)],
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

CareerPathCubit _buildCubit({
  List<CareerPlayer>? players,
  _SpyArenaRankingRepository? ranking,
  Map<String, CareerRoundState>? rounds,
  String? selectedId,
  Set<String>? completedIds,
}) {
  final roundsStore = rounds ?? <String, CareerRoundState>{};
  var selected = selectedId;
  return CareerPathCubit(
    players: players ?? const [_player1, _player2],
    loadRound: (playerId) async => roundsStore[playerId],
    saveRound: (round) async => roundsStore[round.playerId] = round,
    loadSelectedId: () async => selected,
    saveSelectedId: (playerId) async => selected = playerId,
    loadCompletedIds: () async => completedIds ?? <String>{},
    ranking: ranking ?? _SpyArenaRankingRepository(),
  );
}

void main() {
  test('loadSelected carrega o primeiro jogador ainda não concluído', () async {
    final cubit = _buildCubit();
    addTearDown(cubit.close);

    await cubit.loadSelected();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.player, isNotNull);
    expect(cubit.state.round, isNotNull);
    expect(cubit.state.round!.status, CareerRoundStatus.playing);
  });

  test(
    'loadSelected retoma o jogador salvo quando ele tem progresso salvo',
    () async {
      final cubit = _buildCubit(
        selectedId: 'p2',
        rounds: {
          'p2': CareerRoundState(playerId: 'p2', startedAt: DateTime.now()),
        },
      );
      addTearDown(cubit.close);

      await cubit.loadSelected();

      expect(cubit.state.player?.id, 'p2');
    },
  );

  group('isCorrect', () {
    test('bate com qualquer resposta aceita, ignorando maiúscula/acento', () {
      final cubit = _buildCubit();
      addTearDown(cubit.close);

      expect(cubit.isCorrect(_player2, 'Rafael'), isTrue);
      expect(cubit.isCorrect(_player2, 'RAFAEL MOURA'), isTrue);
      expect(cubit.isCorrect(_player2, 'Fulano'), isFalse);
    });
  });

  group('guess', () {
    test('acerto de primeira marca won e registra first_try_correct', () async {
      final ranking = _SpyArenaRankingRepository();
      final cubit = _buildCubit(players: const [_player1], ranking: ranking);
      addTearDown(cubit.close);
      await cubit.loadSelected();

      await cubit.guess('Harlei');

      expect(cubit.state.round?.status, CareerRoundStatus.won);
      expect(cubit.state.justFinished, isTrue);
      expect(ranking.calls.single.eventType, 'first_try_correct');
    });

    test('acerto depois de erros registra correct_after_errors', () async {
      final ranking = _SpyArenaRankingRepository();
      final cubit = _buildCubit(players: const [_player1], ranking: ranking);
      addTearDown(cubit.close);
      await cubit.loadSelected();

      await cubit.guess('chute errado');
      await cubit.guess('Harlei');

      expect(cubit.state.round?.status, CareerRoundStatus.won);
      expect(ranking.calls.last.eventType, 'correct_after_errors');
      expect(ranking.calls.last.attemptNumber, 2);
    });

    test(
      'erro antes de esgotar tentativas mantém playing, sem justFinished',
      () async {
        final cubit = _buildCubit(players: const [_player1]);
        addTearDown(cubit.close);
        await cubit.loadSelected();

        await cubit.guess('chute errado');

        expect(cubit.state.round?.status, CareerRoundStatus.playing);
        expect(cubit.state.justFinished, isFalse);
        expect(cubit.state.round?.wrongGuesses, ['chute errado']);
      },
    );

    test(
      'esgotar as 5 tentativas marca lost e registra attempts_exhausted',
      () async {
        final ranking = _SpyArenaRankingRepository();
        final cubit = _buildCubit(players: const [_player1], ranking: ranking);
        addTearDown(cubit.close);
        await cubit.loadSelected();

        for (var i = 0; i < CareerPathCubit.maxAttempts; i++) {
          await cubit.guess('chute errado $i');
        }

        expect(cubit.state.round?.status, CareerRoundStatus.lost);
        expect(cubit.state.justFinished, isTrue);
        expect(ranking.calls.single.eventType, 'attempts_exhausted');
        expect(ranking.calls.single.wasRevealed, isTrue);
      },
    );

    test('chute depois que a rodada já terminou não faz nada', () async {
      final cubit = _buildCubit(players: const [_player1]);
      addTearDown(cubit.close);
      await cubit.loadSelected();
      await cubit.guess('Harlei');
      final wonRound = cubit.state.round;

      await cubit.guess('mais um chute');

      expect(cubit.state.round, wonRound);
    });
  });

  test('reveal marca revealed e registra o evento no ranking', () async {
    final ranking = _SpyArenaRankingRepository();
    final cubit = _buildCubit(players: const [_player1], ranking: ranking);
    addTearDown(cubit.close);
    await cubit.loadSelected();

    await cubit.reveal();

    expect(cubit.state.round?.status, CareerRoundStatus.revealed);
    expect(cubit.state.justFinished, isTrue);
    expect(ranking.calls.single.eventType, 'revealed');
  });

  test(
    'acknowledgeResultShown só limpa justFinished quando estava true',
    () async {
      final cubit = _buildCubit(players: const [_player1]);
      addTearDown(cubit.close);
      await cubit.loadSelected();
      await cubit.guess('Harlei');
      expect(cubit.state.justFinished, isTrue);

      cubit.acknowledgeResultShown();

      expect(cubit.state.justFinished, isFalse);
    },
  );

  test(
    'goToNextOrFirst troca pro outro jogador, nunca repete o atual',
    () async {
      final cubit = _buildCubit();
      addTearDown(cubit.close);
      await cubit.loadSelected();
      final first = cubit.state.player!.id;

      await cubit.goToNextOrFirst();

      expect(cubit.state.player!.id, isNot(first));
      expect(cubit.state.roundNumber, 2);
    },
  );
}
