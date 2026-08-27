import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/shared/local_best_score_store.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_cubit.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_state.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// [cubit], quando fornecido, já veio construído e carregado por quem
/// navegou pra cá (ver `GlobalLoading.run` em `quiz_level_page.dart`) — a
/// tela só reaproveita via `BlocProvider.value`. Fica `null` (e a tela
/// cria/carrega o próprio Cubit) só em navegação direta por URL.
class QuizPlayPage extends StatelessWidget {
  const QuizPlayPage({
    required this.difficulty,
    this.isReview = false,
    this.cubit,
    super.key,
  });

  final QuizDifficulty difficulty;
  final bool isReview;
  final QuizCubit? cubit;

  String get _gameId => 'quiz_${difficulty.name}';

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(value: preloaded, child: const _QuizView());
    }
    return BlocProvider(
      create: (_) => QuizCubit(
        difficulty: difficulty,
        isReview: isReview,
        repository: sl<QuizProgressRepository>(),
        questionsRepository: sl<QuizQuestionRepository>(),
        loadBest: () => sl<LocalBestScoreStore>().bestScore(_gameId),
        saveBest: (score) =>
            sl<LocalBestScoreStore>().saveIfBest(_gameId, score),
        ranking: sl<ArenaRankingRepository>(),
      )..init(),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<QuizCubit, QuizState>(
      listenWhen: (previous, current) => !previous.finished && current.finished,
      listener: (context, state) async {
        final cubit = context.read<QuizCubit>();
        final pendingReviewAfter = await sl<QuizProgressRepository>()
            .getPendingReviewIds(cubit.difficulty);
        if (!context.mounted) return;
        context.pushReplacement(
          '/arena/quiz/result',
          extra: QuizEndData(
            difficulty: cubit.difficulty,
            isReview: cubit.isReview,
            correct: state.correctCount,
            total: state.questions.length,
            score: quizScore(state.correctCount),
            bestScore: state.best,
            isNewRecord: state.isNewRecord,
            justCompletedLevel: state.justCompletedLevel,
            levelAnsweredAfter: state.levelAnsweredAfter,
            levelTotal: state.levelTotal,
            pendingReviewAfter: pendingReviewAfter.length,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ArenaGameHeader(
                      title: context.l10n.arenaGameQuizTitle.toUpperCase(),
                      subtitle: context.l10n.quizLevelName(
                        context.read<QuizCubit>().difficulty.label,
                      ),
                      onBack: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: BlocBuilder<QuizCubit, QuizState>(
                        buildWhen: (previous, current) =>
                            previous.status != current.status,
                        builder: (context, statusState) {
                          if (statusState.status != LoadStatus.success) {
                            return const Center(child: GoiasLoadingIndicator());
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BlocBuilder<QuizCubit, QuizState>(
                                builder: (context, state) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        context.l10n.quizQuestionProgress(
                                          state.index + 1,
                                          state.questions.length,
                                        ),
                                        style: TextStyle(
                                          color: colors.textHint,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value:
                                              (state.index + 1) /
                                              state.questions.length,
                                          minHeight: 6,
                                          backgroundColor: colors.border,
                                          valueColor: AlwaysStoppedAnimation(
                                            colors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Expanded(
                                child: BlocBuilder<QuizCubit, QuizState>(
                                  builder: (context, state) {
                                    return SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(
                                              AppSpacing.lg,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: colors.border,
                                              ),
                                            ),
                                            child: Text(
                                              state.currentQuestion.question,
                                              style: TextStyle(
                                                color: colors.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          for (
                                            var i = 0;
                                            i <
                                                state
                                                    .currentQuestion
                                                    .options
                                                    .length;
                                            i++
                                          ) ...[
                                            _OptionTile(index: i, state: state),
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              BlocBuilder<QuizCubit, QuizState>(
                                builder: (context, state) {
                                  return AppPrimaryButton(
                                    label: state.isLastQuestion
                                        ? context.l10n.quizSeeResult
                                        : context.l10n.quizNext,
                                    onPressed: state.answered
                                        ? () => context.read<QuizCubit>().next()
                                        : null,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.index, required this.state});

  final int index;
  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = state.currentQuestion;
    final isCorrect = index == question.correctIndex;
    final isSelected = index == state.selected;

    Color background = colors.surface;
    Color border = colors.border;
    Color foreground = colors.textPrimary;
    IconData? trailingIcon;

    if (state.answered) {
      if (isCorrect) {
        background = colors.success.withValues(alpha: 0.12);
        border = colors.success;
        foreground = colors.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        background = colors.error.withValues(alpha: 0.12);
        border = colors.error;
        foreground = colors.error;
        trailingIcon = Icons.cancel_rounded;
      } else {
        foreground = colors.textHint;
      }
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: state.answered
            ? null
            : () => context.read<QuizCubit>().selectAnswer(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question.options[index],
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: foreground, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
