import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';

abstract class TicketRepository {
  Future<Result<TicketEvent?>> getFeaturedEvent();

  Future<Result<List<Ticket>>> getMyTickets();

  Future<Result<List<TicketOrder>>> getMyOrders();
}
