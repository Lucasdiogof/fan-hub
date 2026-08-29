import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Busca só quando a página abre — nunca pré-carrega detalhes de todas as
/// partidas ao entrar na aba Jogos. `load()` é chamado explicitamente por
/// quem cria o Cubit (nunca no construtor), pra nunca disparar duas buscas
/// concorrentes quando o carregamento já acontece antes da navegação (ver
/// `GlobalLoading.run` nos pontos de entrada).
///
/// Enquanto a partida está ao vivo/intervalo, faz polling silencioso a
/// cada 45s (placar, minuto, eventos, estatísticas) — nunca troca `status`
/// pra `loading` nesse caso, então a tela não pisca nem perde a posição de
/// scroll, só os números atualizam no lugar. Para sozinho assim que a
/// partida deixa de estar aberta. `pausePolling`/`resumePolling` existem
/// pra quem monta a tela (`MatchDetailsPage`) respeitar o ciclo de vida do
/// app — nunca continua batendo no backend com a tela em segundo plano.
class MatchDetailsCubit extends Cubit<MatchDetailsState> {
  MatchDetailsCubit(this._repository, this.fixtureId)
    : super(const MatchDetailsState());

  final FootballRepository _repository;
  final String fixtureId;
  Timer? _pollTimer;
  bool _pollingPaused = false;

  bool get _isLive {
    final status = state.match?.status;
    return status == MatchStatus.live || status == MatchStatus.halftime;
  }

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    await _fetch(silent: false);
    _startPollingIfLive();
  }

  Future<void> _fetch({required bool silent}) async {
    final result = await _repository.getMatchDetails(fixtureId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: LoadStatus.success,
            match: data.match,
            events: data.events,
            lineups: data.lineups,
            stats: data.stats,
          ),
        );
      case Error(:final failure):
        // Num poll silencioso, mantém o último dado bom na tela e tenta de
        // novo no próximo tick — uma falha passageira nunca troca conteúdo
        // cheio por uma mensagem de erro.
        if (!silent) {
          emit(
            state.copyWith(
              status: LoadStatus.error,
              errorMessage: failure.message,
            ),
          );
        }
    }
  }

  void _startPollingIfLive() {
    _pollTimer?.cancel();
    if (_pollingPaused || !_isLive) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _pollTick(),
    );
  }

  Future<void> _pollTick() async {
    await _fetch(silent: true);
    if (!_isLive) _pollTimer?.cancel();
  }

  /// App foi pra segundo plano — nunca continua fazendo polling com a tela
  /// invisível.
  void pausePolling() {
    _pollingPaused = true;
    _pollTimer?.cancel();
  }

  /// App voltou ao primeiro plano — retoma o polling se a partida ainda
  /// estiver ao vivo, e já dispara uma busca na hora (o placar pode ter
  /// mudado inteiro enquanto o app estava em segundo plano).
  void resumePolling() {
    _pollingPaused = false;
    if (_isLive) unawaited(_pollTick());
    _startPollingIfLive();
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
