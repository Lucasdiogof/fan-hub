import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_details_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

class _FakeRepository implements FootballRepository {
  _FakeRepository(this._result);
  final Result<({CompetitionRef competition, CompetitionSeason season})>
  _result;

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) async => _result;

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      throw UnimplementedError();

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
  getStandings({String? competitionId}) => throw UnimplementedError();

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() => throw UnimplementedError();

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
  getCurrentRound({int offset = 0}) => throw UnimplementedError();

  @override
  Future<Result<List<Match>>> getSeasonFixtures() => throw UnimplementedError();

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
  getMatchDetails(String fixtureId) => throw UnimplementedError();
}

const _competition = CompetitionRef(
  id: 'copa-do-brasil',
  name: 'Copa do Brasil',
  format: CompetitionFormat.knockout,
);

CompetitionStage _stage(String id, {bool isCurrent = false}) =>
    CompetitionStage(
      id: id,
      name: id,
      order: 0,
      type: StageType.knockout,
      status: StageStatus.active,
      isCurrent: isCurrent,
    );

void main() {
  test('load() bem-sucedido -> seleciona a fase atual da temporada', () async {
    final repo = _FakeRepository(
      Success((
        competition: _competition,
        season: CompetitionSeason(
          id: 'copa-do-brasil',
          label: 'Copa do Brasil',
          stages: [_stage('oitavas'), _stage('quartas', isCurrent: true)],
        ),
      )),
    );
    final cubit = CompetitionDetailsCubit(repo, 'copa-do-brasil');
    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.stages, hasLength(2));
    expect(cubit.state.selectedStageId, 'quartas');
    expect(cubit.state.selectedStage?.id, 'quartas');
    addTearDown(cubit.close);
  });

  test('temporada sem nenhuma fase -> status empty', () async {
    final repo = _FakeRepository(
      const Success((
        competition: _competition,
        season: CompetitionSeason(id: 'x', label: 'x', stages: []),
      )),
    );
    final cubit = CompetitionDetailsCubit(repo, 'copa-do-brasil');
    await cubit.load();

    expect(cubit.state.status, LoadStatus.empty);
    addTearDown(cubit.close);
  });

  test('falha de rede -> status error com a mensagem', () async {
    final repo = _FakeRepository(const Error(ServerFailure('offline')));
    final cubit = CompetitionDetailsCubit(repo, 'copa-do-brasil');
    await cubit.load();

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.errorMessage, 'offline');
    addTearDown(cubit.close);
  });

  test(
    'selectStage troca a fase selecionada sem nova chamada de rede',
    () async {
      var callCount = 0;
      final repo = _CountingRepository(
        Success((
          competition: _competition,
          season: CompetitionSeason(
            id: 'copa-do-brasil',
            label: 'Copa do Brasil',
            stages: [_stage('oitavas', isCurrent: true), _stage('quartas')],
          ),
        )),
        onCall: () => callCount++,
      );
      final cubit = CompetitionDetailsCubit(repo, 'copa-do-brasil');
      await cubit.load();
      expect(callCount, 1);

      cubit.selectStage('quartas');
      expect(cubit.state.selectedStageId, 'quartas');
      expect(callCount, 1, reason: 'trocar de fase não deve refazer a rede');
      addTearDown(cubit.close);
    },
  );
}

class _CountingRepository extends _FakeRepository {
  _CountingRepository(super.result, {required this.onCall});
  final void Function() onCall;

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) async {
    onCall();
    return super.getCompetitionSeason(competitionId: competitionId);
  }
}
