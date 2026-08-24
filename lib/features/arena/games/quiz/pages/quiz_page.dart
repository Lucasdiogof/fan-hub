import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_scores.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_cubit.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_state.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_logic.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

class QuizPlayPage extends StatelessWidget {
  const QuizPlayPage({required this.difficulty, this.avoid = const {}, super.key});

  final QuizDifficulty difficulty;
  final Set<String> avoid;

  String get _gameId => 'quiz_${difficulty.name}';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit(
        difficulty: difficulty,
        avoid: avoid,
        loadBest: () => sl<ArenaScores>().bestScore(_gameId),
        saveBest: (score) => sl<ArenaScores>().saveIfBest(_gameId, score),
      ),
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
      listener: (context, state) {
        final cubit = context.read<QuizCubit>();
        context.pushReplacement(
          '/arena/quiz/result',
          extra: QuizEndData(
            difficulty: cubit.difficulty,
            answeredQuestions: state.questions.map((question) => question.question).toSet(),
            correct: state.correctCount,
            total: state.questions.length,
            score: quizScore(state.correctCount),
            bestScore: state.best,
            isNewRecord: state.isNewRecord,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.canPop() ? context.pop() : context.go('/'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUIZ DO VERDÃO',
                            style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                          ),
                          Text(
                            'Nível ${context.read<QuizCubit>().difficulty.label}',
                            style: TextStyle(color: colors.textHint, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                BlocBuilder<QuizCubit, QuizState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pergunta ${state.index + 1} de ${state.questions.length}',
                          style: TextStyle(color: colors.textHint, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (state.index + 1) / state.questions.length,
                            minHeight: 6,
                            backgroundColor: colors.border,
                            valueColor: AlwaysStoppedAnimation(colors.primary),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                state.currentQuestion.question,
                                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            for (var i = 0; i < state.currentQuestion.options.length; i++) ...[
                              _OptionTile(index: i, state: state),
                              const SizedBox(height: AppSpacing.sm),
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
                      label: state.isLastQuestion ? 'VER RESULTADO' : 'PRÓXIMA',
                      onPressed: state.answered ? () => context.read<QuizCubit>().next() : null,
                    );
                  },
                ),
              ],
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
        onTap: state.answered ? null : () => context.read<QuizCubit>().selectAnswer(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question.options[index],
                  style: TextStyle(color: foreground, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (trailingIcon != null) Icon(trailingIcon, color: foreground, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }
}
