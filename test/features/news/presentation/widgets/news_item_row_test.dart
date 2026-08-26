import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/presentation/widgets/news_item_row.dart';

const _item = NewsItem(
  id: 'n-1',
  title: 'GOIÁS LANÇA NOVA COLEÇÃO DIADORA 2026',
  category: 'Marketing',
  publishedAt: null,
  imageUrl: 'https://example.com/x.png',
  url: 'https://example.com/n-1',
);

void main() {
  testWidgets('shows the title and the uppercased category', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

        theme: AppTheme.light,
        home: Scaffold(
          body: NewsItemRow(item: _item, onTap: () {}),
        ),
      ),
    );

    expect(find.text('GOIÁS LANÇA NOVA COLEÇÃO DIADORA 2026'), findsOneWidget);
    expect(find.text('MARKETING'), findsOneWidget);
  });

  testWidgets('does not show a relative-time label when publishedAt is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

        theme: AppTheme.light,
        home: Scaffold(
          body: NewsItemRow(item: _item, onTap: () {}),
        ),
      ),
    );

    expect(find.text('•'), findsNothing);
  });

  testWidgets('the whole row is tappable, not just the title', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

        theme: AppTheme.light,
        home: Scaffold(
          body: NewsItemRow(item: _item, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
