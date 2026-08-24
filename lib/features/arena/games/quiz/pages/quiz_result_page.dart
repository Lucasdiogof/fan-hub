import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Resultado real da rodada de quiz — página própria, mesmo padrão da tela
/// de resultado do Desafio dos Pênaltis (ver `PenaltyResultPage`).
class QuizResultPage extends StatelessWidget {
  const QuizResultPage({required this.data, super.key});

  final QuizEndData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPerfect = data.total > 0 && data.correct == data.total;

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
              constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
              child: FractionallySizedBox(
                widthFactor: 0.88,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RESULTADO FINAL · NÍVEL ${data.difficulty.label.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Você acertou ${data.correct} de ${data.total} perguntas',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.35),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '${data.correct} / ${data.total}',
                          style: TextStyle(color: colors.textPrimary, fontSize: 46, fontWeight: FontWeight.w900, height: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ACERTOS',
                          style: TextStyle(color: colors.textHint, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                        if (isPerfect) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _Badge(label: 'Perfeito!', color: colors.success),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Divider(height: 1, color: colors.border),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'PONTUAÇÃO',
                          style: TextStyle(color: colors.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.score} pts',
                          style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (data.isNewRecord)
                          _Badge(label: 'Novo recorde', color: colors.gold)
                        else
                          Text('Recorde: ${data.bestScore} pts', style: TextStyle(color: colors.textHint, fontSize: 12.5)),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: AppPrimaryButton(
                            label: 'MAIS PERGUNTAS',
                            onPressed: () => context.pushReplacement(
                              '/arena/quiz/play',
                              extra: (difficulty: data.difficulty, avoid: data.answeredQuestions),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
    );
  }
}
