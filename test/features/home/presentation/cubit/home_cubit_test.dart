import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _goias = Team(
  id: 1863,
  name: 'Goiás',
  shortName: 'GO',
  color: Color(0xFF004C1B),
);
const _opponent = Team(
  id: 2,
  name: 'Fortaleza',
  shortName: 'FOR',
  color: Color(0xFF1F6F4A),
);

Match _match({
  required String id,
  required MatchStatus status,
  DateTime? kickoff,
  int? homeScore,
  int? awayScore,
}) => Match(
  id: id,
  competition: 'Brasileirão Série B',
  round: 'Rodada 20',
  homeTeam: _goias,
  awayTeam: _opponent,
  stadium: 'Serrinha',
  kickoff: kickoff,
  status: status,
  homeScore: homeScore,
  awayScore: awayScore,
);

class _FakeFootballRepository implements FootballRepository {
  Match? nextMatch;
  List<Match> recentResults = const [];

  /// Quando setado, `getActiveClubSnapshot` retorna `Error` com isto em vez de
  /// funcionar normalmente — pra testar o estado de erro do `HomeCubit`.
  Failure? failure;

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async {
    final currentFailure = failure;
    if (currentFailure != null) return Error(currentFailure);
    return Success((nextMatch: nextMatch, recentResults: recentResults));
  }

  @override
  Future<
    Result<
      ({
        CompetitionRef competition,
        List<Standing> table,
        List<StandingGroup> groups,
      })
    >
  >
  getStandings({String? competitionId}) async => const Success((
    competition: CompetitionRef(
      id: 'primary',
      name: '',
      format: CompetitionFormat.leagueTable,
    ),
    table: [],
    groups: [],
  ));

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      const Success([]);

  @override
  Future<
    Result<
      ({
        List<Match> matches,
        String? roundLabel,
        bool hasPrevious,
        bool hasNext,
      })
    >
  >
  getCurrentRound({int offset = 0}) async => const Success((
    matches: [],
    roundLabel: null,
    hasPrevious: false,
    hasNext: false,
  ));

  @override
  Future<
    Result<
      ({
        Match match,
        List<MatchEvent> events,
        MatchLineups? lineups,
        List<MatchStat> stats,
      })
    >
  >
  getMatchDetails(String fixtureId) async => throw UnimplementedError();

  @override
  Future<Result<List<Match>>> getSeasonFixtures() async =>
      throw UnimplementedError();
}

class _FakeCrowdLineupRepository implements CrowdLineupRepository {
  @override
  Future<Result<LineupVote?>> getMyVote(String matchId) async =>
      const Success(null);

  @override
  Future<Result<void>> submitVote(String matchId, LineupVote vote) async =>
      throw UnimplementedError();

  @override
  Future<Result<CrowdLineup>> getCrowdLineup(String matchId) async =>
      throw UnimplementedError();
}

void main() {
  late _FakeFootballRepository football;

  setUp(() => football = _FakeFootballRepository());

  HomeCubit build() {
    final cubit = HomeCubit(football, _FakeCrowdLineupRepository());
    addTearDown(cubit.close);
    return cubit;
  }

  test('shows the upcoming match when there is no recent result', () async {
    football.nextMatch = _match(
      id: 'next',
      status: MatchStatus.scheduled,
      kickoff: DateTime.now().add(const Duration(days: 3)),
    );
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.nextMatch?.id, 'next');
  });

  test(
    'a match finished less than a day ago takes priority over the next match',
    () async {
      football.nextMatch = _match(
        id: 'next',
        status: MatchStatus.scheduled,
        kickoff: DateTime.now().add(const Duration(days: 3)),
      );
      football.recentResults = [
        _match(
          id: 'just-finished',
          status: MatchStatus.finished,
          kickoff: DateTime.now().subtract(const Duration(hours: 5)),
          homeScore: 2,
          awayScore: 1,
        ),
      ];
      final cubit = build();
      await cubit.load();

      expect(cubit.state.nextMatch?.id, 'just-finished');
      expect(cubit.state.nextMatch?.status, MatchStatus.finished);
    },
  );

  test(
    'a match finished more than a day ago (plus the grace buffer) falls back to the next match',
    () async {
      football.nextMatch = _match(
        id: 'next',
        status: MatchStatus.scheduled,
        kickoff: DateTime.now().add(const Duration(days: 3)),
      );
      football.recentResults = [
        _match(
          id: 'old-result',
          status: MatchStatus.finished,
          kickoff: DateTime.now().subtract(const Duration(days: 2)),
          homeScore: 2,
          awayScore: 1,
        ),
      ];
      final cubit = build();
      await cubit.load();

      expect(cubit.state.nextMatch?.id, 'next');
    },
  );

  test(
    'a recently finished match still shows even with no next match available',
    () async {
      football.nextMatch = null;
      football.recentResults = [
        _match(
          id: 'just-finished',
          status: MatchStatus.finished,
          kickoff: DateTime.now().subtract(const Duration(hours: 2)),
          homeScore: 0,
          awayScore: 0,
        ),
      ];
      final cubit = build();
      await cubit.load();

      expect(cubit.state.nextMatch?.id, 'just-finished');
    },
  );

  test(
    'no next match and no recent result clears the match, but is still SUCCESS (not error)',
    () async {
      football.nextMatch = null;
      football.recentResults = const [];
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.nextMatch, isNull);
      expect(cubit.state.errorMessage, isNull);
    },
  );

  test('a live match is shown regardless of any recent result', () async {
    football.nextMatch = _match(id: 'live', status: MatchStatus.live);
    football.recentResults = [
      _match(
        id: 'old-result',
        status: MatchStatus.finished,
        kickoff: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
    final cubit = build();
    await cubit.load();

    expect(cubit.state.nextMatch?.id, 'live');
  });

  test('load() transitions through LOADING before settling', () async {
    football.nextMatch = _match(
      id: 'next',
      status: MatchStatus.scheduled,
      kickoff: DateTime.now().add(const Duration(days: 1)),
    );
    final cubit = HomeCubit(football, _FakeCrowdLineupRepository());
    addTearDown(cubit.close);

    final future = expectLater(
      cubit.stream,
      emitsThrough(
        predicate<HomeState>(
          (state) =>
              state.status == LoadStatus.success &&
              state.nextMatch?.id == 'next',
        ),
      ),
    );
    expect(cubit.state.status, LoadStatus.loading);
    await future;
  });

  group('error state (never confused with "no next match")', () {
    test(
      'a failed load is represented as ERROR, not as an empty match',
      () async {
        football.failure = const NetworkFailure('sem conexão');
        final cubit = build();
        await cubit.load();

        expect(cubit.state.status, LoadStatus.error);
        expect(cubit.state.nextMatch, isNull);
        expect(cubit.state.errorMessage, 'sem conexão');
      },
    );

    test(
      'retry after an error recovers to SUCCESS once the call works',
      () async {
        football.failure = const NetworkFailure('sem conexão');
        final cubit = build();
        await cubit.load();
        expect(cubit.state.status, LoadStatus.error);

        football.failure = null;
        football.nextMatch = _match(
          id: 'recovered',
          status: MatchStatus.scheduled,
          kickoff: DateTime.now().add(const Duration(days: 1)),
        );
        await cubit.load();

        expect(cubit.state.status, LoadStatus.success);
        expect(cubit.state.nextMatch?.id, 'recovered');
        expect(cubit.state.errorMessage, isNull);
      },
    );

    test('retry after an error that fails again stays in ERROR', () async {
      football.failure = const NetworkFailure('sem conexão');
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);

      football.failure = const ServerFailure('servidor indisponível');
      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.nextMatch, isNull);
      expect(cubit.state.errorMessage, 'servidor indisponível');
    });
  });
}
