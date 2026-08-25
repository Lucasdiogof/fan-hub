import 'package:equatable/equatable.dart';

class LineupPlayer extends Equatable {
  const LineupPlayer({
    required this.name,
    required this.jerseyNumber,
    required this.photo,
  });

  final String name;
  final int jerseyNumber;
  final String photo;

  @override
  List<Object?> get props => [name, jerseyNumber, photo];
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
