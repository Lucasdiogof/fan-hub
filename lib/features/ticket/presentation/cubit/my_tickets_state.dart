import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MyTicketsState extends Equatable {
  const MyTicketsState({
    this.status = LoadStatus.initial,
    this.tickets = const [],
    this.errorMessage,
    this.refunding = false,
    this.refundErrorMessage,
  });

  final LoadStatus status;
  final List<Ticket> tickets;
  final String? errorMessage;

  /// Guarda contra duplo toque em "Solicitar reembolso" (mesmo padrão de
  /// `PurchaseState.saving`) — só um pedido de reembolso por vez.
  final bool refunding;

  /// Separado de [errorMessage] de propósito: aquele é o erro de carregar
  /// a lista inteira (tela cheia, via `LoadStatus.error`); este é só o erro
  /// de um pedido de reembolso específico (mostrado numa bottom sheet).
  final String? refundErrorMessage;

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
    bool? refunding,
    String? Function()? refundErrorMessage,
  }) {
    return MyTicketsState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      errorMessage: errorMessage ?? this.errorMessage,
      refunding: refunding ?? this.refunding,
      refundErrorMessage: refundErrorMessage != null
          ? refundErrorMessage()
          : this.refundErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tickets,
    errorMessage,
    refunding,
    refundErrorMessage,
  ];
}
