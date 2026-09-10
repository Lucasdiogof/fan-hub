import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';

/// Uma temporada de uma competição (rearquitetura multi-competição
/// 2026-09-10, spec item 7) — mesmo quando o provider só distingue UMA
/// temporada hoje, o contrato já sai nesse formato pra nunca precisar de
/// uma migração de shape depois.
class CompetitionSeason extends Equatable {
  const CompetitionSeason({
    required this.id,
    required this.label,
    required this.stages,
  });

  final String id;
  final String label;
  final List<CompetitionStage> stages;

  /// Fase a abrir por padrão (spec item 8, nessa ordem de prioridade):
  /// 1. a fase marcada como atual pelo provider;
  /// 2. a última fase (mais recente) que já tem dado;
  /// 3. a primeira fase disponível.
  CompetitionStage? get currentStage {
    if (stages.isEmpty) return null;
    for (final stage in stages) {
      if (stage.isCurrent) return stage;
    }
    for (final stage in stages.reversed) {
      if (stage.hasData) return stage;
    }
    return stages.first;
  }

  @override
  List<Object?> get props => [id, label, stages];
}
