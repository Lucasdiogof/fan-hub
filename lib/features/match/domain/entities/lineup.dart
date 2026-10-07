import 'package:equatable/equatable.dart';

class LineupPlayer extends Equatable {
  const LineupPlayer({
    required this.name,
    required this.jerseyNumber,
    required this.photo,
    this.providerPlayerId,
  });

  final String name;
  final int jerseyNumber;
  final String photo;

  /// ID do jogador no provedor (OneFootball) — o vínculo canônico com o
  /// jogador real, ao contrário do nome (que varia: "Djalma Antônio da Silva
  /// Filho" x "Djalma"). `null` quando o provedor não informou.
  final int? providerPlayerId;

  @override
  List<Object?> get props => [name, jerseyNumber, photo, providerPlayerId];
}

class TeamLineup extends Equatable {
  const TeamLineup({required this.teamName, required this.rows});

  final String teamName;
  final List<List<LineupPlayer>> rows;

  @override
  List<Object?> get props => [teamName, rows];
}

class MatchLineups extends Equatable {
  const MatchLineups({required this.home, required this.away});

  final TeamLineup home;
  final TeamLineup away;

  @override
  List<Object?> get props => [home, away];
}
