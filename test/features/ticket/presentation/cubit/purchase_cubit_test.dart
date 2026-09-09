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
  categories: [TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 40)],
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
  List<TicketHolder>? lastHolders;

  @override
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required List<TicketHolder> holders,
  }) async {
    lastHolders = holders;
    purchaseCallCount++;
    // Delay real (não só microtask) — é essa janela assíncrona que um
    // duplo toque exploraria sem a guarda no Cubit.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final failure = purchaseFailure;
    if (failure != null) return Error(failure);
    final primaryHolder = holders.first;
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
        holderName: primaryHolder.name,
        holderDocument: primaryHolder.document,
        status: TicketOrderStatus.confirmed,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<List<Ticket>>> getMyTickets() async => const Success([]);

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async => Success(_event());

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
    cubit.setQuantity('cadeiras', 'inteira', 1);
    cubit.ensureHolderSlots();
    cubit
      ..setHolderName(0, 'Lucas Diogo')
      ..setHolderDocument(0, '11144477735');
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

  test(
    'finalizePurchase sem itens/titular válido não chama o repositório',
    () async {
      final freshCubit = PurchaseCubit(repository, _event());
      await freshCubit.finalizePurchase();

      expect(repository.purchaseCallCount, 0);
      expect(freshCubit.state.order, isNull);
    },
  );

  test(
    'botão fica em loading (saving) durante o finalizePurchase em curso',
    () async {
      final future = cubit.finalizePurchase();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state.saving, isTrue);

      await future;
      expect(cubit.state.saving, isFalse);
    },
  );

  group('titular por ingresso (compra de mais de um)', () {
    late PurchaseCubit multiCubit;

    setUp(() {
      multiCubit = PurchaseCubit(repository, _event())
        ..setQuantity('cadeiras', 'inteira', 2);
      multiCubit.ensureHolderSlots();
    });

    tearDown(() => multiCubit.close());

    test('ensureHolderSlots cria um titular vazio por ingresso', () {
      expect(multiCubit.state.holders.length, 2);
    });

    test(
      'não pode finalizar até TODOS os titulares terem nome e documento válidos',
      () {
        multiCubit
          ..setHolderName(0, 'Lucas Diogo')
          ..setHolderDocument(0, '11144477735');
        // Só o primeiro preenchido — o segundo ainda está vazio.
        expect(multiCubit.state.canFinalize, isFalse);

        multiCubit
          ..setHolderName(1, 'Amigo Torcedor')
          ..setHolderDocument(1, 'AB123456');
        expect(multiCubit.state.canFinalize, isTrue);
      },
    );

    test(
      'cada ingresso vai pro repositório com o titular próprio dele',
      () async {
        multiCubit
          ..setHolderName(0, 'Lucas Diogo')
          ..setHolderDocument(0, '11144477735')
          ..setHolderName(1, 'Amigo Torcedor')
          ..setHolderDocument(1, '52998224725');
        await multiCubit.finalizePurchase();

        expect(multiCubit.state.order, isNotNull);
        expect(multiCubit.state.order!.holderName, 'Lucas Diogo');
        expect(repository.lastHolders?.map((h) => h.name).toList(), [
          'Lucas Diogo',
          'Amigo Torcedor',
        ]);
      },
    );

    test('marcar "é pra mim" preenche e desabilita edição daquele titular', () {
      multiCubit.setHolderIsSelf(
        0,
        value: true,
        profileName: 'Lucas Diogo',
        profileDocument: '11144477735',
      );
      expect(multiCubit.state.holders[0].isSelf, isTrue);
      expect(multiCubit.state.holders[0].name, 'Lucas Diogo');
      // O segundo ingresso continua independente, sem herdar nada do
      // primeiro.
      expect(multiCubit.state.holders[1].isSelf, isFalse);
      expect(multiCubit.state.holders[1].name, isEmpty);
    });
  });
}
