import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_details_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Tela própria de UMA competição do catálogo — aberta a partir do catálogo
/// global (`CompetitionCatalogPage`), independente de o clube ativo
/// disputar essa competição ou não (spec multi-competição, item 7/21: uma
/// competição sem participação do clube abre normalmente, nunca um erro de
/// "clube não participa"). Desde a rearquitetura 2026-09-10 busca a
/// TEMPORADA inteira (todas as fases), não só uma tabela — `selectStage`
/// troca a fase mostrada sem nova chamada de rede (todas já vieram juntas).
class CompetitionDetailsCubit extends Cubit<CompetitionDetailsState> {
  CompetitionDetailsCubit(this._repository, this.competitionId)
    : super(const CompetitionDetailsState());

  final FootballRepository _repository;
  final String competitionId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getCompetitionSeason(
      competitionId: competitionId,
    );
    switch (result) {
      case Success(:final data):
        final stages = data.season.stages;
        final current = data.season.currentStage;
        emit(
          state.copyWith(
            status: stages.isEmpty ? LoadStatus.empty : LoadStatus.success,
            competition: data.competition,
            stages: stages,
            selectedStageId: current?.id,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Chamado pelo `CompetitionStageSelector` — nunca refaz a rede, todas as
  /// fases da temporada já vieram na mesma resposta de `load()`.
  void selectStage(String stageId) {
    emit(state.copyWith(selectedStageId: stageId));
  }
}
