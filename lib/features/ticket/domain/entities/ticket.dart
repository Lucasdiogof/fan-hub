import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';

/// Um ingresso — seja ele criado por compra ou por check-in de sócio
/// ([origin] discrimina, nunca duas classes separadas). [categoryLabel] é
/// `null` no check-in (não existe categoria de preço) e [price] é `null`
/// pro mesmo caso.
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.matchId,
    required this.competition,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,
    required this.stadium,
    required this.sectorName,
    required this.venueLabel,
    required this.gate,
    required this.holderName,
    required this.holderDocument,
    required this.status,
    required this.origin,
    required this.createdAt,
    this.categoryLabel,
    this.orderId,
    this.price,
    this.refundedAt,
  });

  final String id;
  final String matchId;
  final String competition;
  final String round;
  final Team homeTeam;
  final Team awayTeam;
  final DateTime? kickoff;
  final String stadium;
  final String sectorName;
  final String venueLabel;
  final String gate;
  final String holderName;
  final String holderDocument;
  final TicketStatus status;
  final TicketOrigin origin;
  final DateTime createdAt;
  final String? categoryLabel;
  final String? orderId;
  final double? price;

  /// Preenchido só quando [status] é [TicketStatus.refunded] — "data da
  /// solicitação" mostrada no detalhe do reembolso.
  final DateTime? refundedAt;

  @override
  List<Object?> get props => [
    id,
    matchId,
    competition,
    round,
    homeTeam,
    awayTeam,
    kickoff,
    stadium,
    sectorName,
    venueLabel,
    gate,
    holderName,
    holderDocument,
    status,
    origin,
    createdAt,
    categoryLabel,
    orderId,
    price,
    refundedAt,
  ];
}

/// Regra central de elegibilidade pra "Solicitar reembolso" — a UI só
/// consome isto, nunca decide de novo. Mock atual (sem pagamento real):
/// ingresso de COMPRA, ainda ATIVO (cobre "não usado" e "não reembolsado"
/// de uma vez, já que são estados mutuamente exclusivos de [TicketStatus])
/// e a partida ainda não começou (mesma convenção de "kickoff null == ainda
/// por vir" usada no resto do módulo, ver `computeSaleStatus`). Não existe
/// hoje uma janela oficial tipo "até 24h antes" — se essa regra comercial
/// nascer, entra aqui, num único lugar.
bool canRequestRefund(Ticket ticket, {DateTime? now}) {
  final effectiveNow = now ?? DateTime.now();
  final kickoff = ticket.kickoff;
  return ticket.origin == TicketOrigin.purchase &&
      ticket.status == TicketStatus.active &&
      (kickoff == null || effectiveNow.isBefore(kickoff));
}
