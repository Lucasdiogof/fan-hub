import 'package:dio/dio.dart';
import 'package:goias_app/features/match/data/dto/competition_dto.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';

/// Só sabe conversar com o nosso backend interno (`/api/football/*`) —
/// nunca com a API-Football diretamente, e nunca vê a API key.
class FootballRemoteDataSource {
  FootballRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({CompetitionDto competition, List<MatchDto> matches})> getFixtures({
    required String scope,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/football/fixtures',
      queryParameters: {'scope': scope},
    );
    final data = response.data!;
    return (
      competition: CompetitionDto.fromJson(data['competition'] as Map<String, dynamic>),
      matches: (data['matches'] as List)
          .map((m) => MatchDto.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<({CompetitionDto competition, MatchDto match})> getFixtureDetails(int fixtureId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/football/fixtures/$fixtureId');
    final data = response.data!;
    return (
      competition: CompetitionDto.fromJson(data['competition'] as Map<String, dynamic>),
      match: MatchDto.fromJson(data['match'] as Map<String, dynamic>),
    );
  }

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
}
