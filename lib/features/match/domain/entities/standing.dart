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

  /// `true` quando esta linha é o clube ATIVO deste build (comparando o id
  /// confirmado do time com `ClubConfig.integrations.oneFootballTeamId` —
  /// computado no cliente desde a M3.3, que tirou o cálculo do servidor).
  /// Nunca compare `team.name` pra descobrir o clube.
  final bool isActiveClub;

  Standing copyWith({bool? isActiveClub}) {
    return Standing(
      position: position,
      team: team,
      isActiveClub: isActiveClub ?? this.isActiveClub,
      points: points,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalDifference: goalDifference,
      form: form,
    );
  }

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
