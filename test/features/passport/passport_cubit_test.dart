import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Dublê em memória — implementa a interface direto, sem precisar de um
/// SupabaseClient de mentira (mesmo padrão já usado em
/// test/features/crowd_lineup/presentation/pages/crowd_lineup_page_test.dart).
class _FakePassportRepository implements PassportRepository {
  List<PassportSeason> seasons = const [];
  Map<int, List<PassportMatch>> matchesByYear = const {};
  PassportSummary summary = PassportSummary.empty;
  bool failSave = false;
  bool failMatches = false;
  List<PassportAttendanceChange>? lastSavedChanges;

  /// Quantas vezes `saveAttendances` foi de fato chamado — pra testar que
  /// um duplo toque/chamada concorrente não dispara dois salvamentos.
  int saveCallCount = 0;

  @override
  Future<Result<List<PassportSeason>>> getSeasons() async => Success(seasons);

  @override
  Future<Result<List<PassportMatch>>> getMatchesForYear(int year) async {
    if (failMatches) {
      return const Error(ServerFailure('falhou'));
    }
    return Success(matchesByYear[year] ?? const []);
  }

  @override
  Future<Result<PassportSummary>> getSummary({String? userId}) async =>
      Success(summary);

  @override
  Future<Result<PassportAttendanceBreakdown>> getAttendanceBreakdown({
    String? userId,
  }) async => const Success(PassportAttendanceBreakdown.empty);

  @override
  Future<Result<List<PassportAttendanceChangeResult>>> saveAttendances(
    List<PassportAttendanceChange> changes,
  ) async {
    saveCallCount++;
    lastSavedChanges = changes;
    // Delay real (não só microtask) — é essa janela assíncrona que um
    // duplo toque/chamada concorrente exploraria sem a guarda no Cubit.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (failSave) {
      return const Error(ServerFailure('não salvou'));
    }
    return Success([
      for (final c in changes)
        PassportAttendanceChangeResult(
          matchId: c.matchId,
          attended: c.attended,
          applied: true,
        ),
    ]);
  }

  @override
  Future<Result<List<PassportRankingEntry>>> getRanking({
    int? year,
    int limit = 50,
  }) async => const Success([]);

  @override
  Future<Result<({int rank, int matchCount})?>> getMyRank({int? year}) async =>
      const Success(null);

  @override
  Future<Result<PassportStadiumSummary>> getStadiumSummary({
    String? userId,
  }) async => const Success(PassportStadiumSummary.empty);

  @override
  Future<Result<List<PassportMatch>>> getAttendedMatches({
    String? userId,
  }) async => const Success([]);

  @override
  Future<Result<String?>> getMemorableMatchId({String? userId}) async =>
      const Success(null);

  @override
  Future<Result<void>> setMemorableMatch(String matchId) async =>
      const Success(null);
}

PassportMatch _finishedMatch(
  String id, {
  int season = 2026,
  bool attended = false,
}) {
  return PassportMatch(
    id: id,
    season: season,
    matchDate: DateTime(season, 1, 1),
    status: PassportMatchStatus.finished,
    competition: 'Campeonato Goiano',
    competitionCode: 'GOIANO',
    opponent: 'Vila Nova',
    attended: attended,
  );
}

PassportMatch _scheduledMatch(String id, {int season = 2026}) {
  return PassportMatch(
    id: id,
    season: season,
    matchDate: DateTime.now().add(const Duration(days: 10)),
    status: PassportMatchStatus.scheduled,
    competition: 'Campeonato Goiano',
    competitionCode: 'GOIANO',
    opponent: 'Vila Nova',
    attended: false,
  );
}

void main() {
  late _FakePassportRepository repository;
  late PassportCubit cubit;

  setUp(() {
    repository = _FakePassportRepository();
    cubit = PassportCubit(repository);
  });

  test(
    'loadInitial carrega temporadas, seleciona o ano mais recente e carrega as partidas dele',
    () async {
      repository.seasons = const [
        PassportSeason(season: 2026, matchCount: 2, finishedCount: 1),
        PassportSeason(season: 2025, matchCount: 3, finishedCount: 3),
      ];
      repository.matchesByYear = {
        2026: [_finishedMatch('m1')],
      };

      await cubit.loadInitial();
      // loadInitial dispara o carregamento das partidas do ano sem esperar
      // (não trava o seletor de ano na resposta das partidas) — drena a
      // fila de microtasks pra esse fire-and-forget terminar antes de checar.
      await pumpEventQueue();

      expect(cubit.state.seasonsStatus, LoadStatus.success);
      expect(cubit.state.selectedYear, 2026);
      expect(cubit.state.matchesStatus, LoadStatus.success);
      expect(cubit.state.matches, hasLength(1));
    },
  );

  test('selectYear troca de temporada e recarrega as partidas', () async {
    repository.seasons = const [
      PassportSeason(season: 2026, matchCount: 1, finishedCount: 1),
      PassportSeason(season: 2025, matchCount: 1, finishedCount: 1),
    ];
    repository.matchesByYear = {
      2026: [_finishedMatch('m1', season: 2026)],
      2025: [_finishedMatch('m2', season: 2025)],
    };
    await cubit.loadInitial();

    await cubit.selectYear(2025);

    expect(cubit.state.selectedYear, 2025);
    expect(cubit.state.matches.single.id, 'm2');
  });

  test('toggleAttendance nunca marca partida agendada', () {
    final scheduled = _scheduledMatch('m1');
    cubit.emit(cubit.state.copyWith(matches: [scheduled]));

    cubit.toggleAttendance(scheduled);

    expect(cubit.state.pendingChanges, isEmpty);
  });

  test(
    'toggleAttendance marca e desmarcar de novo cancela a mudança pendente',
    () {
      final match = _finishedMatch('m1');
      cubit.emit(cubit.state.copyWith(matches: [match]));

      cubit.toggleAttendance(match);
      expect(cubit.state.pendingChanges, {'m1': true});
      expect(cubit.state.hasUnsavedChanges, isTrue);

      cubit.toggleAttendance(match);
      expect(cubit.state.pendingChanges, isEmpty);
      expect(cubit.state.hasUnsavedChanges, isFalse);
    },
  );

  test(
    'save envia só o delta (nunca a lista inteira) e limpa as mudanças aplicadas',
    () async {
      final m1 = _finishedMatch('m1');
      final m2 = _finishedMatch('m2', attended: true);
      cubit.emit(cubit.state.copyWith(matches: [m1, m2]));
      cubit.toggleAttendance(m1); // false -> true
      cubit.toggleAttendance(m2); // true -> false

      await cubit.save();

      expect(repository.lastSavedChanges, hasLength(2));
      expect(cubit.state.pendingChanges, isEmpty);
      expect(cubit.state.saveStatus, LoadStatus.success);
      expect(
        cubit.state.matches.firstWhere((m) => m.id == 'm1').attended,
        isTrue,
      );
      expect(
        cubit.state.matches.firstWhere((m) => m.id == 'm2').attended,
        isFalse,
      );
    },
  );

  test(
    'duas chamadas concorrentes de save() só disparam um salvamento real',
    () async {
      final m1 = _finishedMatch('m1');
      cubit.emit(cubit.state.copyWith(matches: [m1]));
      cubit.toggleAttendance(m1);

      final first = cubit.save();
      final second = cubit.save(); // "segundo toque" durante o 1º save.
      await Future.wait([first, second]);

      expect(repository.saveCallCount, 1);
    },
  );

  test('em erro no save, as seleções locais continuam intactas', () async {
    repository.failSave = true;
    final m1 = _finishedMatch('m1');
    cubit.emit(cubit.state.copyWith(matches: [m1]));
    cubit.toggleAttendance(m1);

    await cubit.save();

    expect(cubit.state.saveStatus, LoadStatus.error);
    expect(cubit.state.pendingChanges, {'m1': true});
    expect(cubit.state.hasUnsavedChanges, isTrue);
  });

  test(
    'filteredMatches aplica o filtro selecionado sem perder as mudanças pendentes',
    () {
      final homeMatch = PassportMatch(
        id: 'home',
        season: 2026,
        matchDate: DateTime(2026, 1, 1),
        status: PassportMatchStatus.finished,
        competition: 'Goiano',
        competitionCode: 'GOIANO',
        opponent: 'Vila Nova',
        clubIsHome: true,
        attended: false,
      );
      final awayMatch = PassportMatch(
        id: 'away',
        season: 2026,
        matchDate: DateTime(2026, 1, 2),
        status: PassportMatchStatus.finished,
        competition: 'Goiano',
        competitionCode: 'GOIANO',
        opponent: 'Vila Nova',
        clubIsHome: false,
        attended: false,
      );
      cubit.emit(cubit.state.copyWith(matches: [homeMatch, awayMatch]));

      cubit.setFilter(PassportFilter.home);

      expect(cubit.state.filteredMatches.map((m) => m.id), ['home']);
    },
  );
}
