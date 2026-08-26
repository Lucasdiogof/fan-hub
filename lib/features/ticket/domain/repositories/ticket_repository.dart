import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';

abstract class TicketRepository {
  Future<Result<TicketEvent?>> getFeaturedEvent();

  Future<Result<MatchSalesInfo?>> getMatchSalesInfo(String matchId);

  /// Sócio confirmando presença — cria o ingresso de check-in e grava a
  /// decisão. Chamar de novo pro mesmo `matchId` é idempotente (upsert).
  Future<Result<Ticket>> checkIn({
    required String matchId,
    required String sectorId,
    required String holderName,
    required String holderDocument,
  });

  /// "Não dessa vez" — grava a decisão sem criar ingresso.
  Future<Result<void>> declineCheckIn(String matchId);

  /// "Mudei de ideia" depois de recusar — volta pro estado `available`,
  /// sem apagar nenhum ingresso (não havia nenhum).
  Future<Result<void>> clearCheckInDecision(String matchId);

  /// Cancela o ingresso de check-in confirmado. Chamado só quando
  /// `MatchTicketInfo.canCancelCheckIn` permitir — a regra mora no
  /// repositório/dado, não é decidida na UI.
  Future<Result<void>> undoCheckIn(String matchId);

  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required String holderName,
    required String holderDocument,
  });

  Future<Result<List<Ticket>>> getMyTickets();

  Future<Result<List<TicketOrder>>> getMyOrders();
}
