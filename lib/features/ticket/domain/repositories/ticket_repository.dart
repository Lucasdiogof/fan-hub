import 'dart:typed_data';

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

  /// [holders] tem exatamente um titular por ingresso físico (soma das
  /// quantidades de [items], nessa mesma ordem "achatada") — nunca um
  /// titular só cobrindo vários ingressos.
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required List<TicketHolder> holders,
  });

  /// Sobe o comprovante de meia-entrada (Lei Federal 12.933/2013) pro
  /// bucket privado `half_price_proofs` e devolve o path salvo (nunca uma
  /// URL pública — o comprovante é documento pessoal). Cada chamada gera um
  /// path novo, nunca sobrescreve um comprovante anterior no mesmo pedido.
  Future<Result<String>> uploadHalfPriceProof(
    Uint8List bytes,
    String fileExtension,
  );

  Future<Result<List<Ticket>>> getMyTickets();

  Future<Result<List<TicketOrder>>> getMyOrders();

  /// Reembolso simulado (sem gateway real) de um ingresso de COMPRA — nunca
  /// de check-in de sócio (ver `undoCheckIn` pra esse caso). Rejeita se o
  /// ingresso não existir, não pertencer ao usuário, não for de compra, ou
  /// já não estiver `active` (idempotente contra pedido duplicado).
  Future<Result<Ticket>> requestRefund(String ticketId);
}
