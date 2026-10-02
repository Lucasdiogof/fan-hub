import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/widgets/guess_comparison_table.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/domain/player_position.dart';

GuessPlayer _player(String id, {String? academyClub}) => GuessPlayer(
  id: id,
  name: id,
  displayName: id,
  position: PlayerPosition.mei,
  shirtNumber: 10,
  academyClub: academyClub,
  clubDebutYear: 1995,
  dataStatus: GuessPlayerDataStatus.verified,
);

Future<void> _pumpTable(
  WidgetTester tester,
  List<GuessComparisonResult> results, {
  Locale locale = const Locale('pt'),
}) async {
  // Largura de um celular pequeno (360dp) menos o padding da página: a
  // coluna BASE é a mais estreita que a tabela vai ter de verdade.
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GuessComparisonTable(results: results),
        ),
      ),
    ),
  );
}

void main() {
  final secret = _player('secreto', academyClub: 'Goiás');

  testWidgets('palpite sem clube formador mostra "Desconhecido", nunca "—"', (
    tester,
  ) async {
    await _pumpTable(tester, [
      compareGuess(secret: secret, guess: _player('sem_base')),
      compareGuess(
        secret: secret,
        guess: _player('vazio', academyClub: '  '),
      ),
    ]);

    expect(find.text('Desconhecido'), findsNWidgets(2));
    expect(find.text('—'), findsNothing);
  });

  testWidgets('"Desconhecido" cabe inteiro na célula BASE (sem reticências)', (
    tester,
  ) async {
    await _pumpTable(tester, [
      compareGuess(secret: secret, guess: _player('sem_base')),
    ]);

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Desconhecido'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('rótulo traduzido em en/es', (tester) async {
    final results = [compareGuess(secret: secret, guess: _player('a'))];
    await _pumpTable(tester, results, locale: const Locale('en'));
    expect(find.text('Unknown'), findsOneWidget);
    await _pumpTable(tester, results, locale: const Locale('es'));
    expect(find.text('Desconocido'), findsOneWidget);
  });

  testWidgets('palpite com clube formador continua mostrando o clube', (
    tester,
  ) async {
    await _pumpTable(tester, [
      compareGuess(
        secret: secret,
        guess: _player('com_base', academyClub: 'Goiás'),
      ),
    ]);

    expect(find.text('Goiás'), findsOneWidget);
    expect(find.text('Desconhecido'), findsNothing);
  });
}
