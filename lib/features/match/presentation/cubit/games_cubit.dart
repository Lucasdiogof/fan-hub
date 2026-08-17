import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Centraliza o fetch de dados esportivos da aba Jogos: uma chamada pra
/// partidas (próximo jogo/próximos/resultados são derivados client-side) e
/// uma pra classificação — nenhum widget filho faz sua própria requisição.
class GamesCubit extends Cubit<GamesState> {
  GamesCubit(this._footballRepository) : super(const GamesState()) {
    loadMatches();
    loadStandings();
  }

  final FootballRepository _footballRepository;

  Future<void> loadMatches() async {
    emit(state.copyWith(matchesStatus: LoadStatus.loading));
    final result = await _footballRepository.getMatches();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            matchesStatus: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            matches: data,
          ),
        );
      case Error(:final failure):
        emit(state.copyWith(matchesStatus: LoadStatus.error, matchesErrorMessage: failure.message));
    }
  }

  Future<void> loadStandings() async {
    emit(state.copyWith(standingsStatus: LoadStatus.loading));
    final result = await _footballRepository.getStandings();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            standingsStatus: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            standings: data,
          ),
        );
      case Error(:final failure):
        emit(state.copyWith(standingsStatus: LoadStatus.error, standingsErrorMessage: failure.message));
    }
  }

  /// Pull-to-refresh: refaz as duas buscas. O Cloudflare continua no
  /// caminho — isso não ignora o cache server-side, só força uma nova
  /// leitura no lado do Flutter.
  Future<void> refresh() async {
    await Future.wait([loadMatches(), loadStandings()]);
  }
}
