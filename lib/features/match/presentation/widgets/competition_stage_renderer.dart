import 'package:flutter/material.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/features/match/domain/entities/stage_type.dart';
import 'package:goias_app/features/match/presentation/widgets/knockout_stage_view.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_content.dart';

/// Decide o que renderizar pra fase selecionada, orientado por
/// `stage.type` — nunca um `if (competition.name == ...)` (spec
/// multi-competição 2026-09-10/11/12, item 13/17/22). Uma Stage `knockout`
/// já carrega todas as suas rodadas ([CompetitionStage.rounds]); quem
/// decide qual rodada mostrar e navega entre elas é o próprio
/// `KnockoutStageView` (fase → lista vertical, sem bracket/scroll
/// horizontal).
class CompetitionStageRenderer extends StatelessWidget {
  const CompetitionStageRenderer({
    required this.stages,
    required this.selectedStageId,
    super.key,
  });

  final List<CompetitionStage> stages;
  final String? selectedStageId;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = stages.indexWhere((s) => s.id == selectedStageId);
    final selected = selectedIndex >= 0 ? stages[selectedIndex] : null;
    if (selected == null) return const SizedBox.shrink();

    if (selected.type == StageType.knockout) {
      return KnockoutStageView(rounds: selected.rounds);
    }

    return StandingsContent(
      standings: selected.standings,
      standingGroups: selected.groups,
    );
  }
}
