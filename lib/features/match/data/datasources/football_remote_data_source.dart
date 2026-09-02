import 'package:dio/dio.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/data/dto/lineup_dto.dart';
import 'package:goias_app/features/match/data/dto/match_event_dto.dart';
import 'package:goias_app/features/match/data/dto/match_stat_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';

/// Só sabe conversar com o nosso backend interno (`/api/football/*`) —
/// nunca com campeonato-brasileiro-api ou TheSportsDB diretamente. As rotas
/// `/team/<code>` e `/team/<code>/season` usam `ClubConfig.identity.code`
/// (M3.3) — o Worker resolve `<code>` num `ClubServerConfig` próprio (ver
/// `src/_shared/club_server_config.ts`); `/team/goias` continua existindo
/// no Worker só como alias legacy, o app novo nunca chama esse literal.
class FootballRemoteDataSource {
  FootballRemoteDataSource(this._dio, this._clubConfig);

  final Dio _dio;
  final ClubConfig _clubConfig;

  Future<({CompetitionDto competition, List<StandingDto> standings})>
  getStandings() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/football/standings',
    );
    final data = response.data!;
    return (
      competition: CompetitionDto.fromJson(
        data['competition'] as Map<String, dynamic>,
      ),
      standings: (data['standings'] as List)
          .map((s) => StandingDto.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<
    ({
      CompetitionDto competition,
      List<MatchDto> matches,
      String? roundLabel,
      bool hasPrevious,
      bool hasNext,
    })
  >
  getCurrentRound({int offset = 0}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/football/current-round',
      queryParameters: offset == 0 ? null : {'offset': offset},
    );
    final data = response.data!;
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

  Future<
    ({
      CompetitionDto competition,
      MatchDto? nextMatch,
      List<MatchDto> recentResults,
    })
  >
  getActiveClubSnapshot() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/football/team/${_clubConfig.identity.code}',
    );
    final data = response.data!;
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

  /// Diferente dos outros: sem `competition` no nível da resposta — cada
  /// partida já carrega a própria (Goianão/Brasileirão/Copa do Brasil
  /// misturados), porque é "temporada inteira do time", não de uma
  /// competição só (ver `MatchDto.competition`).
  Future<List<MatchDto>> getSeasonFixtures() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/football/team/${_clubConfig.identity.code}/season',
    );
    final data = response.data!;
    return (data['matches'] as List)
        .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<
    ({
      CompetitionDto competition,
      MatchDto match,
      List<MatchEventDto> events,
      MatchLineupsDto? lineups,
      List<MatchStatDto> stats,
    })
  >
  getFixtureDetails(String fixtureId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/football/fixtures/$fixtureId',
    );
    final data = response.data!;
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
