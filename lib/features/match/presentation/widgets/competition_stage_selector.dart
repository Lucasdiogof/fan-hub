import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';

/// Seletor horizontal de fases de uma competição (spec multi-competição
/// 2026-09-10, item 13) — `[Fase de Liga][Playoff][Oitavas][Quartas]...` ou
/// `[Fase de grupos][Mata-mata]`, sempre gerado a partir de [stages], nunca
/// uma lista fixa de nomes na UI. Some sozinho quando só há uma fase.
class CompetitionStageSelector extends StatelessWidget {
  const CompetitionStageSelector({
    required this.stages,
    required this.selectedStageId,
    required this.onSelected,
    super.key,
  });

  final List<CompetitionStage> stages;
  final String? selectedStageId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (stages.length <= 1) return const SizedBox.shrink();
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final stage in stages) ...[
            _StageChip(
              label: stage.name,
              selected: stage.id == selectedStageId,
              onTap: () => onSelected(stage.id),
              colors: colors,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
