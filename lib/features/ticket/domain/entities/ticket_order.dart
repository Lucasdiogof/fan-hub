import 'package:equatable/equatable.dart';

enum TicketOrderStatus { confirmed, pending, cancelled, refunded }

extension TicketOrderStatusLabel on TicketOrderStatus {
  String get label => switch (this) {
    TicketOrderStatus.confirmed => 'Confirmado',
    TicketOrderStatus.pending => 'Pendente',
    TicketOrderStatus.cancelled => 'Cancelado',
    TicketOrderStatus.refunded => 'Reembolsado',
  };
}

class TicketOrder extends Equatable {
  const TicketOrder({
    required this.id,
    required this.number,
    required this.eventName,
    required this.date,
    required this.amount,
    required this.status,
    this.items = const [],
  });

  final String id;
  final String number;
  final String eventName;
  final DateTime date;
  final double amount;
  final TicketOrderStatus status;
  final List<String> items;

  @override
  List<Object?> get props => [id, number, eventName, date, amount, status, items];
}
