import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_trajectory_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

// A lógica de "quem ganhou/quantos gols/qual estádio foi mais visitado/
// desempate entre estádios" mora inteiramente nas RPCs do Supabase
// (passport_attendance_breakdown, passport_stadium_summary), não no
// Flutter — este projeto não tem infraestrutura de teste de SQL (sem
// pgTAP, sem Postgres local em CI), então esses cálculos não têm como
// virar um `flutter test`; foram verificados manualmente rodando as
// migrações reais (mesmo processo já usado pra `passport_attendance_breakdown`
// nesta mesma sessão). Os testes aqui cobrem o que É lógica Dart de
// verdade: como o Cubit combina os 5 resultados do repositório em estado,
// resolve o jogo memorável, e lida com falha parcial/seleção/desmarcação.
class _FakeTrajectoryRepository implements PassportRepository {
  PassportSummary summary = PassportSummary.empty;
  PassportAttendanceBreakdown breakdown = PassportAttendanceBreakdown.empty;
  PassportStadiumSummary stadiumSummary = PassportStadiumSummary.empty;
  List<PassportMatch> attendedMatches = const [];
  String? memorableMatchId;

  bool failSummary = false;
  bool failBreakdown = false;
  bool failStadium = false;
  bool failAttended = false;
  bool failMemorableId = false;
  bool failSetMemorable = false;

  String? lastSetMemorableMatchId;

  @override
  Future<Result<PassportSummary>> getSummary() async {
    if (failSummary) return const Error(ServerFailure('falhou'));
    return Success(summary);
  }

  @override
  Future<Result<PassportAttendanceBreakdown>> getAttendanceBreakdown() async {
    if (failBreakdown) return const Error(ServerFailure('falhou'));
    return Success(breakdown);
  }

  @override
  Future<Result<PassportStadiumSummary>> getStadiumSummary() async {
    if (failStadium) return const Error(ServerFailure('falhou'));
    return Success(stadiumSummary);
  }

  @override
  Future<Result<List<PassportMatch>>> getAttendedMatches() async {
    if (failAttended) return const Error(ServerFailure('falhou'));
    return Success(attendedMatches);
  }

  @override
  Future<Result<String?>> getMemorableMatchId() async {
    if (failMemorableId) return const Error(ServerFailure('falhou'));
    return Success(memorableMatchId);
  }

  @override
  Future<Result<void>> setMemorableMatch(String matchId) async {
    lastSetMemorableMatchId = matchId;
    if (failSetMemorable) {
      return const Error(ServerFailure('não salvou'));
    }
    memorableMatchId = matchId;
    return const Success(null);
  }

  @override
  Future<Result<List<PassportSeason>>> getSeasons() async => const Success([]);

  @override
  Future<Result<List<PassportMatch>>> getMatchesForYear(int year) async =>
      const Success([]);

  @override
  Future<Result<List<PassportAttendanceChangeResult>>> saveAttendances(
    List<PassportAttendanceChange> changes,
  ) async => const Success([]);

  @override
  Future<Result<List<PassportRankingEntry>>> getRanking({
    int? year,
    int limit = 50,
  }) async => const Success([]);

  @override
  Future<Result<({int rank, int matchCount})?>> getMyRank({int? year}) async =>
      const Success(null);
}

PassportMatch _attendedMatch(
  String id, {
  int goiasScore = 1,
  int opponentScore = 0,
}) {
  return PassportMatch(
    id: id,
    season: 2026,
    matchDate: DateTime(2026, 5, 10),
    status: PassportMatchStatus.finished,
    competition: 'Campeonato Goiano',
    competitionCode: 'GOIANO',
    opponent: 'Vila Nova',
    goiasScore: goiasScore,
    opponentScore: opponentScore,
    attended: true,
  );
}

void main() {
  late _FakeTrajectoryRepository repository;
  late PassportTrajectoryCubit cubit;

  setUp(() {
    repository = _FakeTrajectoryRepository();
    cubit = PassportTrajectoryCubit(repository);
  });

  test(
    'estado sem nenhuma presença: totalMatches e seasonsCount ficam 0',
    () async {
      repository.summary = const PassportSummary(
        totalMatches: 0,
        yearsWithAttendance: 0,
      );

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.totalMatches, 0);
      expect(cubit.state.seasonsCount, 0);
    },
  );

  test('load combina summary, breakdown, estádios e jogo memorável', () async {
    repository.summary = const PassportSummary(
      totalMatches: 3,
      yearsWithAttendance: 2,
    );
    repository.breakdown = const PassportAttendanceBreakdown(
      totalMatches: 3,
      wins: 2,
      draws: 1,
      losses: 0,
      homeGames: 2,
      awayGames: 1,
      goalsFor: 5,
      goalsAgainst: 2,
    );
    repository.stadiumSummary = const PassportStadiumSummary(
      uniqueStadiums: 1,
      mostVisitedName: 'Estádio Hailé Pinheiro',
      mostVisitedCount: 3,
    );
    final match = _attendedMatch('m1');
    repository.attendedMatches = [match];
    repository.memorableMatchId = 'm1';

    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.totalMatches, 3);
    expect(cubit.state.seasonsCount, 2);
    expect(cubit.state.breakdown.wins, 2);
    expect(cubit.state.goalDifference, 3);
    expect(
      cubit.state.stadiumSummary.mostVisitedName,
      'Estádio Hailé Pinheiro',
    );
    expect(cubit.state.memorableMatch?.id, 'm1');
  });

  test('saldo de gols negativo continua correto', () async {
    repository.breakdown = const PassportAttendanceBreakdown(
      totalMatches: 1,
      wins: 0,
      draws: 0,
      losses: 1,
      homeGames: 0,
      awayGames: 1,
      goalsFor: 1,
      goalsAgainst: 4,
    );

    await cubit.load();

    expect(cubit.state.goalDifference, -3);
  });

  test(
    'estádio sem dado ainda (venue vazio): estado sem mais visitado',
    () async {
      repository.stadiumSummary = PassportStadiumSummary.empty;

      await cubit.load();

      expect(cubit.state.stadiumSummary.uniqueStadiums, 0);
      expect(cubit.state.stadiumSummary.mostVisitedName, isNull);
    },
  );

  test(
    'estado sem jogo memorável selecionado: memorableMatch fica null',
    () async {
      repository.attendedMatches = [_attendedMatch('m1')];
      repository.memorableMatchId = null;

      await cubit.load();

      expect(cubit.state.memorableMatch, isNull);
    },
  );

  test(
    'memorableMatchId que não corresponde a nenhuma partida atendida fica null (defensivo)',
    () async {
      repository.attendedMatches = [_attendedMatch('m1')];
      repository.memorableMatchId = 'partida-que-sumiu';

      await cubit.load();

      expect(cubit.state.memorableMatch, isNull);
    },
  );

  test('falha em getSummary vira estado de erro pra tela inteira', () async {
    repository.failSummary = true;

    await cubit.load();

    expect(cubit.state.status, LoadStatus.error);
  });

  test(
    'falha em getStadiumSummary não impede o resto da tela (cai pro vazio)',
    () async {
      repository.summary = const PassportSummary(
        totalMatches: 1,
        yearsWithAttendance: 1,
      );
      repository.failStadium = true;

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.stadiumSummary, PassportStadiumSummary.empty);
    },
  );

  test(
    'falha em getMemorableMatchId não impede o resto da tela (memorável fica null)',
    () async {
      repository.summary = const PassportSummary(
        totalMatches: 1,
        yearsWithAttendance: 1,
      );
      repository.failMemorableId = true;

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.memorableMatch, isNull);
    },
  );

  test(
    'selectMemorableMatch: só pode escolher entre as partidas "Eu fui" já carregadas',
    () async {
      final match = _attendedMatch('m2', goiasScore: 3, opponentScore: 2);
      repository.attendedMatches = [match];
      await cubit.load();

      final ok = await cubit.selectMemorableMatch(match);

      expect(ok, isTrue);
      expect(repository.lastSetMemorableMatchId, 'm2');
      expect(cubit.state.memorableMatch?.id, 'm2');
      expect(cubit.state.savingMemorableMatch, isFalse);
    },
  );

  test(
    'selectMemorableMatch: falha no servidor não muda a seleção atual',
    () async {
      final first = _attendedMatch('m1');
      final second = _attendedMatch('m2');
      repository.attendedMatches = [first, second];
      repository.memorableMatchId = 'm1';
      await cubit.load();
      expect(cubit.state.memorableMatch?.id, 'm1');

      repository.failSetMemorable = true;
      final ok = await cubit.selectMemorableMatch(second);

      expect(ok, isFalse);
      expect(cubit.state.memorableMatch?.id, 'm1');
      expect(cubit.state.savingMemorableMatch, isFalse);
    },
  );
}
