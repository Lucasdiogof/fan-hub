import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';

class FakeFootballRepository implements FootballRepository {
  Result<
    ({
      CompetitionRef competition,
      List<Standing> table,
      List<StandingGroup> groups,
    })
  >
  Function()?
  getStandingsCall;

  Result<List<CompetitionRef>> competitionsResult = const Success([]);

  Result<({CompetitionRef competition, CompetitionSeason season})> Function()?
  getCompetitionSeasonCall;

  Result<
    ({List<Match> matches, String? roundLabel, bool hasPrevious, bool hasNext})
  >
  Function()?
  getCurrentRoundCall;

  Result<({Match? nextMatch, List<Match> recentResults})> Function()?
  getActiveClubSnapshotCall;

  Result<List<Match>> seasonFixturesResult = const Success([]);

  Result<
    ({
      Match match,
      List<MatchEvent> events,
      MatchLineups? lineups,
      List<MatchStat> stats,
    })
  >
  Function()?
  getMatchDetailsCall;

  int getMatchDetailsCallCount = 0;
  String? lastFixtureId;

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
  getStandings({String? competitionId}) async => getStandingsCall!();

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      competitionsResult;

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) async =>
      getCompetitionSeasonCall!();

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
  getCurrentRound({int offset = 0}) async => getCurrentRoundCall!();

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async => getActiveClubSnapshotCall!();

  @override
  Future<Result<List<Match>>> getSeasonFixtures() async => seasonFixturesResult;

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
  getMatchDetails(String fixtureId) async {
    getMatchDetailsCallCount++;
    lastFixtureId = fixtureId;
    return getMatchDetailsCall!();
  }
}
