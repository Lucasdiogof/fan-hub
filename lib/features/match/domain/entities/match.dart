import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/team_info.dart';

enum MatchStatus { scheduled, live, finished }

class Match extends Equatable {
  const Match({
    required this.id,
    required this.competition,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.stadium,
    required this.kickoff,
    required this.status,
    this.salesOpen = false,
    this.homeScore,
    this.awayScore,
  });

  final String id;
  final String competition;
  final String round;
  final TeamInfo homeTeam;
  final TeamInfo awayTeam;
  final String stadium;
  final DateTime kickoff;
  final MatchStatus status;
  final bool salesOpen;
  final int? homeScore;
  final int? awayScore;

  bool get isGoiasHome => homeTeam.shortName == 'GO';

  TeamInfo get opponent => isGoiasHome ? awayTeam : homeTeam;

  String get resultLabel => '${homeTeam.shortName} $homeScore x $awayScore ${awayTeam.shortName}';

  @override
  List<Object?> get props => [
    id,
    competition,
    round,
    homeTeam,
    awayTeam,
    stadium,
    kickoff,
    status,
    salesOpen,
    homeScore,
    awayScore,
  ];
}
