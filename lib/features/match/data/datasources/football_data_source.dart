import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/competition_season_dto.dart';
import 'package:goias_app/features/match/data/dto/lineup_dto.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/data/dto/match_event_dto.dart';
import 'package:goias_app/features/match/data/dto/match_stat_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_group_dto.dart';

/// Fonte dos dados de futebol (contrato JSON único, ver DTOs). Implementações:
/// `FootballRemoteDataSource` (Worker) e `FootballSnapshotDataSource`
/// (Supabase) — as duas coexistem só durante o rollout (ver
/// `FootballSource`); depois do corte fica apenas a de snapshot.
abstract interface class FootballDataSource {
  Future<
    ({
      CompetitionDto competition,
      List<StandingDto> standings,
      List<StandingGroupDto> groups,
      CompetitionSeasonDto? season,
    })
  >
  getStandings({String? competitionId});

  Future<List<CompetitionRefDto>> getCompetitions();

  Future<
    ({
      CompetitionDto competition,
      List<MatchDto> matches,
      String? roundLabel,
      bool hasPrevious,
      bool hasNext,
    })
  >
  getCurrentRound({int offset = 0});

  Future<
    ({
      CompetitionDto competition,
      MatchDto? nextMatch,
      List<MatchDto> recentResults,
    })
  >
  getActiveClubSnapshot();

  Future<List<MatchDto>> getSeasonFixtures();

  Future<
    ({
      CompetitionDto competition,
      MatchDto match,
      List<MatchEventDto> events,
      MatchLineupsDto? lineups,
      List<MatchStatDto> stats,
    })
  >
  getFixtureDetails(String fixtureId);
}

/// Parsing do contrato JSON único de futebol — compartilhado pelas duas
/// implementações (Worker e Snapshot), que entregam exatamente o mesmo
/// formato; nunca parsing de JSON cru do OneFootball no app.
class FootballJson {
  const FootballJson._();

  static ({
    CompetitionDto competition,
    List<StandingDto> standings,
    List<StandingGroupDto> groups,
    CompetitionSeasonDto? season,
  })
  getStandings(Map<String, dynamic> data) => (
    competition: CompetitionDto.fromJson(
      data['competition'] as Map<String, dynamic>,
    ),
    standings: ((data['standings'] as List?) ?? const [])
        .map((s) => StandingDto.fromJson(s as Map<String, dynamic>))
        .toList(),
    groups: ((data['groups'] as List?) ?? const [])
        .map((g) => StandingGroupDto.fromJson(g as Map<String, dynamic>))
        .toList(),
    // `null` só em cache/deploy antigo sem o campo — o repositório monta uma
    // temporada de 1 fase a partir de `standings`/`groups` nesse caso.
    season: data['season'] != null
        ? CompetitionSeasonDto.fromJson(data['season'] as Map<String, dynamic>)
        : null,
  );

  static List<CompetitionRefDto> getCompetitions(Map<String, dynamic> data) =>
      (data['competitions'] as List)
          .map((c) => CompetitionRefDto.fromJson(c as Map<String, dynamic>))
          .toList();

  static ({
    CompetitionDto competition,
    List<MatchDto> matches,
    String? roundLabel,
    bool hasPrevious,
    bool hasNext,
  })
  getCurrentRound(Map<String, dynamic> data) {
    final round = data['round'] as Map<String, dynamic>?;
    return (
      competition: CompetitionDto.fromJson(
        data['competition'] as Map<String, dynamic>,
      ),
      matches: (data['matches'] as List)
          .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
          .toList(),
      roundLabel: round?['label'] as String?,
      hasPrevious: data['hasPrevious'] as bool? ?? false,
      hasNext: data['hasNext'] as bool? ?? false,
    );
  }

  static ({
    CompetitionDto competition,
    MatchDto? nextMatch,
    List<MatchDto> recentResults,
  })
  getActiveClubSnapshot(Map<String, dynamic> data) {
    final nextMatchJson = data['nextMatch'] as Map<String, dynamic>?;
    return (
      competition: CompetitionDto.fromJson(
        data['competition'] as Map<String, dynamic>,
      ),
      nextMatch: nextMatchJson != null
          ? MatchDto.fromJson(nextMatchJson)
          : null,
      recentResults: (data['recentResults'] as List)
          .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<MatchDto> getSeasonFixtures(Map<String, dynamic> data) =>
      (data['matches'] as List)
          .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
          .toList();

  static ({
    CompetitionDto competition,
    MatchDto match,
    List<MatchEventDto> events,
    MatchLineupsDto? lineups,
    List<MatchStatDto> stats,
  })
  getFixtureDetails(Map<String, dynamic> data) {
    final lineupsJson = data['lineups'] as Map<String, dynamic>?;
    return (
      competition: CompetitionDto.fromJson(
        data['competition'] as Map<String, dynamic>,
      ),
      match: MatchDto.fromJson(data['match'] as Map<String, dynamic>),
      events: ((data['events'] as List?) ?? [])
          .map((e) => MatchEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      lineups: lineupsJson != null
          ? MatchLineupsDto.fromJson(lineupsJson)
          : null,
      stats: ((data['stats'] as List?) ?? [])
          .map((s) => MatchStatDto.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
