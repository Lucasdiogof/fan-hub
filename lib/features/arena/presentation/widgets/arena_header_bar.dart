import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

/// Cabeçalho da Arena — botão de voltar (a Arena agora é uma rota
/// empurrada, não mais uma aba fixa da bottom nav) e botão de Ranking
/// (troféu) na mesma linha, título/subtítulo embaixo — mesmo padrão de
/// `SecurityPage` (seta em cima, título abaixo, nunca dividindo espaço na
/// mesma linha).
class ArenaHeaderBar extends StatelessWidget {
  const ArenaHeaderBar({
    required this.onRankingTap,
    required this.onBack,
    super.key,
  });

  final VoidCallback onRankingTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackButtonCircle(size: 34, iconSize: 16, onTap: onBack),
            const Spacer(),
            _RankingButton(onTap: onRankingTap),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PageTitle(l10n.arenaTitle.toUpperCase()),
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
  const _RankingButton({required this.onTap});

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
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 17,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}
