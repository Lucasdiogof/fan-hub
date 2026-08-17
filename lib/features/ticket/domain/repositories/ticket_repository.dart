import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/stadium_sector.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';

abstract class TicketRepository {
  Future<Result<List<StadiumSector>>> getSectors(String matchId);

  Future<Result<List<Ticket>>> purchase({
    required String matchId,
    required StadiumSector sector,
    required TicketType type,
    required int quantity,
  });

  Future<Result<List<Ticket>>> getMyTickets();
}
