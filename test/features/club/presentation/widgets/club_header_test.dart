// ClubHeader — a linha de "orgulho" (headerTagline) é opcional por clube;
// travando aqui a regressão de 2026-09-07: o Bragantino mostrava
// "O MAIOR DO CENTRO-OESTE" (frase real só do Goiás) porque o texto vinha
// hardcoded direto do l10n global em vez do clube ativo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/presentation/widgets/club_header.dart';
import 'package:goias_app/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  Widget wrap() => MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
    home: const Scaffold(body: ClubHeader()),
  );

  testWidgets('Goiás mostra a própria tagline real', (tester) async {
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
    await tester.pumpWidget(wrap());

    expect(find.text('O MAIOR DO CENTRO-OESTE'), findsOneWidget);
  });

  testWidgets(
    'Bragantino: sem tagline própria ainda -> linha simplesmente some, '
    'nunca herda a frase do Goiás',
    (tester) async {
      sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
      await tester.pumpWidget(wrap());

      expect(
        find.text('O MAIOR DO CENTRO-OESTE', skipOffstage: false),
        findsNothing,
      );
      expect(bragantinoClubConfig.identity.headerTagline, isEmpty);
    },
  );
}
