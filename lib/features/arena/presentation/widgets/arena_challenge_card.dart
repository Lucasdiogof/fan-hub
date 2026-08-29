import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_progress_bar.dart';
import 'package:goias_app/features/arena/shared/arena_game_l10n.dart';

/// Card único pros 4 desafios da Arena (Quiz, Adivinhe a Escalação,
/// Adivinhe o Jogador, Quem Vestiu o Manto?) — mesma estrutura, altura,
/// padding e tipografia pros quatro, com ou sem coleção finita de
/// progresso (ver spec de reformulação: consistência entre os cards >
/// diferenciação por jogo). `progress` alimenta fração+barra pros 3 jogos
/// de coleção finita; `statLabel` é o texto alternativo pro Quem Vestiu o
/// Manto, que não tem "total" (o mesmo jogador pode voltar a ser secreto).
class ArenaChallengeCard extends StatelessWidget {
  const ArenaChallengeCard({
    required this.game,
    required this.onTap,
    required this.everStarted,
    this.progress,
    this.statLabel,
    super.key,
  });

  final ArenaGame game;
  final VoidCallback onTap;

  /// Só usado quando [progress] é `null` (Quem Vestiu o Manto) pra decidir
  /// entre "Começar"/"Continuar" sem uma fração de coleção.
  final bool everStarted;
  final ({int completed, int total})? progress;
  final String? statLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final resolvedProgress = progress;
    final fraction = resolvedProgress == null || resolvedProgress.total == 0
        ? null
        : (resolvedProgress.completed / resolvedProgress.total).clamp(0.0, 1.0);
    final isCompleted = fraction != null && fraction >= 1.0;
    final ctaLabel = isCompleted
        ? l10n.arenaChallengeCtaCompleted
        : fraction != null && resolvedProgress!.completed > 0
        ? l10n.arenaChallengeCtaContinue
        : fraction == null && everStarted
        ? l10n.arenaChallengeCtaContinue
        : l10n.arenaChallengeCtaStart;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(game.icon, color: colors.primary, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                arenaGameTitle(l10n, game.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 30,
                child: fraction != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${resolvedProgress!.completed}/${resolvedProgress.total} · ${(fraction * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ArenaProgressBar(
                            fraction: fraction,
                            trackColor: colors.border,
                            fillColor: colors.primary,
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          statLabel ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textHint,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    ctaLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? colors.textHint : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: isCompleted ? colors.textHint : colors.primary,
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
