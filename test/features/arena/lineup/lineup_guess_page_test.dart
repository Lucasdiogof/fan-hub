import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_input_mode.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_guess_page.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_keyboard.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/native_lineup_input.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/l10n/app_localizations.dart';

class _FakeRanking implements ArenaRankingRepository {
  @override
  Future<Result<ScoreResult>> recordScore({
    required String gameId,
    required String itemId,
    required String eventType,
    int? attemptNumber,
    String? difficulty,
    int? wrongCount,
    int? foundCount,
    int? totalCount,
    bool wasRevealed = false,
    bool wasAbandoned = false,
  }) async => const Success(
    ScoreResult(pointsEarned: 0, itemScore: 0, totalScore: 0, gameScore: 0),
  );

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) async => const Success([]);

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) async => const Success(null);

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) =>
      throw UnimplementedError();
}

const _player = LineupPlayer(
  id: 'p',
  position: 'ST',
  x: 0.5,
  y: 0.2,
  shirtNumber: 9,
  fullName: 'Jogador Teste',
  displayName: 'Teste',
  puzzleAnswer: 'PEDRO',
  answerParts: [5],
  normalizedAnswer: 'PEDRO',
);

final _match = LineupMatch(
  id: 'm',
  competition: 'Teste',
  season: '2024',
  phase: 'Final',
  date: DateTime(2024, 1, 1),
  homeTeam: 'Goiás',
  awayTeam: 'Adversário',
  homeScore: 1,
  awayScore: 0,
  teamToGuess: 'Goiás',
  formation: '4-3-3',
  formationConfidence: FormationConfidence.confirmed,
  players: const [_player],
);

LineupCubit _buildCubit() {
  return LineupCubit(
    matches: [_match],
    loadState: (_) async => null,
    saveState: (_) async {},
    loadSelectedMatchId: () async => null,
    saveSelectedMatchId: (_) async {},
    loadCompletedIds: () async => const {},
    ranking: _FakeRanking(),
  );
}

Future<LineupCubit> _pump(
  WidgetTester tester, {
  required LineupGuessInputMode mode,
}) async {
  final cubit = _buildCubit();
  await cubit.loadSelectedMatch();
  cubit.selectPlayer('p');
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      home: BlocProvider.value(
        value: cubit,
        child: LineupGuessPage(inputModeOverride: mode),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  group('input mode switch', () {
    testWidgets('nativeKeyboard renders NativeLineupInput, not LineupKeyboard', (
      tester,
    ) async {
      await _pump(tester, mode: LineupGuessInputMode.nativeKeyboard);
      expect(find.byType(NativeLineupInput), findsOneWidget);
      expect(find.byType(LineupKeyboard), findsNothing);
    });

    testWidgets(
      'customKeyboard still renders LineupKeyboard, not NativeLineupInput '
      '(o teclado antigo continua intacto)',
      (tester) async {
        await _pump(tester, mode: LineupGuessInputMode.customKeyboard);
        expect(find.byType(LineupKeyboard), findsOneWidget);
        expect(find.byType(NativeLineupInput), findsNothing);
      },
    );
  });

  group('nativeKeyboard mode', () {
    testWidgets('typing fills the grid through the same cubit state', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        mode: LineupGuessInputMode.nativeKeyboard,
      );
      await tester.enterText(find.byType(TextField), 'PED');
      await tester.pump();

      expect(cubit.state.currentGuessLetters, ['P', 'E', 'D']);
    });

    testWidgets('confirm stays blocked until the guess is complete', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        mode: LineupGuessInputMode.nativeKeyboard,
      );
      await tester.enterText(find.byType(TextField), 'PED');
      await tester.pump();
      expect(cubit.canSubmit, isFalse);

      await tester.enterText(find.byType(TextField), 'PEDRO');
      await tester.pump();
      expect(cubit.canSubmit, isTrue);
    });

    testWidgets(
      'a wrong guess opens the next attempt with the keyboard still open',
      (tester) async {
        final cubit = await _pump(
          tester,
          mode: LineupGuessInputMode.nativeKeyboard,
        );
        await tester.enterText(find.byType(TextField), 'ERRAD');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(cubit.state.selectedPlayerState.attemptsUsed, 1);
        expect(cubit.state.selectedPlayerState.isDone, isFalse);
        expect(cubit.state.currentGuessLetters, isEmpty);
        // O input nativo continua na árvore — não precisa tocar de novo
        // pra reabrir o teclado.
        expect(find.byType(NativeLineupInput), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'PEDRO');
        await tester.pump();
        expect(cubit.canSubmit, isTrue);
      },
    );

    testWidgets('a correct guess ends the round and closes the input', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        mode: LineupGuessInputMode.nativeKeyboard,
      );
      await tester.enterText(find.byType(TextField), 'PEDRO');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(cubit.state.selectedPlayerState.solved, isTrue);
      expect(find.byType(NativeLineupInput), findsNothing);
    });

    testWidgets('lowercase and non-letter input are normalized away', (
      tester,
    ) async {
      final cubit = await _pump(
        tester,
        mode: LineupGuessInputMode.nativeKeyboard,
      );
      await tester.enterText(find.byType(TextField), 'pé1dro');
      await tester.pump();

      expect(cubit.state.currentGuessLetters.join(), 'PDRO');
    });
  });
}
