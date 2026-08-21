import 'package:equatable/equatable.dart';

enum TicketEventStatus { salesOpen, checkInOpen, unavailable }

class TicketEvent extends Equatable {
  const TicketEvent({
    required this.id,
    required this.competition,
    required this.homeTeam,
    required this.awayTeam,
    required this.dateTime,
    required this.stadium,
    required this.status,
  });

  final String id;
  final String competition;
  final String homeTeam;
  final String awayTeam;
  final DateTime dateTime;
  final String stadium;
  final TicketEventStatus status;

  @override
  List<Object?> get props => [id, competition, homeTeam, awayTeam, dateTime, stadium, status];
}
