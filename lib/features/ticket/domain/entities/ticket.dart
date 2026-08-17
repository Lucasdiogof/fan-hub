import 'package:equatable/equatable.dart';

enum TicketType { inteira, meia }

extension TicketTypeLabel on TicketType {
  String get label => switch (this) {
    TicketType.inteira => 'Inteira',
    TicketType.meia => 'Meia-entrada',
  };
}

enum TicketStatus { confirmed, used }

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.matchId,
    required this.sectorName,
    required this.type,
    required this.price,
    required this.qrData,
    required this.status,
  });

  final String id;
  final String matchId;
  final String sectorName;
  final TicketType type;
  final double price;
  final String qrData;
  final TicketStatus status;

  @override
  List<Object?> get props => [id, matchId, sectorName, type, price, qrData, status];
}
