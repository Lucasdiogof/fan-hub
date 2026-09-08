import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_cubit.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_state.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';
import 'package:goias_app/features/arena/games/player_identity/presentation/player_identity_copy.dart';
import 'package:goias_app/features/arena/games/player_identity/widgets/player_identity_option_tile.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Uma pergunta por tela — mesma estrutura de `TacticalIdentityQuestionPage`
/// (progresso, "Voltar" preservando a resposta anterior, nunca acumula
/// score imperativamente).
class PlayerIdentityQuestionPage extends StatelessWidget {
  const PlayerIdentityQuestionPage({this.cubit, super.key});

  final PlayerIdentityCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(value: provided, child: const _QuestionView());
    }
    return BlocProvider(
      create: (_) => PlayerIdentityCubit(),
      child: const _QuestionView(),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView();

  void _handleBack(BuildContext context) {
    final cubit = context.read<PlayerIdentityCubit>();
    if (cubit.state.isFirstQuestion) {
      context.canPop() ? context.pop() : context.go('/');
    } else {
      cubit.back();
    }
  }

  void _handleContinue(BuildContext context) {
    final cubit = context.read<PlayerIdentityCubit>();
    if (!cubit.state.answered) return;
    if (cubit.state.isLastQuestion) {
      context.push(
        '/arena/player-identity/processing',
        extra: cubit.finalAnswers,
      );
    } else {
      cubit.next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ContentWidth.form.maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ArenaGameHeader(
                      title: context.playerIdentityGameTitle.toUpperCase(),
                      onBack: () => _handleBack(context),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    BlocBuilder<PlayerIdentityCubit, PlayerIdentityState>(
                      buildWhen: (previous, current) =>
                          previous.index != current.index,
                      builder: (context, state) {
                        final total = playerIdentityQuestions.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${(state.index + 1).toString().padLeft(2, '0')} / '
                              '${total.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: colors.textHint,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (state.index + 1) / total,
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
                      child: BlocBuilder<
                        PlayerIdentityCubit,
                        PlayerIdentityState
                      >(
                        builder: (context, state) {
                          final question = state.currentQuestion;
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.lg,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Text(
                                    question.text,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                for (final option in question.options) ...[
                                  PlayerIdentityOptionTile(
                                    option: option,
                                    selected: state.selected?.id == option.id,
                                    onTap: () => context
                                        .read<PlayerIdentityCubit>()
                                        .selectOption(option),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<PlayerIdentityCubit, PlayerIdentityState>(
                      builder: (context, state) {
                        return AppPrimaryButton(
                          label: state.isLastQuestion
                              ? l10n.playerIdentityCardCtaViewResult
                              : l10n.commonContinue,
                          onPressed: state.answered
                              ? () => _handleContinue(context)
                              : null,
                        );
                      },
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
