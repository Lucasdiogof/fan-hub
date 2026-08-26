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
  ];
}
