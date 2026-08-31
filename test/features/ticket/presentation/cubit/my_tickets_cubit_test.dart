import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

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

Ticket _ticket({
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
  homeTeam: _goias,
  awayTeam: _opponent,
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

class _FakeTicketRepository implements TicketRepository {
  _FakeTicketRepository(this.tickets);

  List<Ticket> tickets;
  int requestRefundCallCount = 0;
  Failure? requestRefundFailure;
  Duration refundDelay = Duration.zero;

  @override
  Future<Result<List<Ticket>>> getMyTickets() async => Success(List.of(tickets));

  @override
  Future<Result<Ticket>> requestRefund(String ticketId) async {
    requestRefundCallCount++;
    if (refundDelay > Duration.zero) {
      await Future<void>.delayed(refundDelay);
    }
    final failure = requestRefundFailure;
    if (failure != null) return Error(failure);
    final index = tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1 || tickets[index].status != TicketStatus.active) {
      return const Error(ServerFailure('Este ingresso não pode ser reembolsado.'));
    }
    final refunded = _ticket(
      id: tickets[index].id,
      status: TicketStatus.refunded,
      kickoff: tickets[index].kickoff,
      refundedAt: DateTime.now(),
    );
    tickets[index] = refunded;
    return Success(refunded);
  }

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async =>
      throw UnimplementedError();

  @override
  Future<Result<MatchSalesInfo?>> getMatchSalesInfo(String matchId) async =>
      throw UnimplementedError();

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
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required List<TicketHolder> holders,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<TicketOrder>>> getMyOrders() async =>
      throw UnimplementedError();
}

void main() {
  group('canRequestRefund', () {
    test('ingresso de compra, ativo, partida futura pode ser reembolsado', () {
      final ticket = _ticket(id: 't1');
      expect(canRequestRefund(ticket), isTrue);
    });

    test('ingresso de check-in de sócio nunca pode ser reembolsado', () {
      final ticket = _ticket(id: 't1', origin: TicketOrigin.membershipCheckIn);
      expect(canRequestRefund(ticket), isFalse);
    });

    test('ingresso já reembolsado não pode ser reembolsado de novo', () {
      final ticket = _ticket(id: 't1', status: TicketStatus.refunded);
      expect(canRequestRefund(ticket), isFalse);
    });

    test('ingresso já utilizado não pode ser reembolsado', () {
      final ticket = _ticket(id: 't1', status: TicketStatus.used);
      expect(canRequestRefund(ticket), isFalse);
    });

    test('partida já começada bloqueia o reembolso', () {
      final ticket = _ticket(
        id: 't1',
        kickoff: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(canRequestRefund(ticket), isFalse);
    });

    test('kickoff nulo (data a confirmar) é tratado como ainda por vir', () {
      final ticket = Ticket(
        id: 't1',
        matchId: 'm1',
        competition: 'Campeonato Goiano',
        round: 'Rodada 1',
        homeTeam: _goias,
        awayTeam: _opponent,
        kickoff: null,
        stadium: 'Serrinha',
        sectorName: 'Cadeiras',
        venueLabel: 'Serrinha',
        gate: 'A',
        holderName: 'Torcedor Teste',
        holderDocument: '12345678900',
        status: TicketStatus.active,
        origin: TicketOrigin.purchase,
        createdAt: DateTime.now(),
      );
      expect(canRequestRefund(ticket), isTrue);
    });
  });

  group('MyTicketsState.upcoming/history', () {
    test('ingresso reembolsado sai de upcoming e aparece em history', () {
      final active = _ticket(id: 'active');
      final refunded = _ticket(id: 'refunded', status: TicketStatus.refunded);
      final state = MyTicketsState(
        status: LoadStatus.success,
        tickets: [active, refunded],
      );
      expect(state.upcoming.map((t) => t.id), [active.id]);
      expect(state.history.map((t) => t.id), [refunded.id]);
    });
  });

  group('MyTicketsCubit.requestRefund', () {
    late _FakeTicketRepository repository;
    late MyTicketsCubit cubit;

    setUp(() {
      repository = _FakeTicketRepository([_ticket(id: 't1')]);
      cubit = MyTicketsCubit(repository);
    });

    tearDown(() => cubit.close());

    test('sucesso: recarrega a lista e o ingresso vira refunded', () async {
      await Future<void>.delayed(Duration.zero); // load() inicial do construtor
      await cubit.requestRefund('t1');

      expect(cubit.state.refunding, isFalse);
      expect(cubit.state.refundErrorMessage, isNull);
      expect(cubit.state.tickets.single.status, TicketStatus.refunded);
    });

    test('falha: mantém a lista e expõe refundErrorMessage', () async {
      repository.requestRefundFailure = const ServerFailure('deu ruim');
      await Future<void>.delayed(Duration.zero);

      await cubit.requestRefund('t1');

      expect(cubit.state.refunding, isFalse);
      expect(cubit.state.refundErrorMessage, 'deu ruim');
      expect(cubit.state.tickets.single.status, TicketStatus.active);
    });

    test('duplo toque: duas chamadas concorrentes só reembolsam uma vez', () async {
      repository.refundDelay = const Duration(milliseconds: 20);
      await Future<void>.delayed(Duration.zero);

      final first = cubit.requestRefund('t1');
      final second = cubit.requestRefund('t1'); // ignorado — já está refunding
      await Future.wait([first, second]);

      expect(repository.requestRefundCallCount, 1);
      expect(cubit.state.tickets.single.status, TicketStatus.refunded);
    });

    test(
      'ingresso já reembolsado (ou de outra conta) é rejeitado, não reembolsa de novo',
      () async {
        repository.tickets = [_ticket(id: 't1', status: TicketStatus.refunded)];
        await Future<void>.delayed(Duration.zero);

        await cubit.requestRefund('t1');

        expect(cubit.state.refundErrorMessage, isNotNull);
        expect(repository.requestRefundCallCount, 1);
      },
    );
  });
}
