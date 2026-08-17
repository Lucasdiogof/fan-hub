import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Busca só quando a página abre — nunca pré-carrega detalhes de todas as
/// partidas ao entrar na aba Jogos.
class MatchDetailsCubit extends Cubit<MatchDetailsState> {
  MatchDetailsCubit(this._repository, this.fixtureId) : super(const MatchDetailsState()) {
    load();
  }

  final FootballRepository _repository;
  final String fixtureId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getMatchDetails(fixtureId);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, match: data));
      case Error(:final failure):
        emit(state.copyWith(status: LoadStatus.error, errorMessage: failure.message));
    }
  }
}
