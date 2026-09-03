import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/news/presentation/pages/news_list_page.dart';

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

  List<NewsItem> items;
  Failure? failure;
  int calls = 0;

  @override
  Future<Result<List<NewsItem>>> getList() async {
    calls++;
    if (failure != null) return Error(failure!);
    return Success(items);
  }

  @override
  Future<Result<NewsArticle?>> getArticle(String id) async =>
      const Success(null);
}

Widget _wrap() {
  return MaterialApp.router(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,

    theme: AppTheme.light(),
    routerConfig: GoRouter(
      initialLocation: '/news',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/news', builder: (_, _) => const NewsListPage()),
      ],
    ),
  );
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets('shows every item returned by the repository', (tester) async {
    sl.registerLazySingleton<NewsCubit>(
      () => NewsCubit(
        _FakeNewsRepository(items: [_item('1'), _item('2'), _item('3')]),
      ),
    );

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Notícia 1'), findsOneWidget);
    expect(find.text('Notícia 2'), findsOneWidget);
    expect(find.text('Notícia 3'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no items', (tester) async {
    sl.registerLazySingleton<NewsCubit>(() => NewsCubit(_FakeNewsRepository()));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma notícia por aqui ainda'), findsOneWidget);
  });

  testWidgets('shows the error state with the failure message', (tester) async {
    sl.registerLazySingleton<NewsCubit>(
      () => NewsCubit(
        _FakeNewsRepository(
          failure: const ServerFailure('Sem conexão com a internet.'),
        ),
      ),
    );

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as notícias'), findsOneWidget);
    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
  });

  testWidgets('pull-to-refresh re-fetches the list', (tester) async {
    final repository = _FakeNewsRepository(items: [_item('1')]);
    sl.registerLazySingleton<NewsCubit>(() => NewsCubit(repository));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(repository.calls, 1);

    await tester.fling(find.text('Notícia 1'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
  });
}
