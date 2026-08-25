import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/news/presentation/widgets/news_home_section.dart';

NewsItem _item(String id) => NewsItem(
  id: id,
  title: 'Notícia $id',
  category: 'Futebol',
  publishedAt: null,
  imageUrl: 'https://example.com/$id.png',
  url: 'https://example.com/n/$id',
);

class _FakeNewsRepository implements NewsRepository {
  _FakeNewsRepository({this.items = const [], this.failure});

  final List<NewsItem> items;
  final Failure? failure;

  @override
  Future<Result<List<NewsItem>>> getList() async {
    if (failure != null) return Error(failure!);
    return Success(items);
  }

  @override
  Future<Result<NewsArticle?>> getArticle(String id) async =>
      const Success(null);
}

Widget _wrap(Widget child) {
  return MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: child),
        ),
        GoRoute(path: '/news', builder: (_, _) => const SizedBox()),
      ],
    ),
  );
}

void main() {
  setUp(() => sl.reset());

  testWidgets('shows up to 3 items and hides the rest', (tester) async {
    sl.registerLazySingleton<NewsCubit>(
      () => NewsCubit(
        _FakeNewsRepository(
          items: [_item('1'), _item('2'), _item('3'), _item('4')],
        ),
      ),
    );

    await tester.pumpWidget(_wrap(const NewsHomeSection()));
    await tester.pumpAndSettle();

    expect(find.text('Notícia 1'), findsOneWidget);
    expect(find.text('Notícia 2'), findsOneWidget);
    expect(find.text('Notícia 3'), findsOneWidget);
    expect(find.text('Notícia 4'), findsNothing);
  });

  testWidgets('shows the section header with "Ver mais"', (tester) async {
    sl.registerLazySingleton<NewsCubit>(
      () => NewsCubit(_FakeNewsRepository(items: [_item('1')])),
    );

    await tester.pumpWidget(_wrap(const NewsHomeSection()));
    await tester.pumpAndSettle();

    expect(find.text('NOTÍCIAS'), findsOneWidget);
    expect(find.text('Ver mais'), findsOneWidget);
  });

  testWidgets(
    'renders nothing when the feed is empty — no jarring empty state on the Home',
    (tester) async {
      sl.registerLazySingleton<NewsCubit>(
        () => NewsCubit(_FakeNewsRepository()),
      );

      await tester.pumpWidget(_wrap(const NewsHomeSection()));
      await tester.pumpAndSettle();

      expect(find.text('NOTÍCIAS'), findsNothing);
    },
  );

  testWidgets(
    'renders nothing on error either — secondary content fails silently on the Home',
    (tester) async {
      sl.registerLazySingleton<NewsCubit>(
        () => NewsCubit(_FakeNewsRepository(failure: const ServerFailure())),
      );

      await tester.pumpWidget(_wrap(const NewsHomeSection()));
      await tester.pumpAndSettle();

      expect(find.text('NOTÍCIAS'), findsNothing);
    },
  );
}
