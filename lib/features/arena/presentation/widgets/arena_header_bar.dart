import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

/// Cabeçalho da Arena — botão de voltar (a Arena agora é uma rota
/// empurrada, não mais uma aba fixa da bottom nav) + título/subtítulo de um
/// lado, botão de Ranking (troféu, com a posição do usuário quando
/// disponível) do outro.
class ArenaHeaderBar extends StatelessWidget {
  const ArenaHeaderBar({
    required this.onRankingTap,
    required this.onBack,
    this.rank,
    super.key,
  });

  final VoidCallback onRankingTap;
  final VoidCallback onBack;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackButtonCircle(size: 34, iconSize: 16, onTap: onBack),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: PageTitle(l10n.arenaTitle.toUpperCase())),
            const SizedBox(width: AppSpacing.sm),
            _RankingButton(rank: rank, onTap: onRankingTap),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.arenaHeaderSubtitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RankingButton extends StatelessWidget {
  const _RankingButton({required this.rank, required this.onTap});

  final int? rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.arenaRankingTitle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.emoji_events_rounded, size: 20, color: colors.primary),
              if (rank != null)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.background, width: 1.5),
                    ),
                    child: Text(
                      '#$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
