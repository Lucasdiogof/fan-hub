import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Centraliza o fetch de dados esportivos da aba Jogos: rodada atual,
/// snapshot do Goiás (próximo jogo + últimos resultados) e classificação
/// vêm de três endpoints independentes — cada um com seu próprio estado,
/// pra uma falha em um não esconder os outros dois.
class GamesCubit extends Cubit<GamesState> {
  GamesCubit(this._footballRepository) : super(const GamesState()) {
    loadCurrentRound();
    loadSnapshot();
    loadStandings();
  }

  final FootballRepository _footballRepository;

  /// [offset] relativo à rodada atual (0) — negativo pra rodadas
  /// anteriores. Sempre reseta pra 0 quando chamado sem argumento (recarga
  /// normal/pull-to-refresh); só `previousRound()`/`nextRound()` passam um
  /// offset explícito, preservando o que já estava sendo mostrado.
  Future<void> loadCurrentRound({int offset = 0}) async {
    emit(state.copyWith(currentRoundStatus: LoadStatus.loading));
    final result = await _footballRepository.getCurrentRound(offset: offset);
    switch (result) {
      case Success(:final data):
        final matches = MatchOrdering.chronological(data.matches);
        emit(
          state.copyWith(
            currentRoundStatus: matches.isEmpty
                ? LoadStatus.empty
                : LoadStatus.success,
            currentRoundMatches: matches,
            roundOffset: offset,
            roundLabel: data.roundLabel,
            clearRoundLabel: data.roundLabel == null,
            hasPreviousRound: data.hasPrevious,
            hasNextRound: data.hasNext,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            currentRoundStatus: LoadStatus.error,
            currentRoundErrorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> previousRound() async {
    if (!state.hasPreviousRound) return;
    await loadCurrentRound(offset: state.roundOffset - 1);
  }

  Future<void> nextRound() async {
    if (!state.hasNextRound) return;
    await loadCurrentRound(offset: state.roundOffset + 1);
  }

  Future<void> loadSnapshot() async {
    emit(state.copyWith(snapshotStatus: LoadStatus.loading));
    final result = await _footballRepository.getGoiasSnapshot();
    switch (result) {
      case Success(:final data):
        final nextMatch =
            data.nextMatch != null && MatchOrdering.isOpen(data.nextMatch!)
            ? data.nextMatch
            : null;
        emit(
          state.copyWith(
            snapshotStatus: nextMatch == null
                ? LoadStatus.empty
                : LoadStatus.success,
            nextMatch: nextMatch,
            clearNextMatch: nextMatch == null,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            snapshotStatus: LoadStatus.error,
            snapshotErrorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> loadStandings() async {
    emit(state.copyWith(standingsStatus: LoadStatus.loading));
    final result = await _footballRepository.getStandings();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            standingsStatus: data.isEmpty
                ? LoadStatus.empty
                : LoadStatus.success,
            standings: data,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            standingsStatus: LoadStatus.error,
            standingsErrorMessage: failure.message,
          ),
        );
    }
  }

  /// Pull-to-refresh: refaz as três buscas. O Cloudflare continua no
  /// caminho — isso não ignora o cache server-side, só força uma nova
  /// leitura no lado do Flutter.
  Future<void> refresh() async {
    await Future.wait([loadCurrentRound(), loadSnapshot(), loadStandings()]);
  }
}
