import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_stage.dart';
import 'package:goias_app/shared/state/load_status.dart';

class CompetitionDetailsState extends Equatable {
  const CompetitionDetailsState({
    this.status = LoadStatus.initial,
    this.competition,
    this.stages = const [],
    this.selectedStageId,
    this.errorMessage,
  });

  final LoadStatus status;
  final CompetitionRef? competition;

  /// Todas as fases da temporada (spec multi-competição 2026-09-10, item
  /// 5) — normalmente 1 fase só (Brasileirão, grupos), várias pra
  /// mata-mata (uma por rodada, ver `buildKnockoutRounds` no Worker).
  final List<CompetitionStage> stages;

  /// Fase escolhida no `CompetitionStageSelector` — `null` até a primeira
  /// carga resolver a fase inicial (spec item 8: ativa > última com dado >
  /// primeira).
  final String? selectedStageId;
  final String? errorMessage;

  CompetitionStage? get selectedStage {
    if (stages.isEmpty) return null;
    for (final stage in stages) {
      if (stage.id == selectedStageId) return stage;
    }
    return stages.first;
  }

  CompetitionDetailsState copyWith({
    LoadStatus? status,
    CompetitionRef? competition,
    List<CompetitionStage>? stages,
    String? selectedStageId,
    String? errorMessage,
  }) {
    return CompetitionDetailsState(
      status: status ?? this.status,
      competition: competition ?? this.competition,
      stages: stages ?? this.stages,
      selectedStageId: selectedStageId ?? this.selectedStageId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    competition,
    stages,
    selectedStageId,
    errorMessage,
  ];
}
