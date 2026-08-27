import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MyTicketsState extends Equatable {
  const MyTicketsState({
    this.status = LoadStatus.initial,
    this.tickets = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Ticket> tickets;
  final String? errorMessage;

  /// Ativo e ainda por vir (ou sem horário confirmado) — mesma convenção de
  /// `kickoff == null` como "ainda por vir" já usada pra partidas.
  List<Ticket> get upcoming => tickets
      .where(
        (ticket) =>
            ticket.status == TicketStatus.active &&
            (ticket.kickoff == null || ticket.kickoff!.isAfter(DateTime.now())),
      )
      .toList();

  List<Ticket> get history =>
      tickets.where((ticket) => !upcoming.contains(ticket)).toList();

  MyTicketsState copyWith({
    LoadStatus? status,
    List<Ticket>? tickets,
    String? errorMessage,
  }) {
    return MyTicketsState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tickets, errorMessage];
}
