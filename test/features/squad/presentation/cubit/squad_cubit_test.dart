import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/squad/domain/repositories/squad_repository.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _member = SquadMember(
  id: 'p1',
  name: 'Harlei',
  position: 'Goleiro',
  positionGroup: 'goalkeeper',
);

class _FakeSquadRepository implements SquadRepository {
  Result<List<SquadMember>> squadResult = const Success([]);

  @override
  Future<Result<List<SquadMember>>> getSquad() async => squadResult;
}

void main() {
  late _FakeSquadRepository repository;
  late SquadCubit cubit;

  setUp(() {
    repository = _FakeSquadRepository();
    cubit = SquadCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, sem elenco', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.members, isEmpty);
  });

  group('load', () {
    test('sucesso com jogadores emite success com o elenco', () async {
      repository.squadResult = const Success([_member]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.members, [_member]);
    });

    test('sucesso vazio emite LoadStatus.empty', () async {
      repository.squadResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test('falha do repositório emite error com a mensagem', () async {
      repository.squadResult = const Error(ServerFailure('indisponível'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'indisponível');
    });
  });

  test('refresh chama load() de novo', () async {
    repository.squadResult = const Success([_member]);
    await cubit.refresh();
    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.members, [_member]);
  });
}
