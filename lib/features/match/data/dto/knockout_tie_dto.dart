import 'package:goias_app/features/match/data/dto/team_dto.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

class KnockoutLegDto {
  const KnockoutLegDto({
    required this.legType,
    required this.status,
    this.kickoff,
    this.homeScore,
    this.awayScore,
  });

  final String legType;
  final String status;
  final DateTime? kickoff;
  final int? homeScore;
  final int? awayScore;

  factory KnockoutLegDto.fromJson(Map<String, dynamic> json) => KnockoutLegDto(
    legType: json['legType'] as String? ?? 'SINGLE',
    status: json['status'] as String? ?? 'unknown',
    // As pernas de mata-mata já vêm em UTC real com `Z` (confirmado ao
    // vivo — `OneFootballMatchCard.kickoff` nunca passa por
    // `utcToNaiveBrazilLocal`) — `parseKickoffInstant` respeita esse
    // offset sem tocar, mas fica robusto do mesmo jeito se isso mudar.
    kickoff: parseKickoffInstant(json['kickoff'] as String?),
    homeScore: json['homeScore'] as int?,
    awayScore: json['awayScore'] as int?,
  );

  KnockoutLeg toEntity() => KnockoutLeg(
    legType: switch (legType) {
      'FIRST' => KnockoutLegType.first,
      'SECOND' => KnockoutLegType.second,
      _ => KnockoutLegType.single,
    },
    status: MatchStatus.values.asNameMap()[status] ?? MatchStatus.unknown,
    kickoff: kickoff,
    homeScore: homeScore,
    awayScore: awayScore,
  );
}

class KnockoutTieDto {
  const KnockoutTieDto({
    required this.homeTeam,
    required this.awayTeam,
    required this.legs,
    this.aggregateHome,
    this.aggregateAway,
    this.penaltyHome,
    this.penaltyAway,
  });

  final TeamDto homeTeam;
  final TeamDto awayTeam;
  final List<KnockoutLegDto> legs;
  final int? aggregateHome;
  final int? aggregateAway;
  final int? penaltyHome;
  final int? penaltyAway;

  factory KnockoutTieDto.fromJson(Map<String, dynamic> json) => KnockoutTieDto(
    homeTeam: TeamDto.fromJson(json['homeTeam'] as Map<String, dynamic>),
    awayTeam: TeamDto.fromJson(json['awayTeam'] as Map<String, dynamic>),
    legs: (json['legs'] as List)
        .map((l) => KnockoutLegDto.fromJson(l as Map<String, dynamic>))
        .toList(),
    aggregateHome: json['aggregateHome'] as int?,
    aggregateAway: json['aggregateAway'] as int?,
    penaltyHome: json['penaltyHome'] as int?,
    penaltyAway: json['penaltyAway'] as int?,
  );

  KnockoutTie toEntity() => KnockoutTie(
    homeTeam: homeTeam.toEntity(),
    awayTeam: awayTeam.toEntity(),
    legs: legs.map((l) => l.toEntity()).toList(),
    aggregateHome: aggregateHome,
    aggregateAway: aggregateAway,
    penaltyHome: penaltyHome,
    penaltyAway: penaltyAway,
  );
}
