import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_content_block.dart';
import 'package:goias_app/features/news/presentation/pages/news_article_page.dart';

const _article = NewsArticle(
  id: 'n-1',
  title: 'GOIÁS LANÇA NOVA COLEÇÃO DIADORA 2026',
  category: 'Marketing',
  publishedAt: null,
  imageUrl: '',
  url: 'https://www.goiasec.com.br/noticias/n-1',
  content: [
    NewsParagraphBlock('Primeiro parágrafo.'),
    NewsLinkBlock(text: 'PRESS KIT', url: 'https://example.com/x.pdf'),
  ],
);

Widget _wrap(NewsArticle article) {
  return MaterialApp.router(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,

    theme: AppTheme.light(),
    routerConfig: GoRouter(
      initialLocation: '/news/article',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/news/article',
          builder: (_, _) => NewsArticlePage(article: article),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('shows title, category badge and every content block', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_article));
    await tester.pumpAndSettle();

    expect(find.text('GOIÁS LANÇA NOVA COLEÇÃO DIADORA 2026'), findsOneWidget);
    expect(find.text('MARKETING'), findsOneWidget);
    expect(find.text('Primeiro parágrafo.'), findsOneWidget);
    expect(find.text('PRESS KIT'), findsOneWidget);
  });

  testWidgets('always shows the source footer with the original-article link', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_article));
    await tester.pumpAndSettle();

    expect(find.text('FONTE: GOIÁS ESPORTE CLUBE'), findsOneWidget);
    expect(find.text('Abrir matéria original'), findsOneWidget);
  });

  testWidgets('hides the date row when publishedAt is null', (tester) async {
    await tester.pumpWidget(_wrap(_article));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.event_available_rounded), findsNothing);
  });

  testWidgets('shows the date row when publishedAt is set', (tester) async {
    final article = NewsArticle(
      id: _article.id,
      title: _article.title,
      category: _article.category,
      publishedAt: DateTime(2026, 8, 18),
      imageUrl: _article.imageUrl,
      url: _article.url,
      content: _article.content,
    );
    await tester.pumpWidget(_wrap(article));
    await tester.pumpAndSettle();

    expect(find.text('18/08/2026'), findsOneWidget);
  });
}
