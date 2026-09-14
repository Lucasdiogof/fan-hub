import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/features/club/domain/repositories/club_transparency_repository.dart';
import 'package:goias_app/features/club/presentation/cubit/club_transparency_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

final _topic = ClubTransparencyTopic(
  id: 'balanco',
  title: 'Balanço Financeiro',
  documents: [
    ClubTransparencyDocument(
      id: 'd1',
      title: 'Balanço 2025',
      date: DateTime(2026, 1, 1),
      pdfUrl: 'https://example.com/balanco-2025.pdf',
    ),
  ],
);

class _FakeClubTransparencyRepository implements ClubTransparencyRepository {
  Result<List<ClubTransparencyTopic>> topicsResult = const Success([]);

  @override
  Future<Result<List<ClubTransparencyTopic>>> getTopics() async => topicsResult;
}

void main() {
  late _FakeClubTransparencyRepository repository;
  late ClubTransparencyCubit cubit;

  setUp(() {
    repository = _FakeClubTransparencyRepository();
    cubit = ClubTransparencyCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, sem tópicos', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.topics, isEmpty);
  });

  group('load', () {
    test('sucesso com tópicos emite success com os tópicos', () async {
      repository.topicsResult = Success([_topic]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.topics, [_topic]);
    });

    test('sucesso vazio emite LoadStatus.empty', () async {
      repository.topicsResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test('falha do repositório emite error com a mensagem', () async {
      repository.topicsResult = const Error(ServerFailure('indisponível'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'indisponível');
    });
  });

  test('refresh chama load() de novo', () async {
    repository.topicsResult = Success([_topic]);
    await cubit.refresh();
    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.topics, [_topic]);
  });
}
