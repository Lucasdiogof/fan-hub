import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';

const goiasTeam = Team(
  id: 1863,
  name: 'Goiás',
  shortName: 'GO',
  color: Color(0xFF004C1B),
);
const opponentTeam = Team(
  id: 2,
  name: 'Vila Nova',
  shortName: 'VNO',
  color: Color(0xFF000000),
);

Ticket buildTicket({
  required String id,
  TicketStatus status = TicketStatus.active,
  TicketOrigin origin = TicketOrigin.purchase,
  DateTime? kickoff,
  DateTime? refundedAt,
}) => Ticket(
  id: id,
  matchId: 'm1',
  competition: 'Campeonato Goiano',
  round: 'Rodada 1',
  homeTeam: goiasTeam,
  awayTeam: opponentTeam,
  kickoff: kickoff ?? DateTime.now().add(const Duration(days: 5)),
  stadium: 'Serrinha',
  sectorName: 'Cadeiras',
  venueLabel: 'Serrinha',
  gate: 'A',
  holderName: 'Torcedor Teste',
  holderDocument: '12345678900',
  status: status,
  origin: origin,
  createdAt: DateTime.now(),
  orderId: 'order-1',
  price: 40,
  refundedAt: refundedAt,
);

TicketOrder buildOrder({
  required String id,
  TicketOrderStatus status = TicketOrderStatus.confirmed,
  DateTime? createdAt,
}) => TicketOrder(
  id: id,
  number: id,
  matchId: 'm1',
  competition: 'Campeonato Goiano',
  round: 'Rodada 1',
  homeTeam: goiasTeam,
  awayTeam: opponentTeam,
  kickoff: DateTime.now().add(const Duration(days: 5)),
  stadium: 'Serrinha',
  items: const [
    TicketOrderItem(
      sectorId: 's1',
      sectorName: 'Cadeiras',
      venueLabel: 'Serrinha',
      gate: 'A',
      categoryId: 'inteira',
      categoryLabel: 'Inteira',
      quantity: 1,
      unitPrice: 40,
    ),
  ],
  holderName: 'Torcedor Teste',
  holderDocument: '12345678900',
  status: status,
  createdAt: createdAt ?? DateTime.now(),
);

class FakeTicketRepository implements TicketRepository {
  Result<TicketEvent?> featuredEventResult = const Success(null);
  Result<MatchSalesInfo?> matchSalesInfoResult = const Success(null);
  Result<Ticket> checkInResult = Success(buildTicket(id: 't1'));
  Result<void> declineCheckInResult = const Success(null);
  Result<void> clearCheckInDecisionResult = const Success(null);
  Result<void> undoCheckInResult = const Success(null);
  Result<TicketOrder> purchaseResult = Success(buildOrder(id: 'order-1'));
  Result<String> uploadHalfPriceProofResult = const Success('proofs/p1');
  Result<List<Ticket>> myTicketsResult = const Success([]);
  Result<List<TicketOrder>> myOrdersResult = const Success([]);
  Result<Ticket> requestRefundResult = Success(buildTicket(id: 't1'));

  Map<String, dynamic>? lastCheckInArgs;
  String? lastDeclinedMatchId;
  String? lastUndoneMatchId;
  Map<String, dynamic>? lastPurchaseArgs;
  String? lastRefundedTicketId;

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async => featuredEventResult;

  @override
  Future<Result<MatchSalesInfo?>> getMatchSalesInfo(String matchId) async =>
      matchSalesInfoResult;

  @override
  Future<Result<Ticket>> checkIn({
    required String matchId,
    required String sectorId,
    required String holderName,
    required String holderDocument,
  }) async {
    lastCheckInArgs = {
      'matchId': matchId,
      'sectorId': sectorId,
      'holderName': holderName,
      'holderDocument': holderDocument,
    };
    return checkInResult;
  }

  @override
  Future<Result<void>> declineCheckIn(String matchId) async {
    lastDeclinedMatchId = matchId;
    return declineCheckInResult;
  }

  @override
  Future<Result<void>> clearCheckInDecision(String matchId) async =>
      clearCheckInDecisionResult;

  @override
  Future<Result<void>> undoCheckIn(String matchId) async {
    lastUndoneMatchId = matchId;
    return undoCheckInResult;
  }

  @override
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required List<TicketHolder> holders,
  }) async {
    lastPurchaseArgs = {'matchId': matchId, 'items': items, 'holders': holders};
    return purchaseResult;
  }

  @override
  Future<Result<String>> uploadHalfPriceProof(
    Uint8List bytes,
    String fileExtension,
  ) async => uploadHalfPriceProofResult;

  @override
  Future<Result<List<Ticket>>> getMyTickets() async => myTicketsResult;

  @override
  Future<Result<List<TicketOrder>>> getMyOrders() async => myOrdersResult;

  @override
  Future<Result<Ticket>> requestRefund(String ticketId) async {
    lastRefundedTicketId = ticketId;
    return requestRefundResult;
  }
}
