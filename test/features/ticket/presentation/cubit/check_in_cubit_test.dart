import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';
import 'package:goias_app/features/ticket/presentation/cubit/check_in_cubit.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

import '../../fakes/fake_ticket_repository.dart';

TicketEvent _buildEvent() {
  final match = Match(
    id: '1',
    competition: 'Campeonato Goiano',
    round: 'Rodada 1',
    homeTeam: goiasTeam,
    awayTeam: opponentTeam,
    stadium: 'Serrinha',
    kickoff: DateTime.now().add(const Duration(days: 5)),
    status: MatchStatus.scheduled,
  );
  final info = MatchTicketInfo(
    matchId: '1',
    saleOpensAt: DateTime.now().subtract(const Duration(days: 1)),
    checkInOpensAt: DateTime.now().subtract(const Duration(hours: 1)),
    canCancelCheckIn: true,
    sectors: const [
      TicketSector(
        id: 's1',
        name: 'Cadeiras',
        venueLabel: 'Serrinha',
        gate: 'A',
        categories: [],
        availableForCheckIn: true,
      ),
    ],
  );
  return TicketEvent(
    match: match,
    info: info,
    saleStatus: TicketSaleStatus.open,
    checkInStatus: CheckInStatus.available,
  );
}

void main() {
  late FakeTicketRepository repository;
  late CheckInCubit cubit;

  setUp(() {
    repository = FakeTicketRepository();
    cubit = CheckInCubit(repository, _buildEvent());
  });

  tearDown(() => cubit.close());

  test('estado inicial não tem setor selecionado', () {
    expect(cubit.state.selectedSectorId, isNull);
    expect(cubit.state.saving, isFalse);
  });

  test('selectSector guarda o setor escolhido', () {
    cubit.selectSector('s1');
    expect(cubit.state.selectedSectorId, 's1');
  });

  group('confirm', () {
    test('sem setor selecionado, não faz nada', () async {
      await cubit.confirm(holderName: 'Lucas', holderDocument: '12345678900');

      expect(cubit.state.saving, isFalse);
      expect(cubit.state.justConfirmed, isFalse);
      expect(repository.lastCheckInArgs, isNull);
    });

    test(
      'sucesso marca justConfirmed e guarda o ingresso confirmado',
      () async {
        cubit.selectSector('s1');
        final ticket = buildTicket(id: 't-checkin');
        repository.checkInResult = Success(ticket);

        await cubit.confirm(holderName: 'Lucas', holderDocument: '12345678900');

        expect(cubit.state.saving, isFalse);
        expect(cubit.state.justConfirmed, isTrue);
        expect(cubit.state.confirmedTicket, ticket);
        expect(repository.lastCheckInArgs, {
          'matchId': '1',
          'sectorId': 's1',
          'holderName': 'Lucas',
          'holderDocument': '12345678900',
        });
      },
    );

    test(
      'falha do repositório expõe a mensagem e não marca justConfirmed',
      () async {
        cubit.selectSector('s1');
        repository.checkInResult = const Error(ServerFailure('setor lotado'));

        await cubit.confirm(holderName: 'Lucas', holderDocument: '12345678900');

        expect(cubit.state.saving, isFalse);
        expect(cubit.state.justConfirmed, isFalse);
        expect(cubit.state.errorMessage, 'setor lotado');
      },
    );
  });

  group('decline', () {
    test('sucesso marca justDeclined', () async {
      await cubit.decline();

      expect(cubit.state.saving, isFalse);
      expect(cubit.state.justDeclined, isTrue);
      expect(repository.lastDeclinedMatchId, '1');
    });

    test('falha expõe a mensagem e não marca justDeclined', () async {
      repository.declineCheckInResult = const Error(ServerFailure('erro'));

      await cubit.decline();

      expect(cubit.state.saving, isFalse);
      expect(cubit.state.justDeclined, isFalse);
      expect(cubit.state.errorMessage, 'erro');
    });
  });
}
