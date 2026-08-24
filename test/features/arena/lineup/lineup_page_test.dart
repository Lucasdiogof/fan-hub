import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    sl.registerLazySingleton<LineupStorage>(LineupStorage.new);
  });

  testWidgets(
    'selecionar camisa, digitar, enviar, voltar e ver o progresso atualizado',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const LineupPage()),
      );
      await tester.pumpAndSettle();

      // Progresso inicial: nenhum jogador resolvido ainda.
      expect(find.text('0/11'), findsOneWidget);

      // Abre a camisa 1 (goleiro da partida padrão — Sul-Americana 2010,
      // Harlei, resposta "HARLEI").
      await tester.tap(
        find.byKey(const ValueKey('2010_palmeiras_sulamericana_semi_volta-p0')),
      );
      await tester.pumpAndSettle();

      expect(find.text('CAMISA 1'), findsOneWidget);

      for (final letter in 'HARLEI'.split('')) {
        await tester.tap(find.text(letter));
        await tester.pump();
      }
      await tester.tap(find.text('ENTER'));
      await tester.pumpAndSettle();

      // Resolvido: nome revelado na tela de adivinhação.
      expect(find.text('Harlei'), findsOneWidget);

      // Volta pro campo sem perder o progresso.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('1/11'), findsOneWidget);

      // Reabrir o mesmo jogador continua mostrando o resultado (não reseta).
      await tester.tap(
        find.byKey(const ValueKey('2010_palmeiras_sulamericana_semi_volta-p0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Harlei'), findsOneWidget);
    },
  );
}
