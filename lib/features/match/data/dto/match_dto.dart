import 'package:goias_app/features/match/data/dto/team_dto.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

class MatchDto {
  const MatchDto({
    required this.id,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoffRaw,
    required this.statusName,
    this.venue,
    this.homeScore,
    this.awayScore,
    this.minute,
    this.competition,
  });

  final String id;
  final String round;
  final TeamDto homeTeam;
  final TeamDto awayTeam;

  /// Só vem preenchido no endpoint de temporada (`getSeasonFixtures`), onde
  /// cada partida pode ser de uma competição diferente (Goianão, Brasileirão
  /// Série B, Copa do Brasil...) — os outros endpoints têm UM `competition`
  /// só no nível da resposta inteira (ver `toEntity`).
  final String? competition;

  /// Horário já em hora local do Brasil, sem offset (a fonte não fornece
  /// UTC) — parseado direto, nunca convertido por fuso. `null` quando a
  /// fonte ainda não confirmou o horário (visto em jogos futuros do
  /// TheSportsDB antes da data ser fechada).
  final String? kickoffRaw;
  final String statusName;
  final String? venue;
  final int? homeScore;
  final int? awayScore;
  final String? minute;

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    return MatchDto(
      id: json['id'] as String,
      round: json['round'] as String? ?? '',
      homeTeam: TeamDto.fromJson(json['homeTeam'] as Map<String, dynamic>),
      awayTeam: TeamDto.fromJson(json['awayTeam'] as Map<String, dynamic>),
      kickoffRaw: json['kickoff'] as String?,
      statusName: json['status'] as String? ?? 'unknown',
      venue: json['venue'] as String?,
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      minute: json['minute'] as String?,
      competition: json['competition'] as String?,
    );
  }

  Match toEntity({required String competitionName}) {
    return Match(
      id: id,
      competition: competition ?? competitionName,
      round: round,
      homeTeam: homeTeam.toEntity(),
      awayTeam: awayTeam.toEntity(),
      stadium: venue ?? '',
      kickoff: kickoffRaw != null ? DateTime.parse(kickoffRaw!) : null,
      status: MatchStatus.values.asNameMap()[statusName] ?? MatchStatus.unknown,
      homeScore: homeScore,
      awayScore: awayScore,
      minute: minute,
    );
  }
}
