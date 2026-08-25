import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _item = NewsItem(
  id: 'n-1',
  title: 'Título',
  category: 'Futebol',
  publishedAt: null,
  imageUrl: 'https://example.com/x.png',
  url: 'https://example.com/n-1',
);

class _FakeNewsRepository implements NewsRepository {
  List<NewsItem> items = [];
  Failure? listFailure;
  int loadCalls = 0;

  @override
  Future<Result<List<NewsItem>>> getList() async {
    loadCalls++;
    if (listFailure != null) return Error(listFailure!);
    return Success(items);
  }

  @override
  Future<Result<NewsArticle?>> getArticle(String id) async =>
      const Success(null);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('NewsCubit', () {
    test('loads successfully and exposes the items', () async {
      final repository = _FakeNewsRepository()..items = [_item];
      final cubit = NewsCubit(repository);
      await _settle();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.items, [_item]);
      await cubit.close();
    });

    test('an empty list maps to LoadStatus.empty, not success', () async {
      final repository = _FakeNewsRepository();
      final cubit = NewsCubit(repository);
      await _settle();

      expect(cubit.state.status, LoadStatus.empty);
      expect(cubit.state.items, isEmpty);
      await cubit.close();
    });

    test('a failure surfaces the error message and status', () async {
      final repository = _FakeNewsRepository()
        ..listFailure = const ServerFailure('Sem conexão com a internet.');
      final cubit = NewsCubit(repository);
      await _settle();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'Sem conexão com a internet.');
      await cubit.close();
    });

    test(
      'load() runs automatically on construction — no explicit call needed',
      () async {
        final repository = _FakeNewsRepository()..items = [_item];
        NewsCubit(repository);
        await _settle();

        expect(repository.loadCalls, 1);
      },
    );

    test('refresh() re-runs load and can clear a previous error', () async {
      final repository = _FakeNewsRepository()
        ..listFailure = const ServerFailure('erro');
      final cubit = NewsCubit(repository);
      await _settle();
      expect(cubit.state.status, LoadStatus.error);

      repository.listFailure = null;
      repository.items = [_item];
      await cubit.refresh();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });
  });
}
