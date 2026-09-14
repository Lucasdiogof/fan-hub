import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_catalog_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../fakes/fake_football_repository.dart';

const _goiano = CompetitionRef(
  id: 'goiano',
  name: 'Campeonato Goiano',
  format: CompetitionFormat.groupStage,
  region: 'Brasil',
  isClubParticipating: true,
);
const _brasileirao = CompetitionRef(
  id: 'brasileirao-b',
  name: 'Brasileirão Série B',
  format: CompetitionFormat.leagueTable,
  region: 'Brasil',
);
const _libertadores = CompetitionRef(
  id: 'libertadores',
  name: 'Libertadores',
  format: CompetitionFormat.knockout,
  region: 'América do Sul',
);

void main() {
  late FakeFootballRepository repository;
  late CompetitionCatalogCubit cubit;

  setUp(() {
    repository = FakeFootballRepository();
    cubit = CompetitionCatalogCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, sem competições', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.competitions, isEmpty);
  });

  group('load', () {
    test('sucesso separa "suas" das outras, agrupadas por região', () async {
      repository.competitionsResult = const Success([
        _goiano,
        _brasileirao,
        _libertadores,
      ]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.yours, [_goiano]);
      expect(cubit.state.othersByRegion['Brasil'], [_brasileirao]);
      expect(cubit.state.othersByRegion['América do Sul'], [_libertadores]);
    });

    test('sucesso vazio emite LoadStatus.empty', () async {
      repository.competitionsResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test('falha do repositório emite error com a mensagem', () async {
      repository.competitionsResult = const Error(ServerFailure('fora do ar'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'fora do ar');
    });
  });

  test(
    'setQuery filtra por nome, sem diferenciar maiúscula/minúscula',
    () async {
      repository.competitionsResult = const Success([
        _goiano,
        _brasileirao,
        _libertadores,
      ]);
      await cubit.load();

      cubit.setQuery('brasileirão');

      expect(cubit.state.othersByRegion['Brasil'], [_brasileirao]);
      expect(cubit.state.yours, isEmpty);
    },
  );
}
