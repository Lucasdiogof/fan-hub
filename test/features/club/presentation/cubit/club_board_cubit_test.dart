import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/features/club/domain/repositories/club_board_repository.dart';
import 'package:goias_app/features/club/presentation/cubit/club_board_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _section = ClubBoardSection(
  id: 'diretoria',
  title: 'Diretoria',
  members: [
    ClubBoardMember(
      id: 'm1',
      name: 'Marco Antonio Nassif Abi Chedid',
      role: 'Presidente de Honra',
      displayName: 'Marquinho Chedid',
    ),
  ],
);

class _FakeClubBoardRepository implements ClubBoardRepository {
  Result<List<ClubBoardSection>> boardResult = const Success([]);

  @override
  Future<Result<List<ClubBoardSection>>> getBoard() async => boardResult;
}

void main() {
  late _FakeClubBoardRepository repository;
  late ClubBoardCubit cubit;

  setUp(() {
    repository = _FakeClubBoardRepository();
    cubit = ClubBoardCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, sem seções', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.sections, isEmpty);
  });

  group('load', () {
    test('sucesso com seções emite success com as seções', () async {
      repository.boardResult = const Success([_section]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.sections, [_section]);
    });

    test('sucesso vazio emite LoadStatus.empty', () async {
      repository.boardResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
      expect(cubit.state.sections, isEmpty);
    });

    test('falha do repositório emite error com a mensagem', () async {
      repository.boardResult = const Error(ServerFailure('indisponível'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'indisponível');
    });

    test('sucesso depois de uma falha limpa o errorMessage anterior', () async {
      repository.boardResult = const Error(ServerFailure('indisponível'));
      await cubit.load();
      expect(cubit.state.errorMessage, isNotNull);

      repository.boardResult = const Success([_section]);
      await cubit.load();

      expect(cubit.state.errorMessage, isNull);
    });
  });

  test('refresh chama load() de novo', () async {
    repository.boardResult = const Success([_section]);
    await cubit.refresh();
    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.sections, [_section]);
  });
}
