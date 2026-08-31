import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';

/// Estado completo do "próximo evento" pra venda/check-in — junta a partida
/// real ([match], vem de `FootballRepository`) com o que é específico de
/// ingresso ([info], [saleStatus], [checkInStatus]). [checkInStatus] já vem
/// resolvido (janela de tempo + decisão do usuário combinadas) — a UI só
/// faz `switch`, nunca combina regra de novo. `TicketsCubit` que combina
/// isso com o status de sócio (`MembershipRepository`, feature diferente).
class TicketEvent extends Equatable {
  const TicketEvent({
    required this.match,
    required this.info,
    required this.saleStatus,
    required this.checkInStatus,
    this.confirmedSectorName,
    this.checkInTicket,
    this.hasTicketForMatch = false,
  });

  final Match match;
  final MatchTicketInfo info;
  final TicketSaleStatus saleStatus;
  final CheckInStatus checkInStatus;

  /// Preenchidos quando [checkInStatus] é `confirmed`.
  final String? confirmedSectorName;
  final Ticket? checkInTicket;

  /// Se o usuário já comprou algum ingresso pra esta partida, pra ele
  /// mesmo ou pra outra pessoa — nesse caso a UI manda pra "Meus
  /// ingressos" em vez de repetir a compra.
  final bool hasTicketForMatch;

  @override
  List<Object?> get props => [
    match,
    info,
    saleStatus,
    checkInStatus,
    confirmedSectorName,
    checkInTicket,
    hasTicketForMatch,
  ];
}
