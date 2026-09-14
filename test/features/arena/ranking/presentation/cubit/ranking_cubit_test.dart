import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../../../auth/fakes/fake_auth_repository.dart';
import '../../../../membership/fakes/fake_membership_repository.dart';

const _me = RankingEntry(
  rank: 1,
  userId: 'u1',
  name: 'Torcedor Teste',
  totalScore: 100,
  isMe: true,
);
const _other = RankingEntry(
  rank: 2,
  userId: 'u2',
  name: 'Outro Torcedor',
  totalScore: 80,
  isMe: false,
);

class _FakeArenaRankingRepository implements ArenaRankingRepository {
  Result<List<RankingEntry>> rankingResult = const Success([]);
  Result<({int rank, int totalScore})?> myRankResult = const Success(null);
  RankingPeriod? lastRankingPeriod;
  RankingPeriod? lastMyRankPeriod;

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) async {
    lastRankingPeriod = period;
    return rankingResult;
  }

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) async {
    lastMyRankPeriod = period;
    return myRankResult;
  }

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
  }) => throw UnimplementedError();

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) =>
      throw UnimplementedError();
}

void main() {
  late _FakeArenaRankingRepository rankingRepository;
  late AuthCubit authCubit;
  late MembershipStatusCubit membershipStatusCubit;
  late RankingCubit cubit;

  setUp(() {
    rankingRepository = _FakeArenaRankingRepository();
    authCubit = AuthCubit(FakeAuthRepository());
    membershipStatusCubit = MembershipStatusCubit(
      FakeMembershipRepository(),
      authCubit,
    );
    cubit = RankingCubit(rankingRepository, membershipStatusCubit);
  });

  tearDown(() async {
    await cubit.close();
    await membershipStatusCubit.close();
    await authCubit.close();
  });

  test('estado inicial fica em LoadStatus.initial, período allTime', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.period, RankingPeriod.allTime);
  });

  group('load', () {
    test('sucesso combina o ranking com a posição própria', () async {
      rankingRepository.rankingResult = const Success([_me, _other]);
      rankingRepository.myRankResult = const Success((
        rank: 1,
        totalScore: 100,
      ));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.entries.length, 2);
      expect(cubit.state.myRank, (rank: 1, totalScore: 100));
    });

    test(
      'marca isMember na PRÓPRIA linha, nunca na de outro usuário',
      () async {
        membershipStatusCubit.emit(
          MembershipStatusState(
            status: LoadStatus.success,
            membership: buildMembership(),
          ),
        );
        rankingRepository.rankingResult = const Success([_me, _other]);

        await cubit.load();

        final me = cubit.state.entries.firstWhere((e) => e.isMe);
        final other = cubit.state.entries.firstWhere((e) => !e.isMe);
        expect(me.isMember, isTrue);
        expect(other.isMember, isFalse);
      },
    );

    test('sucesso vazio emite LoadStatus.empty', () async {
      rankingRepository.rankingResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test('falha no ranking emite error', () async {
      rankingRepository.rankingResult = const Error(ServerFailure('erro'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
    });

    test('sem posição própria, myRank fica nulo', () async {
      rankingRepository.rankingResult = const Success([_other]);
      rankingRepository.myRankResult = const Success(null);

      await cubit.load();

      expect(cubit.state.myRank, isNull);
    });
  });

  group('selectPeriod', () {
    test('período diferente recarrega com o novo período', () async {
      await cubit.selectPeriod(RankingPeriod.weekly);

      expect(cubit.state.period, RankingPeriod.weekly);
      expect(rankingRepository.lastRankingPeriod, RankingPeriod.weekly);
      expect(rankingRepository.lastMyRankPeriod, RankingPeriod.weekly);
    });

    test('mesmo período que já está selecionado não recarrega', () async {
      await cubit.load();
      rankingRepository.lastRankingPeriod = null;

      await cubit.selectPeriod(RankingPeriod.allTime);

      expect(rankingRepository.lastRankingPeriod, isNull);
    });
  });
}
