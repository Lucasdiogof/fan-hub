import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      // Abre o goleiro da partida padrão (a primeira do banco — Copa do
      // Brasil 1990 x Flamengo). p0 é o Eduardo Heuser, resposta "EDUARDO"
      // (camisa sem número confirmado → "JOGADOR"). Digita pelo teclado
      // físico pra não esbarrar na letra repetida ao procurar as teclas.
      await tester.tap(
        find.byKey(const ValueKey('1990_flamengo_cdb_final_volta-p0')),
      );
      await tester.pumpAndSettle();

      expect(find.text('JOGADOR'), findsOneWidget);

      const keys = [
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyU,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyO,
      ];
      for (final key in keys) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Resolvido: nome revelado na tela de adivinhação.
      expect(find.text('Eduardo Heuser'), findsOneWidget);

      // Volta pro campo sem perder o progresso.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('1/11'), findsOneWidget);

      // Reabrir o mesmo jogador continua mostrando o resultado (não reseta).
      await tester.tap(
        find.byKey(const ValueKey('1990_flamengo_cdb_final_volta-p0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Eduardo Heuser'), findsOneWidget);
    },
  );
}
