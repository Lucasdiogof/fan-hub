import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_catalog_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Catálogo GLOBAL de competições (tela "Ver outros campeonatos") — busca
/// próprio, independente do `GamesCubit` da aba Jogos, pra funcionar mesmo
/// se essa tela for aberta fora da árvore de widgets da aba (spec
/// multi-competição, item 5).
class CompetitionCatalogCubit extends Cubit<CompetitionCatalogState> {
  CompetitionCatalogCubit(this._repository)
    : super(const CompetitionCatalogState());

  final FootballRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getCompetitions();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            competitions: data,
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

  void setQuery(String query) => emit(state.copyWith(query: query));
}
