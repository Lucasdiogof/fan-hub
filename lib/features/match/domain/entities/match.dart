import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

enum MatchStatus {
  scheduled,
  live,
  halftime,
  finished,
  postponed,
  cancelled,
  suspended,
  unknown,
}

class Match extends Equatable {
  const Match({
    required this.id,
    required this.competition,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.stadium,
    this.kickoff,
    required this.status,
    this.city,
    this.homeScore,
    this.awayScore,
    this.minute,
  });

  final String id;
  final String competition;
  final String round;
  final Team homeTeam;
  final Team awayTeam;
  final String stadium;
  final String? city;

  /// Algumas partidas ainda não têm horário confirmado pela fonte (fica
  /// `null` até a fonte publicar). A UI trata isso mostrando "a confirmar"
  /// em vez de esconder a partida.
  final DateTime? kickoff;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;

  /// Minuto ao vivo pronto pra exibir (ex.: "37'", "45+2'") — vem direto da
  /// fonte, nunca calculado localmente a partir do kickoff. `null` fora de
  /// partida ao vivo/intervalo.
  final String? minute;

  bool isHomeTeam(int teamId) => homeTeam.id == teamId;

  @override
  List<Object?> get props => [
    id,
    competition,
    round,
    homeTeam,
    awayTeam,
    stadium,
    city,
    kickoff,
    status,
    homeScore,
    awayScore,
    minute,
  ];
}
