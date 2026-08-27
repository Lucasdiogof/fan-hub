import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_state.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_keyboard.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_letter_grid.dart';

/// Tela dedicada (não bottom sheet) pro mini-Wordle de um jogador — no
/// celular precisa acomodar voltar + info + 6 linhas + teclado
/// confortavelmente, então full-screen é o que sobra espaço de verdade.
/// Sempre a MESMA instância de [LineupCubit] do campo (ver
/// `LineupPage`), então sair e voltar nunca perde tentativas.
class LineupGuessPage extends StatelessWidget {
  const LineupGuessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<LineupCubit>().closePlayer();
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: BlocBuilder<LineupCubit, LineupState>(
            builder: (context, state) {
              final player = state.selectedPlayer;
              if (player == null) return const SizedBox.shrink();
              final playerState = state.selectedPlayerState;

              return KeyboardListener(
                focusNode: FocusNode()..requestFocus(),
                autofocus: true,
                onKeyEvent: (event) => _handlePhysicalKey(context, event),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: context.colors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.shirtNumber != null
                                        ? context.l10n.lineupShirt(
                                            player.shirtNumber!,
                                          )
                                        : context.l10n.lineupPlayerHeading,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    player.position,
                                    style: TextStyle(
                                      color: context.colors.textHint,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (playerState.isDone)
                                _StatusBadge(solved: playerState.solved)
                              else
                                _WordCountBadge(
                                  answerParts: player.answerParts,
                                ),
                            ],
                          ),
                        ),
                        Container(height: 1, color: context.colors.border),
                        if (!playerState.isDone) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.l10n.lineupTypePlayerName,
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.lg,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (playerState.isDone) ...[
                                    Text(
                                      player.displayName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: playerState.solved
                                            ? context.colors.success
                                            : context.colors.error,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  LineupLetterGrid(
                                    answerParts: player.answerParts,
                                    guesses: playerState.guesses,
                                    currentGuessLetters:
                                        state.currentGuessLetters,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!playerState.isDone)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.sm,
                              0,
                              AppSpacing.sm,
                              AppSpacing.md,
                            ),
                            child: LineupKeyboard(
                              keyboardState: playerState.keyboardState,
                              onLetter: (letter) {
                                HapticFeedback.selectionClick();
                                context.read<LineupCubit>().addLetter(letter);
                              },
                              onDelete: () {
                                HapticFeedback.selectionClick();
                                context.read<LineupCubit>().removeLetter();
                              },
                              onEnter: () => _submit(context),
                              canSubmit: context.read<LineupCubit>().canSubmit,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xl,
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(context.l10n.lineupBackToField),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final cubit = context.read<LineupCubit>();
    if (!cubit.canSubmit) return;
    final wasSolved = cubit.state.selectedPlayerState.solved;
    cubit.submitGuess();
    final isSolvedNow = cubit.state.selectedPlayerState.solved;
    final isFailedNow = cubit.state.selectedPlayerState.failed;
    if (!wasSolved && isSolvedNow) {
      HapticFeedback.mediumImpact();
    } else if (isFailedNow) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _handlePhysicalKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final cubit = context.read<LineupCubit>();
    if (cubit.state.selectedPlayerState.isDone) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      cubit.removeLetter();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _submit(context);
    } else {
      final label = key.keyLabel;
      if (label.length == 1 && RegExp(r'^[A-Za-z]$').hasMatch(label)) {
        cubit.addLetter(label);
      }
    }
  }
}

class _WordCountBadge extends StatelessWidget {
  const _WordCountBadge({required this.answerParts});

  final List<int> answerParts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalLetters = answerParts.fold<int>(0, (sum, part) => sum + part);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checkroom_rounded, size: 13, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            context.l10n.lineupWordCount(answerParts.length, totalLetters),
            style: TextStyle(
              color: colors.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.solved});

  final bool solved;

  @override
  Widget build(BuildContext context) {
    final color = solved ? context.colors.success : context.colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        solved ? Icons.check_rounded : Icons.close_rounded,
        size: 16,
        color: color,
      ),
    );
  }
}
