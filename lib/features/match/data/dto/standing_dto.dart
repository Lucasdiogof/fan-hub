import 'package:goias_app/features/match/data/dto/team_dto.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';

class StandingDto {
  const StandingDto({
    required this.position,
    required this.team,
    required this.isGoias,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalDifference,
    this.form,
  });

  final int position;
  final TeamDto team;
  final bool isGoias;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalDifference;
  final String? form;

  /// Números vêm com `?? 0` — o backend já defende contra isso, mas a fonte
  /// (OneFootball) já mostrou na prática que pode faltar um campo numérico
  /// pontualmente numa linha; melhor mostrar 0 do que derrubar a lista
  /// inteira por causa de um time.
  factory StandingDto.fromJson(Map<String, dynamic> json) => StandingDto(
    position: json['position'] as int? ?? 0,
    team: TeamDto.fromJson(json['team'] as Map<String, dynamic>),
    isGoias: json['isGoias'] as bool? ?? false,
    points: json['points'] as int? ?? 0,
    played: json['played'] as int? ?? 0,
    wins: json['wins'] as int? ?? 0,
    draws: json['draws'] as int? ?? 0,
    losses: json['losses'] as int? ?? 0,
    goalDifference: json['goalDifference'] as int? ?? 0,
    form: json['form'] as String?,
  );

  Standing toEntity() => Standing(
    position: position,
    team: team.toEntity(),
    isGoias: isGoias,
    points: points,
    played: played,
    wins: wins,
    draws: draws,
    losses: losses,
    goalDifference: goalDifference,
    form: form,
  );
}
