import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section.dart';

/// Segmented control próprio — não é um `TabBar` do Material.
class GamesSectionSelector extends StatelessWidget {
  const GamesSectionSelector({required this.section, required this.onChanged, super.key});

  final GamesSection section;
  final ValueChanged<GamesSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(AppRadius.button)),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'PARTIDAS',
              selected: section == GamesSection.matches,
              onTap: () => onChanged(GamesSection.matches),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'CLASSIFICAÇÃO',
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
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

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
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button - 4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: selected ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
