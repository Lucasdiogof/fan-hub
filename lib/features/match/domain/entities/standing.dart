import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

class Standing extends Equatable {
  const Standing({
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
  final Team team;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  /// Últimos resultados, ex.: "WWDLW". `null` quando a API não informa.
  final String? form;

  int get goalDifference => goalsFor - goalsAgainst;

  @override
  List<Object?> get props => [
    position,
    team,
    points,
    played,
    wins,
    draws,
    losses,
    goalsFor,
    goalsAgainst,
    form,
  ];
}
