import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section.dart';

/// Segmented control próprio — não é um `TabBar` do Material.
class GamesSectionSelector extends StatelessWidget {
  const GamesSectionSelector({
    required this.section,
    required this.onChanged,
    super.key,
  });

  final GamesSection section;
  final ValueChanged<GamesSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: context.l10n.matchTabMatches,
              selected: section == GamesSection.matches,
              onTap: () => onChanged(GamesSection.matches),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: context.l10n.matchTabStandings,
              selected: section == GamesSection.standings,
              onTap: () => onChanged(GamesSection.standings),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button - 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button - 4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.4,
            color: selected ? colors.onPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
