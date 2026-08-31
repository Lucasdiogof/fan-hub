import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_cubit.dart';

const _goias = Team(
  id: 1863,
  name: 'Goiás',
  shortName: 'GO',
  color: Color(0xFF004C1B),
);
const _opponent = Team(
  id: 2,
  name: 'Vila Nova',
  shortName: 'VNO',
  color: Color(0xFF000000),
);

final _match = Match(
  id: 'm1',
  competition: 'Campeonato Goiano',
  round: 'Rodada 1',
  homeTeam: _goias,
  awayTeam: _opponent,
  stadium: 'Serrinha',
  kickoff: DateTime.now().add(const Duration(days: 5)),
  status: MatchStatus.scheduled,
);

const _sector = TicketSector(
  id: 'cadeiras',
  name: 'Cadeiras',
  venueLabel: 'Serrinha',
  gate: 'A',
  categories: [
    TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 40),
  ],
);

TicketEvent _event() => TicketEvent(
  match: _match,
  info: MatchTicketInfo(
    matchId: _match.id,
    saleOpensAt: DateTime.now().subtract(const Duration(days: 1)),
    checkInOpensAt: DateTime.now().subtract(const Duration(days: 1)),
    canCancelCheckIn: true,
    sectors: const [_sector],
  ),
  saleStatus: TicketSaleStatus.open,
  checkInStatus: CheckInStatus.unavailable,
);

class _FakeTicketRepository implements TicketRepository {
  int purchaseCallCount = 0;
  Failure? purchaseFailure;

  @override
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required String holderName,
    required String holderDocument,
  }) async {
    purchaseCallCount++;
    // Delay real (não só microtask) — é essa janela assíncrona que um
    // duplo toque exploraria sem a guarda no Cubit.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final failure = purchaseFailure;
    if (failure != null) return Error(failure);
    return Success(
      TicketOrder(
        id: 'order-$purchaseCallCount',
        number: 'GOI-$purchaseCallCount',
        matchId: matchId,
        competition: _match.competition,
        round: _match.round,
        homeTeam: _match.homeTeam,
        awayTeam: _match.awayTeam,
        kickoff: _match.kickoff,
        stadium: _match.stadium,
        items: items,
        holderName: holderName,
        holderDocument: holderDocument,
        status: TicketOrderStatus.confirmed,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<List<Ticket>>> getMyTickets() async => const Success([]);

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async =>
      Success(_event());

  @override
  Future<Result<MatchSalesInfo?>> getMatchSalesInfo(String matchId) async =>
      const Success(null);

  @override
  Future<Result<Ticket>> checkIn({
    required String matchId,
    required String sectorId,
    required String holderName,
    required String holderDocument,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> declineCheckIn(String matchId) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> clearCheckInDecision(String matchId) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> undoCheckIn(String matchId) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<TicketOrder>>> getMyOrders() async =>
      throw UnimplementedError();

  @override
  Future<Result<Ticket>> requestRefund(String ticketId) async =>
      throw UnimplementedError();
}

void main() {
  late _FakeTicketRepository repository;
  late PurchaseCubit cubit;

  setUp(() {
    repository = _FakeTicketRepository();
    cubit = PurchaseCubit(repository, _event());
    cubit
      ..setQuantity('cadeiras', 'inteira', 1)
      ..setHolderName('Lucas Diogo')
      ..setHolderDocument('11144477735');
  });

  test('setUp chegou num estado pronto pra finalizar', () {
    expect(cubit.state.canFinalize, isTrue);
  });

  test(
    'duas chamadas concorrentes de finalizePurchase() só criam um pedido',
    () async {
      final first = cubit.finalizePurchase();
      final second = cubit.finalizePurchase(); // "segundo toque".
      await Future.wait([first, second]);

      expect(repository.purchaseCallCount, 1);
      expect(cubit.state.order, isNotNull);
    },
  );

  test('finalizePurchase sem itens/titular válido não chama o repositório', () async {
    final freshCubit = PurchaseCubit(repository, _event());
    await freshCubit.finalizePurchase();

    expect(repository.purchaseCallCount, 0);
    expect(freshCubit.state.order, isNull);
  });

  test('botão fica em loading (saving) durante o finalizePurchase em curso', () async {
    final future = cubit.finalizePurchase();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(cubit.state.saving, isTrue);

    await future;
    expect(cubit.state.saving, isFalse);
  });
}
