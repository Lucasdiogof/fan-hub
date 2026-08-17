import 'package:goias_app/features/match/data/dto/team_dto.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';

class StandingDto {
  const StandingDto({
    required this.position,
    required this.team,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    this.form,
  });

  final int position;
  final TeamDto team;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final String? form;

  factory StandingDto.fromJson(Map<String, dynamic> json) => StandingDto(
    position: json['position'] as int,
    team: TeamDto.fromJson(json['team'] as Map<String, dynamic>),
    points: json['points'] as int,
    played: json['played'] as int,
    wins: json['wins'] as int,
    draws: json['draws'] as int,
    losses: json['losses'] as int,
    goalsFor: json['goalsFor'] as int,
    goalsAgainst: json['goalsAgainst'] as int,
    form: json['form'] as String?,
  );

  Standing toEntity() => Standing(
    position: position,
    team: team.toEntity(),
    points: points,
    played: played,
    wins: wins,
    draws: draws,
    losses: losses,
    goalsFor: goalsFor,
    goalsAgainst: goalsAgainst,
    form: form,
  );
}
