import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/presentation/pages/club_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';

void main() {
  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const ClubPage()),
        GoRoute(
          path: '/squad',
          builder: (context, state) => const Scaffold(body: Text('Elenco')),
        ),
        GoRoute(
          path: '/partners',
          builder: (context, state) => const Scaffold(body: Text('Parceiros')),
        ),
        GoRoute(
          path: '/clube/historia',
          builder: (context, state) => const Scaffold(body: Text('História')),
        ),
        GoRoute(
          path: '/clube/linha-do-tempo',
          builder: (context, state) => const Scaffold(body: Text('Linha')),
        ),
        GoRoute(
          path: '/clube/titulos',
          builder: (context, state) => const Scaffold(body: Text('Títulos')),
        ),
        GoRoute(
          path: '/clube/hino',
          builder: (context, state) => const Scaffold(body: Text('Hino')),
        ),
      ],
    );
    return MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  // A página tem 4 cards grandes + uma grade de tiles — não cabe todo no
  // viewport padrão de teste, e o ListView só materializa o que está visível.
  // Aumenta a "tela" pra tudo renderizar de uma vez, sem precisar rolar.
  void useTallSurface(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('shows the club identity and every section entry point', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());

    expect(find.text('GOIÁS ESPORTE CLUBE'), findsOneWidget);
    expect(find.text('História'), findsOneWidget);
    expect(find.text('Elenco'), findsOneWidget);
    expect(find.text('Títulos'), findsOneWidget);
    expect(find.text('Parceiros'), findsOneWidget);
    expect(find.text('Linha do Tempo'), findsOneWidget);
    expect(find.text('Hino & Músicas'), findsOneWidget);
    // Sem conteúdo real ainda — não devem ter entrada nenhuma na tela.
    expect(find.text('Ídolos'), findsNothing);
    expect(find.text('Símbolos'), findsNothing);
    expect(find.text('Uniformes'), findsNothing);
    expect(find.text('Nossa Casa'), findsNothing);
  });

  testWidgets('tapping Parceiros navigates to the shared partners page', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Parceiros'));
    await tester.pumpAndSettle();

    expect(find.text('Parceiros', skipOffstage: false), findsWidgets);
  });

  testWidgets('tapping Hino & Músicas navigates to the songs page', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Hino & Músicas'));
    await tester.pumpAndSettle();

    expect(find.text('Hino'), findsOneWidget);
  });
}
