import 'package:goias_app/features/match/data/dto/team_dto.dart';
import 'package:goias_app/features/match/data/mappers/api_football_match_status_mapper.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

class MatchDto {
  const MatchDto({
    required this.fixtureId,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoffIso,
    required this.statusCode,
    this.venueName,
    this.venueCity,
    this.homeScore,
    this.awayScore,
  });

  final int fixtureId;
  final String round;
  final TeamDto homeTeam;
  final TeamDto awayTeam;
  final String kickoffIso;
  final String statusCode;
  final String? venueName;
  final String? venueCity;
  final int? homeScore;
  final int? awayScore;

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'] as Map<String, dynamic>?;
    return MatchDto(
      fixtureId: json['fixtureId'] as int,
      round: json['round'] as String? ?? '',
      homeTeam: TeamDto.fromJson(json['homeTeam'] as Map<String, dynamic>),
      awayTeam: TeamDto.fromJson(json['awayTeam'] as Map<String, dynamic>),
      kickoffIso: json['kickoff'] as String,
      statusCode: json['status'] as String? ?? 'TBD',
      venueName: venue?['name'] as String?,
      venueCity: venue?['city'] as String?,
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
    );
  }

  Match toEntity({required String competitionName}) {
    return Match(
      id: fixtureId.toString(),
      competition: competitionName,
      round: round,
      homeTeam: homeTeam.toEntity(),
      awayTeam: awayTeam.toEntity(),
      stadium: venueName ?? '',
      city: venueCity,
      kickoff: toBrazilTime(DateTime.parse(kickoffIso)),
      status: ApiFootballMatchStatusMapper.map(statusCode),
      homeScore: homeScore,
      awayScore: awayScore,
    );
  }
}
