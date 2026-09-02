import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

class Standing extends Equatable {
  const Standing({
    required this.position,
    required this.team,
    required this.isActiveClub,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalDifference,
    this.form,
  });

  final int position;
  final Team team;

  /// Decidido no backend por id confirmado — nunca compare `team.name`
  /// pra descobrir se é o Goiás.
  final bool isActiveClub;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;

  /// Saldo de gols — a fonte (OneFootball) só dá o saldo, não gols
  /// pró/contra separados, o que também é tudo que a UI já mostrava.
  final int goalDifference;

  /// Últimos resultados, ex.: "WWDLW". `null` quando a API não informa.
  final String? form;

  @override
  List<Object?> get props => [
    position,
    team,
    isActiveClub,
    points,
    played,
    wins,
    draws,
    losses,
    goalDifference,
    form,
  ];
}
