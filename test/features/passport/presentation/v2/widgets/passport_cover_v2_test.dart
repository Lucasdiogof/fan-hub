import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_cover_v2.dart';
import 'package:goias_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, int totalMatches, {ThemeData? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          body: PassportCoverV2(
            summary: PassportSummary(
              totalMatches: totalMatches,
              yearsWithAttendance: 1,
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets('singular: 1 jogo cantando e vibrando com o Verdão', (
    tester,
  ) async {
    await _pump(tester, 1);
    expect(
      find.text('1 jogo cantando e vibrando com o Verdão'),
      findsOneWidget,
    );
  });

  testWidgets('plural: 43 jogos cantando e vibrando com o Verdão', (
    tester,
  ) async {
    await _pump(tester, 43);
    expect(
      find.text('43 jogos cantando e vibrando com o Verdão'),
      findsOneWidget,
    );
  });

  testWidgets('0 jogos mostra o nível Primeiros Passos', (tester) async {
    await _pump(tester, 0);
    expect(find.text('Primeiros Passos'), findsOneWidget);
  });

  testWidgets('43 jogos mostra o nível Esmeraldino de Arquibancada', (
    tester,
  ) async {
    await _pump(tester, 43);
    expect(find.text('Esmeraldino de Arquibancada'), findsOneWidget);
  });

  testWidgets('100 jogos mostra o nível Lenda Esmeraldina', (tester) async {
    await _pump(tester, 100);
    expect(find.text('Lenda Esmeraldina'), findsOneWidget);
  });

  testWidgets('nunca mostra um subtítulo abaixo da headline', (tester) async {
    await _pump(tester, 43);
    // Só eyebrow + selo + headline — nada de "Desde"/temporada no card.
    expect(find.textContaining('Desde'), findsNothing);
    expect(find.textContaining('Temporada'), findsNothing);
  });

  testWidgets(
    'o tamanho do card é o mesmo em todos os níveis — só a decoração muda',
    (tester) async {
      Future<Size> sizeFor(int games) async {
        await _pump(tester, games);
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(PassportCoverV2));
      }

      final s1 = await sizeFor(5);
      final s2 = await sizeFor(15);
      final s3 = await sizeFor(43);
      final s4 = await sizeFor(75);
      final s5 = await sizeFor(150);

      expect(s2, s1);
      expect(s3, s1);
      expect(s4, s1);
      expect(s5, s1);
    },
  );

  testWidgets('renderiza sem erro no tema escuro também', (tester) async {
    await _pump(tester, 43, theme: AppTheme.dark());
    expect(find.byType(PassportCoverV2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
