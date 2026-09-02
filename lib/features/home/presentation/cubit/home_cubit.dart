import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._footballRepository, this._crowdLineupRepository)
    : super(const HomeState()) {
    load();
  }

  final FootballRepository _footballRepository;
  final CrowdLineupRepository _crowdLineupRepository;

  /// Quanto tempo depois do pontapé inicial um jogo encerrado ainda "vale a
  /// pena" mostrar na Home (placar final) antes de trocar pro próximo —
  /// pedido explícito do usuário: "acho justo manter um pouco o jogo que
  /// terminou". Não é literalmente "1 dia após o fim" (não temos o horário
  /// real de término, só o kickoff) — soma uma folga de 3h pro jogo em si
  /// (90min + acréscimos + intervalo) por cima do 1 dia pedido, pra garantir
  /// que o resultado fique visível por pelo menos um dia inteiro depois que
  /// a partida de fato terminou, não só depois que começou.
  static const _finishedGracePeriod = Duration(days: 1, hours: 3);

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final snapshotResult = await _footballRepository.getActiveClubSnapshot();

    switch (snapshotResult) {
      case Success(:final data):
        final resolvedMatch = _resolveMatch(data.nextMatch, data.recentResults);
        // Resolvido por matchId (nunca um booleano global) — se o próximo
        // jogo mudar, essa consulta muda junto, e o card "Escalação da
        // Torcida" volta pra "Escalar agora" pro jogo novo.
        final hasVoted = resolvedMatch == null
            ? false
            : await _hasVotedFor(resolvedMatch.id);
        emit(
          state.copyWith(
            status: LoadStatus.success,
            nextMatch: resolvedMatch,
            clearNextMatch: resolvedMatch == null,
            errorMessage: () => null,
            hasVotedForNextMatch: hasVoted,
          ),
        );
      case Error(:final failure):
        // Nunca confundido com "não existe próximo jogo" (que é
        // `success`/`nextMatch: null`, sem mensagem) — a Home mostra um
        // estado de erro com retry nesse caso, não a experiência de "sem
        // jogo". `nextMatch` continua limpo (mesmo comportamento de antes,
        // só a categoria do estado muda) — não inventamos stale-while-
        // revalidate aqui.
        emit(
          state.copyWith(
            status: LoadStatus.error,
            clearNextMatch: true,
            errorMessage: () => failure.message,
          ),
        );
    }
  }

  /// Decide qual partida a Home mostra, nessa ordem de prioridade:
  /// 1. `nextMatch` ao vivo/intervalo — nunca perde espaço pra um resultado
  ///    antigo só porque ele ainda está dentro da folga.
  /// 2. o último resultado, se ainda estiver dentro da folga de
  ///    [_finishedGracePeriod] (é o "acabou de terminar, ainda vale
  ///    mostrar" pedido pelo usuário) — tem prioridade sobre um próximo
  ///    jogo futuro já disponível.
  /// 3. `nextMatch` agendado, se `MatchOrdering.isOpen` disser que ainda
  ///    vale (regra de sempre).
  /// 4. nada.
  Match? _resolveMatch(Match? nextMatch, List<Match> recentResults) {
    if (nextMatch != null &&
        (nextMatch.status == MatchStatus.live ||
            nextMatch.status == MatchStatus.halftime)) {
      return nextMatch;
    }
    final recentlyFinished = recentResults.isEmpty ? null : recentResults.first;
    if (recentlyFinished != null &&
        recentlyFinished.status == MatchStatus.finished &&
        recentlyFinished.kickoff != null &&
        DateTime.now().difference(recentlyFinished.kickoff!) <
            _finishedGracePeriod) {
      return recentlyFinished;
    }
    return nextMatch != null && MatchOrdering.isOpen(nextMatch)
        ? nextMatch
        : null;
  }

  Future<bool> _hasVotedFor(String matchId) async {
    final result = await _crowdLineupRepository.getMyVote(matchId);
    return switch (result) {
      Success(:final data) => data != null,
      Error() => false,
    };
  }
}
