import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/presentation/pages/club_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  Future<void> useClub(ClubConfig config) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(config);
  }

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
          path: '/clube/titulos',
          builder: (context, state) => const Scaffold(body: Text('Títulos')),
        ),
        GoRoute(
          path: '/clube/idolos',
          builder: (context, state) =>
              const Scaffold(body: Text('Página de Ídolos')),
        ),
        GoRoute(
          path: '/clube/hino',
          builder: (context, state) => const Scaffold(body: Text('Hino')),
        ),
      ],
    );
    return MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  // A página tem 5 cards grandes — não cabe todo no viewport padrão de
  // teste, e o ListView só materializa o que está visível. Aumenta a
  // "tela" pra tudo renderizar de uma vez, sem precisar rolar.
  void useTallSurface(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(800, 1900);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('shows the club identity and every section entry point', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());

    expect(find.text('GOIÁS ESPORTE CLUBE'), findsOneWidget);
    final headerCrest = tester.widget<Image>(find.byType(Image).first);
    expect(
      (headerCrest.image as AssetImage).assetName,
      goiasClubConfig.assets.crestBadge,
    );
    expect(find.text('História'), findsOneWidget);
    expect(find.text('Elenco'), findsOneWidget);
    expect(find.text('Títulos'), findsOneWidget);
    expect(find.text('Parceiros'), findsOneWidget);
    expect(find.text('Hino & Músicas'), findsOneWidget);
    expect(find.text('Linha do Tempo'), findsNothing);
    // Ídolos do Goiás ativados em 2026-10-01 (37 nomes aprovados).
    expect(find.text('Ídolos'), findsOneWidget);
    // Sem conteúdo real ainda — não devem ter entrada nenhuma na tela.
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

  testWidgets('Bragantino ganha a entrada de Ídolos (dataset próprio)', (
    tester,
  ) async {
    useTallSurface(tester);
    await useClub(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Ídolos'), findsOneWidget);
  });

  testWidgets('tocar em Ídolos navega pra página de Ídolos', (tester) async {
    useTallSurface(tester);
    await useClub(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ídolos'));
    await tester.pumpAndSettle();

    expect(find.text('Página de Ídolos'), findsOneWidget);
  });

  testWidgets('Bragantino: subtítulo do tile de Parceiros nunca menciona Goiás '
      '(regressão 2026-09-07 — era um l10n global hardcoded)', (tester) async {
    useTallSurface(tester);
    await useClub(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('Goiás', skipOffstage: false), findsNothing);
    expect(find.textContaining('Verdão', skipOffstage: false), findsNothing);
    expect(find.textContaining('Bragantino'), findsWidgets);
  });
}
