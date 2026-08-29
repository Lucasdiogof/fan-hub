import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_progress_bar.dart';
import 'package:goias_app/features/arena/shared/arena_game_l10n.dart';

/// Compacto e horizontal — só aparece quando há um desafio de coleção
/// finita (Quiz/Escalação/Jogador) começado e ainda não concluído (ver
/// `_continuePlayingCandidate` em `arena_page.dart`). Reaproveita o mesmo
/// progresso que já alimenta `ArenaChallengeCard`, nunca um contador à
/// parte.
class ContinuePlayingCard extends StatelessWidget {
  const ContinuePlayingCard({
    required this.game,
    required this.progress,
    required this.remainingLabel,
    required this.onTap,
    super.key,
  });

  final ArenaGame game;
  final ({int completed, int total}) progress;
  final String remainingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final fraction = progress.total == 0
        ? 0.0
        : (progress.completed / progress.total).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(game.icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            arenaGameTitle(l10n, game.id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      remainingLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ArenaProgressBar(
                      fraction: fraction,
                      trackColor: colors.border,
                      fillColor: colors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.arenaChallengeCtaContinue,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: colors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
