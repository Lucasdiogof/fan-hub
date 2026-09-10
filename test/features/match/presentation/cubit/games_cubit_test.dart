import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/data/selected_competition_storage.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _primary = CompetitionRef(
  id: 'primary',
  name: 'Brasileirão Série A',
  format: CompetitionFormat.leagueTable,
  isClubParticipating: true,
);
const _secondary = CompetitionRef(
  id: 'sudamericana',
  name: 'CONMEBOL Sudamericana',
  format: CompetitionFormat.groupStage,
);

Standing _standing(int teamId) => Standing(
  position: 1,
  team: Team(
    id: teamId,
    name: 'Time $teamId',
    shortName: 'T$teamId',
    color: const Color(0xFF000000),
  ),
  isActiveClub: false,
  points: 10,
  played: 6,
  wins: 3,
  draws: 1,
  losses: 2,
  goalDifference: 3,
);

class _FakeFootballRepository implements FootballRepository {
  List<CompetitionRef> competitions = [_primary];
  int getStandingsCallCount = 0;
  String? lastRequestedCompetitionId;
  Match? nextMatch;

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      Success(competitions);

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
  getStandings({String? competitionId}) async {
    getStandingsCallCount++;
    lastRequestedCompetitionId = competitionId;
    final resolved = competitionId == 'sudamericana' ? _secondary : _primary;
    if (resolved.format == CompetitionFormat.groupStage) {
      return Success((
        competition: resolved,
        table: const [],
        groups: [
          StandingGroup(title: 'Grupo H', standings: [_standing(1)]),
        ],
      ));
    }
    return Success((
      competition: resolved,
      table: [_standing(2)],
      groups: const [],
    ));
  }

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async =>
      Success((nextMatch: nextMatch, recentResults: const []));

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
  Future<Result<List<Match>>> getSeasonFixtures() async => const Success([]);

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFootballRepository repository;

  setUp(() {
    repository = _FakeFootballRepository();
  });

  test(
    'sem preferência salva: carrega a competição principal (LEAGUE_TABLE)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = GamesCubit(
        repository,
        SelectedCompetitionStorage(goiasClubConfig),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.standingsStatus, LoadStatus.success);
      expect(cubit.state.selectedCompetition, _primary);
      expect(cubit.state.standings, [_standing(2)]);
      expect(cubit.state.standingGroups, isEmpty);
      addTearDown(cubit.close);
    },
  );

  test(
    'com preferência salva válida: carrega essa competição desde o início (GROUP_STAGE)',
    () async {
      SharedPreferences.setMockInitialValues({
        'goias:games_selected_competition_id': 'sudamericana',
      });
      repository.competitions = [_primary, _secondary];
      final cubit = GamesCubit(
        repository,
        SelectedCompetitionStorage(goiasClubConfig),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedCompetition, _secondary);
      expect(cubit.state.standings, isEmpty);
      expect(cubit.state.standingGroups, [
        StandingGroup(title: 'Grupo H', standings: [_standing(1)]),
      ]);
      expect(repository.lastRequestedCompetitionId, 'sudamericana');
      addTearDown(cubit.close);
    },
  );

  test(
    'preferência salva que não existe mais na lista de competições -> ignora, cai pra principal',
    () async {
      SharedPreferences.setMockInitialValues({
        'goias:games_selected_competition_id': 'competicao-que-sumiu',
      });
      final cubit = GamesCubit(
        repository,
        SelectedCompetitionStorage(goiasClubConfig),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedCompetition, _primary);
      addTearDown(cubit.close);
    },
  );

  test('selectCompetition salva a escolha e recarrega pra ela', () async {
    SharedPreferences.setMockInitialValues({});
    repository.competitions = [_primary, _secondary];
    final storage = SelectedCompetitionStorage(goiasClubConfig);
    final cubit = GamesCubit(repository, storage);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    await cubit.selectCompetition('sudamericana');

    expect(cubit.state.selectedCompetition, _secondary);
    expect(await storage.read(), 'sudamericana');
    addTearDown(cubit.close);
  });

  test('refresh() preserva a competição selecionada, nunca volta pra principal', () async {
    SharedPreferences.setMockInitialValues({});
    repository.competitions = [_primary, _secondary];
    final cubit = GamesCubit(
      repository,
      SelectedCompetitionStorage(goiasClubConfig),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await cubit.selectCompetition('sudamericana');

    await cubit.refresh();

    expect(cubit.state.selectedCompetition, _secondary);
    addTearDown(cubit.close);
  });

  test(
    'sem preferência salva: abre na competição do PRÓXIMO JOGO, casada por nome (spec item 1)',
    () async {
      SharedPreferences.setMockInitialValues({});
      repository.competitions = [_primary, _secondary];
      repository.nextMatch = const Match(
        id: 'next',
        competition: 'CONMEBOL Sudamericana', // nome cru, sem patrocinador
        round: 'Quartas de final',
        homeTeam: Team(
          id: 1,
          name: 'RB Bragantino',
          shortName: 'RBB',
          color: Color(0xFF000000),
        ),
        awayTeam: Team(
          id: 2,
          name: 'Adversário',
          shortName: 'ADV',
          color: Color(0xFF000000),
        ),
        stadium: '',
        status: MatchStatus.scheduled,
      );
      final cubit = GamesCubit(
        repository,
        SelectedCompetitionStorage(goiasClubConfig),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedCompetition, _secondary);
      expect(repository.lastRequestedCompetitionId, 'sudamericana');
      addTearDown(cubit.close);
    },
  );

  test(
    'preferência salva tem prioridade sobre a competição do próximo jogo',
    () async {
      SharedPreferences.setMockInitialValues({
        'goias:games_selected_competition_id': 'primary',
      });
      repository.competitions = [_primary, _secondary];
      repository.nextMatch = const Match(
        id: 'next',
        competition: 'CONMEBOL Sudamericana',
        round: 'Quartas de final',
        homeTeam: Team(
          id: 1,
          name: 'RB Bragantino',
          shortName: 'RBB',
          color: Color(0xFF000000),
        ),
        awayTeam: Team(
          id: 2,
          name: 'Adversário',
          shortName: 'ADV',
          color: Color(0xFF000000),
        ),
        stadium: '',
        status: MatchStatus.scheduled,
      );
      final cubit = GamesCubit(
        repository,
        SelectedCompetitionStorage(goiasClubConfig),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selectedCompetition, _primary);
      addTearDown(cubit.close);
    },
  );

  test(
    'getCompetitions falhando não impede ver a classificação principal',
    () async {
      SharedPreferences.setMockInitialValues({});
      repository = _FakeFootballRepository();
      final failingRepository = _FailingCompetitionsRepository(repository);
      final cubit = GamesCubit(
        failingRepository,
        SelectedCompetitionStorage(goiasClubConfig),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.standingsStatus, LoadStatus.success);
      expect(cubit.state.competitions, isEmpty);
      expect(cubit.state.selectedCompetition, _primary);
      addTearDown(cubit.close);
    },
  );
}

/// Decorator que só quebra `getCompetitions`, delega o resto pro fake real
/// — testa que uma falha nesse endpoint específico não impede ver a
/// classificação principal (só o seletor fica vazio).
class _FailingCompetitionsRepository implements FootballRepository {
  _FailingCompetitionsRepository(this._delegate);
  final FootballRepository _delegate;

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      const Error(ServerFailure());

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
  getStandings({String? competitionId}) =>
      _delegate.getStandings(competitionId: competitionId);

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() => _delegate.getActiveClubSnapshot();

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
  getCurrentRound({int offset = 0}) => _delegate.getCurrentRound(offset: offset);

  @override
  Future<Result<List<Match>>> getSeasonFixtures() =>
      _delegate.getSeasonFixtures();

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
  getMatchDetails(String fixtureId) => _delegate.getMatchDetails(fixtureId);
}
