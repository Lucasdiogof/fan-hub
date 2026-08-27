import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
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

  /// Cache em memória por offset dentro desta sessão de tela. Rodada passada
  /// (resultados) e futura (agenda) não mudam, então navegar pra uma rodada
  /// já vista não refaz a rede — aparece na hora. Vive só enquanto o cubit
  /// vive: como ele é `registerFactory` (instância nova a cada entrada na
  /// aba Jogos), sair e voltar recria o cubit, o cache zera e a rodada atual
  /// é buscada de novo — que é o único dado que pode ter mudado. O
  /// pull-to-refresh limpa o cache explicitamente (ver `refresh`).
  final Map<int, _RoundSnapshot> _roundCache = {};

  /// [offset] relativo à rodada atual (0) — negativo pra rodadas
  /// anteriores. Sempre reseta pra 0 quando chamado sem argumento (recarga
  /// normal/pull-to-refresh); só `previousRound()`/`nextRound()` passam um
  /// offset explícito, preservando o que já estava sendo mostrado.
  Future<void> loadCurrentRound({int offset = 0}) async {
    final cached = _roundCache[offset];
    if (cached != null) {
      emit(_stateForRound(offset, cached));
      return;
    }
    emit(state.copyWith(currentRoundStatus: LoadStatus.loading));
    final result = await _footballRepository.getCurrentRound(offset: offset);
    switch (result) {
      case Success(:final data):
        final snapshot = _RoundSnapshot(
          matches: MatchOrdering.chronological(data.matches),
          roundLabel: data.roundLabel,
          hasPrevious: data.hasPrevious,
          hasNext: data.hasNext,
        );
        _roundCache[offset] = snapshot;
        emit(_stateForRound(offset, snapshot));
      case Error(:final failure):
        emit(
          state.copyWith(
            currentRoundStatus: LoadStatus.error,
            currentRoundErrorMessage: failure.message,
          ),
        );
    }
  }

  GamesState _stateForRound(int offset, _RoundSnapshot snapshot) {
    return state.copyWith(
      currentRoundStatus: snapshot.matches.isEmpty
          ? LoadStatus.empty
          : LoadStatus.success,
      currentRoundMatches: snapshot.matches,
      roundOffset: offset,
      roundLabel: snapshot.roundLabel,
      clearRoundLabel: snapshot.roundLabel == null,
      hasPreviousRound: snapshot.hasPrevious,
      hasNextRound: snapshot.hasNext,
    );
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

  /// Pull-to-refresh: refaz as três buscas. Limpa o cache de rodadas
  /// primeiro — é o gesto explícito do usuário pedindo dados novos, então a
  /// rodada atual (e as demais já vistas) volta a ser buscada de verdade. O
  /// Cloudflare continua no caminho — isso não ignora o cache server-side,
  /// só força uma nova leitura no lado do Flutter.
  Future<void> refresh() async {
    _roundCache.clear();
    await Future.wait([loadCurrentRound(), loadSnapshot(), loadStandings()]);
  }
}

class _RoundSnapshot {
  const _RoundSnapshot({
    required this.matches,
    required this.roundLabel,
    required this.hasPrevious,
    required this.hasNext,
  });

  final List<Match> matches;
  final String? roundLabel;
  final bool hasPrevious;
  final bool hasNext;
}
