import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_details_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Tela própria de UMA competição do catálogo — aberta a partir do catálogo
/// global (`CompetitionCatalogPage`), independente de o clube ativo
/// disputar essa competição ou não (spec multi-competição, item 7/21: uma
/// competição sem participação do clube abre normalmente, nunca um erro de
/// "clube não participa").
class CompetitionDetailsCubit extends Cubit<CompetitionDetailsState> {
  CompetitionDetailsCubit(this._repository, this.competitionId)
    : super(const CompetitionDetailsState());

  final FootballRepository _repository;
  final String competitionId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getStandings(competitionId: competitionId);
    switch (result) {
      case Success(:final data):
        final isEmpty = data.table.isEmpty && data.groups.isEmpty;
        emit(
          state.copyWith(
            status: isEmpty ? LoadStatus.empty : LoadStatus.success,
            competition: data.competition,
            standings: data.table,
            standingGroups: data.groups,
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
}
