import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_state.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';
import 'package:goias_app/shared/utils/shuffle_keeping_done.dart';

export 'package:goias_app/shared/utils/normalize_name.dart' show normalizeName;

class CareerPathCubit extends Cubit<CareerPathState> {
  /// `loadSelected()` é chamado explicitamente por quem cria o Cubit
  /// (nunca aqui no construtor) — pra nunca disparar duas buscas
  /// concorrentes quando o carregamento já acontece antes da navegação
  /// (ver `GlobalLoading.run` no ponto de entrada, `arena_page.dart`).
  CareerPathCubit({
    required List<CareerPlayer> players,
    required this.loadRound,
    required this.saveRound,
    required this.loadSelectedId,
    required this.saveSelectedId,
    required this.loadCompletedIds,
    required this.ranking,
  }) : assert(
         players.isNotEmpty,
         'CareerPathCubit precisa de pelo menos um jogador',
       ),
       super(CareerPathState(players: players));

  static const maxAttempts = 5;

  final Future<CareerRoundState?> Function(String playerId) loadRound;
  final Future<void> Function(CareerRoundState round) saveRound;
  final Future<String?> Function() loadSelectedId;
  final Future<void> Function(String playerId) saveSelectedId;
  final Future<Set<String>> Function() loadCompletedIds;
  final ArenaRankingRepository ranking;

  /// Jogadores já mostrados nesta sessão (não persiste, só existe enquanto
  /// o Cubit vive) — usado por [goToNextOrFirst] pra nunca repetir um até
  /// ter dado a volta em todos os outros.
  final _shownThisSession = <String>{};

  /// Reembaralha a ordem a cada abertura do jogo (os já concluídos ficam
  /// parados no mesmo lugar — só o restante troca de posição). Sempre
  /// começa pelo primeiro ainda não concluído nessa ordem, A NÃO SER que
  /// exista um jogador salvo (ver [saveSelectedId]) em que o usuário
  /// realmente tenha chutado algo — só navegar não conta como "retomar
  /// daqui", só um chute conta (ver [guess]). Sem essa distinção, só passar
  /// o olho pelos 23 jogadores e sair deixava o jogo "preso" no último
  /// olhado.
  Future<void> loadSelected() async {
    final completedIds = await loadCompletedIds();
    final ordered = shuffleKeepingDone(
      state.players,
      (player) => completedIds.contains(player.id),
    );
    emit(state.copyWith(players: ordered));

    final savedId = await loadSelectedId();
    final resumePlayer = savedId != null && !completedIds.contains(savedId)
        ? _find(savedId)
        : null;
    final firstIncomplete = ordered.firstWhere(
      (player) => !completedIds.contains(player.id),
      orElse: () => ordered.first,
    );
    _shownThisSession.clear();
    await _loadPlayer(resumePlayer ?? firstIncomplete, roundNumber: 1);
  }

  /// Sorteia o próximo jogador entre os que ainda não apareceram nesta
  /// sessão — cada "Próximo jogador" é um sorteio novo, não um passo fixo
  /// numa ordem definida só na entrada. Ao esgotar todos, começa outra
  /// volta (também sorteada) sem repetir o jogador atual na virada.
  Future<void> goToNextOrFirst() async {
    final current = state.player;
    var pool = state.players
        .where(
          (player) =>
              player.id != current?.id &&
              !_shownThisSession.contains(player.id),
        )
        .toList();
    var roundNumber = state.roundNumber + 1;
    if (pool.isEmpty) {
      _shownThisSession.clear();
      pool = state.players.where((player) => player.id != current?.id).toList();
      roundNumber = 1;
    }
    pool.shuffle();
    final next = pool.isNotEmpty ? pool.first : state.players.first;
    await _loadPlayer(next, roundNumber: roundNumber);
  }

  CareerPlayer? _find(String id) {
    for (final candidate in state.players) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  /// NÃO persiste a seleção aqui — só navegar não é "retomar daqui" (ver
  /// [loadSelected]); quem persiste é [guess], quando o usuário realmente
  /// chuta um nome.
  Future<void> _loadPlayer(
    CareerPlayer player, {
    required int roundNumber,
  }) async {
    _shownThisSession.add(player.id);
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        player: player,
        justFinished: false,
        roundNumber: roundNumber,
      ),
    );
    final saved = await loadRound(player.id);
    final round =
        saved ??
        CareerRoundState(playerId: player.id, startedAt: DateTime.now());
    emit(state.copyWith(status: LoadStatus.success, round: round));
    if (saved == null) await saveRound(round);
  }

  bool isCorrect(CareerPlayer player, String guess) {
    final normalized = normalizeName(guess);
    return player.acceptedAnswers.any(
      (answer) => normalizeName(answer) == normalized,
    );
  }

  Future<void> guess(String name) async {
    final player = state.player;
    final round = state.round;
    if (player == null || round == null || round.isDone) return;

    if (isCorrect(player, name)) {
      final updated = round.copyWith(
        status: CareerRoundStatus.won,
        completedAt: DateTime.now(),
      );
      emit(state.copyWith(round: updated, justFinished: true));
      await saveRound(updated);
      await saveSelectedId(player.id);
      unawaited(
        ranking.recordScore(
          gameId: ArenaGameIds.careerPath,
          itemId: player.id,
          eventType: round.attemptsToWin == 1
              ? 'first_try_correct'
              : 'correct_after_errors',
          attemptNumber: round.attemptsToWin,
        ),
      );
      return;
    }

    final wrongGuesses = [...round.wrongGuesses, name];
    final lost = wrongGuesses.length >= maxAttempts;
    final updated = round.copyWith(
      wrongGuesses: wrongGuesses,
      status: lost ? CareerRoundStatus.lost : CareerRoundStatus.playing,
      completedAt: lost ? DateTime.now() : null,
    );
    emit(state.copyWith(round: updated, justFinished: lost));
    await saveRound(updated);
    await saveSelectedId(player.id);
    if (lost) {
      unawaited(
        ranking.recordScore(
          gameId: ArenaGameIds.careerPath,
          itemId: player.id,
          eventType: 'attempts_exhausted',
          wasRevealed: true,
        ),
      );
    }
  }

  Future<void> reveal() async {
    final player = state.player;
    final round = state.round;
    if (player == null || round == null || round.isDone) return;
    final updated = round.copyWith(
      status: CareerRoundStatus.revealed,
      completedAt: DateTime.now(),
    );
    emit(state.copyWith(round: updated, justFinished: true));
    await saveRound(updated);
    await saveSelectedId(player.id);
    unawaited(
      ranking.recordScore(
        gameId: ArenaGameIds.careerPath,
        itemId: player.id,
        eventType: 'revealed',
        wasRevealed: true,
      ),
    );
  }

  void acknowledgeResultShown() {
    if (!state.justFinished) return;
    emit(state.copyWith(justFinished: false));
  }
}
