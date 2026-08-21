import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';

class EmptyTicketRepository implements TicketRepository {
  static const _latency = Duration(milliseconds: 250);

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async {
    await Future<void>.delayed(_latency);
    return const Success(null);
  }

  @override
  Future<Result<List<Ticket>>> getMyTickets() async {
    await Future<void>.delayed(_latency);
    return const Success([]);
  }

  @override
  Future<Result<List<TicketOrder>>> getMyOrders() async {
    await Future<void>.delayed(_latency);
    return const Success([]);
  }
}
