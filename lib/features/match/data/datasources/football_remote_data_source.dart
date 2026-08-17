import 'package:dio/dio.dart';
import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';

/// Só sabe conversar com o nosso backend interno (`/api/football/*`) —
/// nunca com campeonato-brasileiro-api ou TheSportsDB diretamente.
class FootballRemoteDataSource {
  FootballRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({CompetitionDto competition, List<StandingDto> standings})> getStandings() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/football/standings');
    final data = response.data!;
    return (
      competition: CompetitionDto.fromJson(data['competition'] as Map<String, dynamic>),
      standings: (data['standings'] as List)
          .map((s) => StandingDto.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<({CompetitionDto competition, List<MatchDto> matches})> getCurrentRound() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/football/current-round');
    final data = response.data!;
    return (
      competition: CompetitionDto.fromJson(data['competition'] as Map<String, dynamic>),
      matches: (data['matches'] as List)
          .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<({CompetitionDto competition, MatchDto? nextMatch, List<MatchDto> recentResults})>
  getGoiasSnapshot() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/football/team/goias');
    final data = response.data!;
    final nextMatchJson = data['nextMatch'] as Map<String, dynamic>?;
    return (
      competition: CompetitionDto.fromJson(data['competition'] as Map<String, dynamic>),
      nextMatch: nextMatchJson != null ? MatchDto.fromJson(nextMatchJson) : null,
      recentResults: (data['recentResults'] as List)
          .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<({CompetitionDto competition, MatchDto match})> getFixtureDetails(String fixtureId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/football/fixtures/$fixtureId');
    final data = response.data!;
    return (
      competition: CompetitionDto.fromJson(data['competition'] as Map<String, dynamic>),
      match: MatchDto.fromJson(data['match'] as Map<String, dynamic>),
    );
  }
}
