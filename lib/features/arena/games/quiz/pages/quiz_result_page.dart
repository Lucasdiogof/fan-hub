import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Resultado real da rodada de quiz — página própria, mesmo padrão da tela
/// de resultado do Desafio dos Pênaltis (ver `PenaltyResultPage`). Quando a
/// sessão acabou de completar o nível (`data.justCompletedLevel`), mostra
/// também a experiência de conclusão num bottom sheet — uma vez só, não em
/// replays seguintes (isso já é decidido lá no `QuizCubit`).
class QuizResultPage extends StatefulWidget {
  const QuizResultPage({required this.data, super.key});

  final QuizEndData data;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  @override
  void initState() {
    super.initState();
    if (widget.data.justCompletedLevel) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showLevelCompleted(),
      );
    }
  }

  Future<void> _showLevelCompleted() async {
    if (!mounted) return;
    final data = widget.data;
    final wrongCount = data.pendingReviewAfter;
    final rightCount = data.levelAnsweredAfter - wrongCount;
    final l10n = context.l10n;
    final description = StringBuffer()
      ..write(l10n.quizAllAnswered(data.levelTotal))
      ..write('\n\n')
      ..write(l10n.quizCorrectCount(rightCount));
    if (wrongCount > 0) {
      description
        ..write('\n')
        ..write(l10n.quizPendingReview(wrongCount));
    }
    await AppBottomSheet.show(
      // ignore: use_build_context_synchronously
      context,
      icon: Icons.emoji_events_rounded,
      title: l10n.quizLevelCompleted(data.difficulty.label.toUpperCase()),
      description: description.toString(),
      confirmLabel: wrongCount > 0 ? l10n.quizReviewErrors : l10n.quizPlayAgain,
      cancelLabel: l10n.commonClose,
      onConfirm: () {
        if (!mounted) return;
        if (wrongCount > 0) {
          context.pushReplacement(
            '/arena/quiz/play',
            extra: (difficulty: data.difficulty, isReview: true, cubit: null),
          );
        } else {
          context.pushReplacement(
            '/arena/quiz/play',
            extra: (difficulty: data.difficulty, isReview: false, cubit: null),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final colors = context.colors;
    final isPerfect = data.total > 0 && data.correct == data.total;
    final levelComplete =
        !data.isReview && data.levelAnsweredAfter >= data.levelTotal;

    return Scaffold(
      backgroundColor: ArenaColors.arenaBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: FractionallySizedBox(
                widthFactor: 0.88,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (data.isReview
                                  ? context.l10n.quizReviewLevel(
                                      data.difficulty.label,
                                    )
                                  : context.l10n.quizFinalResultLevel(
                                      data.difficulty.label,
                                    ))
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.quizScoreLine(data.correct, data.total),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${data.correct} / ${data.total}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.quizHits,
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isPerfect) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _Badge(
                            label: context.l10n.quizPerfect,
                            color: colors.success,
                          ),
                        ],
                        if (!data.isReview) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            levelComplete
                                ? '${context.l10n.quizLevelQuestions(data.levelAnsweredAfter, data.levelTotal)} · 100%'
                                : context.l10n.quizLevelQuestions(
                                    data.levelAnsweredAfter,
                                    data.levelTotal,
                                  ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (data.pendingReviewAfter > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.quizPendingReview(
                                data.pendingReviewAfter,
                              ),
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Divider(height: 1, color: colors.border),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          context.l10n.quizScore,
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.score} pts',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (data.isNewRecord)
                          _Badge(
                            label: context.l10n.quizNewRecord,
                            color: colors.gold,
                          )
                        else
                          Text(
                            context.l10n.quizBestRecord(data.bestScore),
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 12.5,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: AppPrimaryButton(
                            label: data.isReview
                                ? (data.pendingReviewAfter > 0
                                      ? context.l10n.quizReviewMore
                                      : context.l10n.quizBackToLevels)
                                : (levelComplete
                                      ? context.l10n.quizPlayAgain
                                      : context.l10n.quizMoreQuestions),
                            onPressed: () {
                              if (data.isReview &&
                                  data.pendingReviewAfter == 0) {
                                context.canPop()
                                    ? context.pop()
                                    : context.go('/');
                                return;
                              }
                              context.pushReplacement(
                                '/arena/quiz/play',
                                extra: (
                                  difficulty: data.difficulty,
                                  isReview: data.isReview,
                                  cubit: null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            child: Text(context.l10n.quizBackToArena),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
