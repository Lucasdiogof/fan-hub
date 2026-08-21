import 'package:equatable/equatable.dart';

enum TicketStatus { valid, used, cancelled }

extension TicketStatusLabel on TicketStatus {
  String get label => switch (this) {
    TicketStatus.valid => 'Válido',
    TicketStatus.used => 'Utilizado',
    TicketStatus.cancelled => 'Cancelado',
  };
}

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.status,
    this.sector,
    this.seat,
  });

  final String id;
  final String eventId;
  final String eventName;
  final DateTime eventDate;
  final TicketStatus status;
  final String? sector;
  final String? seat;

  @override
  List<Object?> get props => [id, eventId, eventName, eventDate, status, sector, seat];
}
