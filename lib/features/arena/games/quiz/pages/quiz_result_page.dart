import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    await AppBottomSheet.show(
      // ignore: use_build_context_synchronously
      context,
      icon: Icons.emoji_events_rounded,
      title: 'NÍVEL ${data.difficulty.label.toUpperCase()} CONCLUÍDO',
      description:
          'Você respondeu todas as ${data.levelTotal} perguntas deste nível.\n\n'
          '$rightCount acertadas'
          '${wrongCount > 0 ? '\n$wrongCount para revisar' : ''}',
      confirmLabel: wrongCount > 0 ? 'REVISAR ERROS' : 'JOGAR NOVAMENTE',
      cancelLabel: 'FECHAR',
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
                                  ? 'REVISÃO · NÍVEL ${data.difficulty.label}'
                                  : 'RESULTADO FINAL · NÍVEL ${data.difficulty.label}')
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
                          'Você acertou ${data.correct} de ${data.total} perguntas',
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
                          'ACERTOS',
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isPerfect) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _Badge(label: 'Perfeito!', color: colors.success),
                        ],
                        if (!data.isReview) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            levelComplete
                                ? '${data.levelAnsweredAfter}/${data.levelTotal} perguntas do nível · 100%'
                                : '${data.levelAnsweredAfter}/${data.levelTotal} perguntas do nível',
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
                              '${data.pendingReviewAfter} para revisar',
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
                          'PONTUAÇÃO',
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
                          _Badge(label: 'Novo recorde', color: colors.gold)
                        else
                          Text(
                            'Recorde: ${data.bestScore} pts',
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
                                      ? 'REVISAR MAIS'
                                      : 'VOLTAR AOS NÍVEIS')
                                : (levelComplete
                                      ? 'JOGAR NOVAMENTE'
                                      : 'MAIS PERGUNTAS'),
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
                            child: const Text('VOLTAR À ARENA'),
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
