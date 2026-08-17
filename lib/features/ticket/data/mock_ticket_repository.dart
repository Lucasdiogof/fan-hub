import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/features/ticket/domain/entities/stadium_sector.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';

class MockTicketRepository implements TicketRepository {
  static const _latency = Duration(milliseconds: 300);

  final List<Ticket> _myTickets = [
    Ticket(
      id: 't-seed-1',
      matchId: 'm-next-1',
      sectorName: MockData.sectors[1].name,
      type: TicketType.inteira,
      price: MockData.sectors[1].price,
      qrData: 'GOIAS-TICKET-T-SEED-1',
      status: TicketStatus.confirmed,
    ),
  ];

  @override
  Future<Result<List<StadiumSector>>> getSectors(String matchId) async {
    await Future<void>.delayed(_latency);
    return const Success(MockData.sectors);
  }

  @override
  Future<Result<List<Ticket>>> purchase({
    required String matchId,
    required StadiumSector sector,
    required TicketType type,
    required int quantity,
  }) async {
    await Future<void>.delayed(_latency);
    final purchased = List.generate(quantity, (index) {
      final id = 't-${DateTime.now().microsecondsSinceEpoch}-$index';
      return Ticket(
        id: id,
        matchId: matchId,
        sectorName: sector.name,
        type: type,
        price: sector.price,
        qrData: 'GOIAS-TICKET-${id.toUpperCase()}',
        status: TicketStatus.confirmed,
      );
    });
    _myTickets.addAll(purchased);
    return Success(purchased);
  }

  @override
  Future<Result<List<Ticket>>> getMyTickets() async {
    await Future<void>.delayed(_latency);
    final sorted = [..._myTickets.reversed];
    return Success(sorted);
  }
}
