import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/arena/shared/arena_game_l10n.dart';
import 'package:goias_app/l10n/app_localizations.dart';

Future<({String quizTitle, String quizTagline})> _quizCopy(
  WidgetTester tester,
  ClubConfig club,
  Locale locale,
) async {
  await sl.reset();
  sl.registerSingleton<ClubConfig>(club);

  late String title;
  late String tagline;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          title = arenaGameTitle(l10n, 'quiz');
          tagline = arenaGameTagline(l10n, 'quiz');
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (quizTitle: title, quizTagline: tagline);
}

void main() {
  tearDown(() => sl.reset());

  const pt = Locale('pt');
  const en = Locale('en');
  const es = Locale('es');

  group('Goiás preserva o texto EXATO de sempre (nunca muda)', () {
    testWidgets('pt: "Quiz do Verdão" / "...conhece o Goiás."', (
      tester,
    ) async {
      final copy = await _quizCopy(tester, goiasClubConfig, pt);
      expect(copy.quizTitle, 'Quiz do Verdão');
      expect(copy.quizTagline, 'Teste o quanto você conhece o Goiás.');
    });

    testWidgets('en: "Goiás Quiz" / "...know Goiás."', (tester) async {
      final copy = await _quizCopy(tester, goiasClubConfig, en);
      expect(copy.quizTitle, 'Goiás Quiz');
      expect(copy.quizTagline, 'Test how well you know Goiás.');
    });

    testWidgets('es: "Quiz del Goiás" / "...conoces al Goiás."', (
      tester,
    ) async {
      final copy = await _quizCopy(tester, goiasClubConfig, es);
      expect(copy.quizTitle, 'Quiz del Goiás');
      expect(copy.quizTagline, 'Pon a prueba cuánto conoces al Goiás.');
    });
  });

  group(
    'Bragantino usa o nome dele — nunca "Verdão"/"Goiás" herdado',
    () {
      for (final (idioma, locale) in [('pt', pt), ('en', en), ('es', es)]) {
        testWidgets('$idioma: zero Goiás/Verdão/Esmeraldino', (tester) async {
          final copy = await _quizCopy(tester, bragantinoClubConfig, locale);
          final blob = '${copy.quizTitle} ${copy.quizTagline}'.toLowerCase();
          expect(blob, isNot(contains('goiás')));
          expect(blob, isNot(contains('goias')));
          expect(blob, isNot(contains('verdão')));
          expect(blob, isNot(contains('esmeraldino')));
          expect(blob, contains('bragantino'));
        });
      }
    },
  );
}
