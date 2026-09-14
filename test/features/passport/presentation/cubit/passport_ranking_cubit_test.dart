import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_ranking_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _entry = PassportRankingEntry(
  rank: 1,
  userId: 'u1',
  name: 'Torcedor Teste',
  matchCount: 30,
  isMe: true,
);

class _FakePassportRepository implements PassportRepository {
  Result<List<PassportRankingEntry>> rankingResult = const Success([]);
  Result<({int rank, int matchCount})?> myRankResult = const Success(null);
  int? lastRankingYear;
  int? lastMyRankYear;

  @override
  Future<Result<List<PassportRankingEntry>>> getRanking({
    int? year,
    int limit = 50,
  }) async {
    lastRankingYear = year;
    return rankingResult;
  }

  @override
  Future<Result<({int rank, int matchCount})?>> getMyRank({int? year}) async {
    lastMyRankYear = year;
    return myRankResult;
  }

  @override
  Future<Result<List<PassportSeason>>> getSeasons() =>
      throw UnimplementedError();

  @override
  Future<Result<List<PassportMatch>>> getMatchesForYear(int year) =>
      throw UnimplementedError();

  @override
  Future<Result<PassportSummary>> getSummary({String? userId}) =>
      throw UnimplementedError();

  @override
  Future<Result<PassportAttendanceBreakdown>> getAttendanceBreakdown({
    String? userId,
  }) => throw UnimplementedError();

  @override
  Future<Result<PassportStadiumSummary>> getStadiumSummary({String? userId}) =>
      throw UnimplementedError();

  @override
  Future<Result<List<PassportMatch>>> getAttendedMatches({String? userId}) =>
      throw UnimplementedError();

  @override
  Future<Result<String?>> getMemorableMatchId({String? userId}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> setMemorableMatch(String matchId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<PassportAttendanceChangeResult>>> saveAttendances(
    List<PassportAttendanceChange> changes,
  ) => throw UnimplementedError();
}

void main() {
  late _FakePassportRepository repository;
  late PassportRankingCubit cubit;

  setUp(() {
    repository = _FakePassportRepository();
    cubit = PassportRankingCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, ano geral', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.year, isNull);
  });

  group('load', () {
    test('sucesso combina o ranking com a posição do usuário atual', () async {
      repository.rankingResult = const Success([_entry]);
      repository.myRankResult = const Success((rank: 1, matchCount: 30));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.entries, [_entry]);
      expect(cubit.state.myRank, 1);
      expect(cubit.state.myMatchCount, 30);
    });

    test('sucesso vazio emite LoadStatus.empty', () async {
      repository.rankingResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test(
      'sem posição própria (ainda não marcou nada), myRank fica nulo',
      () async {
        repository.rankingResult = const Success([_entry]);
        repository.myRankResult = const Success(null);

        await cubit.load();

        expect(cubit.state.myRank, isNull);
        expect(cubit.state.myMatchCount, isNull);
      },
    );

    test(
      'falha no ranking emite error, mesmo se getMyRank funcionasse',
      () async {
        repository.rankingResult = const Error(ServerFailure('indisponível'));

        await cubit.load();

        expect(cubit.state.status, LoadStatus.error);
        expect(cubit.state.errorMessage, 'indisponível');
      },
    );

    test(
      'load(year: X) passa o ano pros dois métodos do repositório',
      () async {
        await cubit.load(year: 2024);

        expect(repository.lastRankingYear, 2024);
        expect(repository.lastMyRankYear, 2024);
        expect(cubit.state.year, 2024);
      },
    );
  });

  test('selectYear chama load com o ano escolhido', () async {
    await cubit.selectYear(2023);
    expect(cubit.state.year, 2023);
    expect(repository.lastRankingYear, 2023);
  });

  test('refresh recarrega mantendo o ano atual do state', () async {
    await cubit.selectYear(2023);
    await cubit.refresh();
    expect(repository.lastRankingYear, 2023);
  });
}
