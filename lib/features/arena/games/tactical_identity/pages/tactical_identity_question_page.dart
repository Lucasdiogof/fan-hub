import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_cubit.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_state.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/presentation/tactical_identity_copy.dart';
import 'package:goias_app/features/arena/games/tactical_identity/widgets/tactical_option_tile.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Uma pergunta por tela, igual o Quiz — mas sem feedback de certo/errado
/// (nunca verde/vermelho/check/X, ver `TacticalOptionTile`) e com "Voltar"
/// de verdade: sair da última pergunta pra revisar/trocar uma resposta
/// anterior é suportado (o cubit nunca perde a seleção ao navegar pra trás).
class TacticalIdentityQuestionPage extends StatelessWidget {
  const TacticalIdentityQuestionPage({this.cubit, super.key});

  final TacticalIdentityCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(value: provided, child: const _QuestionView());
    }
    return BlocProvider(
      create: (_) => TacticalIdentityCubit(),
      child: const _QuestionView(),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView();

  void _handleBack(BuildContext context) {
    final cubit = context.read<TacticalIdentityCubit>();
    if (cubit.state.isFirstQuestion) {
      context.canPop() ? context.pop() : context.go('/');
    } else {
      cubit.back();
    }
  }

  void _handleContinue(BuildContext context) {
    final cubit = context.read<TacticalIdentityCubit>();
    if (!cubit.state.answered) return;
    if (cubit.state.isLastQuestion) {
      context.push(
        '/arena/tactical-identity/processing',
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
              constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ArenaGameHeader(
                      title: l10n.tacticalIdentityGameTitle.toUpperCase(),
                      onBack: () => _handleBack(context),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    BlocBuilder<TacticalIdentityCubit, TacticalIdentityState>(
                      buildWhen: (previous, current) =>
                          previous.index != current.index,
                      builder: (context, state) {
                        final total = tacticalIdentityQuestions.length;
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
                      child:
                          BlocBuilder<
                            TacticalIdentityCubit,
                            TacticalIdentityState
                          >(
                            builder: (context, state) {
                              final question = state.currentQuestion;
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
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: colors.border,
                                        ),
                                      ),
                                      child: Text(
                                        context.tacticalQuestionText(question),
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
                                      TacticalOptionTile(
                                        option: option,
                                        selected:
                                            state.selected?.id == option.id,
                                        onTap: () => context
                                            .read<TacticalIdentityCubit>()
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
                    BlocBuilder<TacticalIdentityCubit, TacticalIdentityState>(
                      builder: (context, state) {
                        return AppPrimaryButton(
                          label: state.isLastQuestion
                              ? l10n.tacticalIdentityCardCtaViewResult
                              : l10n.tacticalQuestionContinue,
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
