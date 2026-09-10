import 'package:flutter/material.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/presentation/widgets/segmented_chip_row.dart';

/// Seletor horizontal de fases de uma competição (spec multi-competição
/// 2026-09-10, item 13) — `[Fase de Grupos][Eliminatórias]` ou
/// `[Fase de Liga]` sozinho, sempre gerado a partir de [stages], nunca uma
/// lista fixa de nomes na UI. Some sozinho quando só há uma fase.
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
    return SegmentedChipRow(
      items: [
        for (final stage in stages)
          SegmentedChipItem(id: stage.id, label: stage.name),
      ],
      selectedId: selectedStageId,
      onSelected: onSelected,
    );
  }
}
