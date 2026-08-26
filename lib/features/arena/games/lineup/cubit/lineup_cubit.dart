import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_state.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/word_evaluation_service.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/shuffle_keeping_done.dart';

/// Um único Cubit cobre campo + tela de adivinhação (ver `LineupPage` e
/// `LineupGuessPage`, que compartilham a mesma instância via
/// `BlocProvider.value` num `Navigator.push` comum — não uma rota nova do
/// go_router). É por isso que "voltar" nunca perde tentativas: não existe
/// um segundo Cubit sendo criado do zero, é a mesma instância o tempo
/// todo, e cada guess enviado já vai pro storage imediatamente.
///
/// Também é o Cubit que navega entre as 31 partidas do banco
/// ([nextMatch]/[previousMatch]/[selectMatch]) — trocar de partida nunca
/// recria o Cubit nem a tela, só troca `state.match`/`state.game` pra
/// outra posição de [matches]. O progresso de cada partida já era isolado
/// por `matchId` no storage (ver `LineupStorage`), então navegar nunca
/// apaga o progresso de nenhuma outra.
class LineupCubit extends Cubit<LineupState> {
  /// `loadSelectedMatch()` é chamado explicitamente por quem cria o Cubit
  /// (nunca aqui no construtor) — pra nunca disparar duas buscas
  /// concorrentes quando o carregamento já acontece antes da navegação
  /// (ver `GlobalLoading.run` no ponto de entrada, `arena_page.dart`).
  LineupCubit({
    required List<LineupMatch> matches,
    required this.loadState,
    required this.saveState,
    required this.loadSelectedMatchId,
    required this.saveSelectedMatchId,
    required this.loadCompletedIds,
    required this.ranking,
  }) : assert(
         matches.isNotEmpty,
         'LineupCubit precisa de pelo menos uma partida',
       ),
       super(LineupState(matches: matches));

  static const maxAttempts = 6;

  final Future<LineupGameState?> Function(String matchId) loadState;
  final Future<void> Function(LineupGameState state) saveState;
  final Future<String?> Function() loadSelectedMatchId;
  final Future<void> Function(String matchId) saveSelectedMatchId;
  final Future<Set<String>> Function() loadCompletedIds;
  final ArenaRankingRepository ranking;

  /// Sempre começa pela primeira partida ainda não concluída (na ordem já
  /// reembaralhada — as concluídas ficam paradas no lugar, só o resto troca
  /// de posição), A NÃO SER que exista uma partida salva (ver
  /// [saveSelectedMatchId]) em que o usuário realmente tenha jogado algo —
  /// só navegar/olhar (`nextMatch`/`previousMatch`) não conta como "retomar
  /// daqui", só um palpite enviado ou uma desistência contam (ver
  /// [submitGuess]/[giveUp]). Sem essa distinção, só passar o olho pelas 31
  /// partidas e sair deixava o jogo "preso" na última olhada, mesmo com
  /// nada de fato jogado ali.
  Future<void> loadSelectedMatch() async {
    final completedIds = await loadCompletedIds();
    final ordered = shuffleKeepingDone(
      state.matches,
      (match) => completedIds.contains(match.id),
    );
    emit(state.copyWith(matches: ordered));

    final savedId = await loadSelectedMatchId();
    final resumeMatch = savedId != null && !completedIds.contains(savedId)
        ? _findMatch(savedId)
        : null;
    final firstIncomplete = ordered.firstWhere(
      (match) => !completedIds.contains(match.id),
      orElse: () => ordered.first,
    );
    await _loadMatch(resumeMatch ?? firstIncomplete);
  }

  Future<void> nextMatch() async {
    final index = state.currentIndex;
    if (index == null || !state.hasNext) return;
    await _loadMatch(state.matches[index + 1]);
  }

  Future<void> previousMatch() async {
    final index = state.currentIndex;
    if (index == null || !state.hasPrevious) return;
    await _loadMatch(state.matches[index - 1]);
  }

  Future<void> selectMatch(String matchId) async {
    final match = _findMatch(matchId);
    if (match == null) return;
    await _loadMatch(match);
  }

  LineupMatch? _findMatch(String matchId) {
    for (final candidate in state.matches) {
      if (candidate.id == matchId) return candidate;
    }
    return null;
  }

  /// Ponto único de troca de partida — usado tanto na carga inicial quanto
  /// em [nextMatch]/[previousMatch]/[selectMatch]. Sempre limpa o jogador
  /// selecionado e o palpite em edição (são da partida anterior, não fazem
  /// sentido na nova). NÃO persiste a seleção aqui — só navegar por
  /// [nextMatch]/[previousMatch] não é "retomar daqui" (ver
  /// [loadSelectedMatch]); quem persiste é [submitGuess]/[giveUp], quando o
  /// usuário realmente joga alguma coisa nessa partida.
  Future<void> _loadMatch(LineupMatch match) async {
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        match: match,
        clearSelectedPlayer: true,
        currentGuessLetters: const [],
        justCompleted: false,
      ),
    );
    final saved = await loadState(match.id);
    final game =
        saved ?? LineupGameState(matchId: match.id, startedAt: DateTime.now());
    emit(state.copyWith(status: LoadStatus.success, game: game));
    if (saved == null) {
      // Persiste já na criação — sem isso, `startedAt` (e o cronômetro do
      // resultado) mudaria toda vez que o app reabrisse antes do primeiro
      // palpite.
      await saveState(game);
    }
  }

  /// Chamado pela UI depois de mostrar o diálogo de resultado — zera
  /// [LineupState.justCompleted] pra ele não disparar de novo sozinho.
  void acknowledgeResultShown() {
    if (!state.justCompleted) return;
    emit(state.copyWith(justCompleted: false));
  }

  void selectPlayer(String playerId) {
    if (state.game == null) return;
    emit(
      state.copyWith(selectedPlayerId: playerId, currentGuessLetters: const []),
    );
  }

  void closePlayer() {
    emit(
      state.copyWith(clearSelectedPlayer: true, currentGuessLetters: const []),
    );
  }

  void addLetter(String letter) {
    final player = state.selectedPlayer;
    if (player == null || state.selectedPlayerState.isDone) return;
    if (state.currentGuessLetters.length >= player.normalizedAnswer.length) {
      return;
    }
    emit(
      state.copyWith(
        currentGuessLetters: [
          ...state.currentGuessLetters,
          letter.toUpperCase(),
        ],
      ),
    );
  }

  void removeLetter() {
    if (state.currentGuessLetters.isEmpty) return;
    final letters = [...state.currentGuessLetters]..removeLast();
    emit(state.copyWith(currentGuessLetters: letters));
  }

  /// `null` se o palpite atual não estiver pronto pra ser enviado (grade
  /// ainda incompleta ou jogador já resolvido/esgotado) — a UI usa isso
  /// pra habilitar/desabilitar o ENTER, sem duplicar essa regra.
  bool get canSubmit {
    final player = state.selectedPlayer;
    if (player == null || state.selectedPlayerState.isDone) return false;
    return state.currentGuessLetters.length == player.normalizedAnswer.length;
  }

  Future<void> submitGuess() async {
    final player = state.selectedPlayer;
    final match = state.match;
    final game = state.game;
    if (player == null || match == null || game == null || !canSubmit) return;

    final playerState = state.selectedPlayerState;
    final guessLetters = state.currentGuessLetters.join();
    final statuses = WordEvaluationService.evaluate(
      normalizedAnswer: player.normalizedAnswer,
      normalizedGuess: guessLetters,
    );
    final keyboardState = WordEvaluationService.mergeKeyboardState(
      previous: playerState.keyboardState,
      normalizedGuess: guessLetters,
      statuses: statuses,
    );
    final guesses = [
      ...playerState.guesses,
      LineupGuess(letters: guessLetters, statuses: statuses),
    ];
    final solved = statuses.every((status) => status == LetterStatus.correct);
    final failed = !solved && guesses.length >= maxAttempts;

    final updatedPlayerState = playerState.copyWith(
      guesses: guesses,
      keyboardState: keyboardState,
      solved: solved,
      failed: failed,
    );
    var updatedGame = game.copyWith(
      playerStates: {...game.playerStates, player.id: updatedPlayerState},
    );
    // `justCompleted` só liga se a partida NÃO estava completa antes desse
    // envio — reabrir uma partida antiga já concluída nunca passa por
    // aqui (o estado carregado já vem com `isDone` em todo mundo, sem
    // nenhum `submitGuess` no meio).
    final wasComplete = _allPlayersDone(match, game);
    final isCompleteNow = _allPlayersDone(match, updatedGame);
    if (isCompleteNow) {
      updatedGame = updatedGame.copyWith(completedAt: DateTime.now());
    }

    final justCompletedNow = !wasComplete && isCompleteNow;
    emit(
      state.copyWith(
        game: updatedGame,
        currentGuessLetters: const [],
        justCompleted: justCompletedNow,
      ),
    );
    await saveState(updatedGame);
    await saveSelectedMatchId(match.id);

    if (justCompletedNow) {
      final states = updatedGame.playerStates.values;
      final failedCount = states.where((p) => p.failed).length;
      final wrongCount = states.fold<int>(
        0,
        (sum, p) => sum + p.attemptsUsed - (p.solved ? 1 : 0),
      );
      unawaited(
        ranking.recordScore(
          gameId: ArenaGameIds.lineup,
          itemId: match.id,
          eventType: failedCount > 0
              ? 'attempts_exhausted'
              : (wrongCount == 0
                    ? 'first_try_correct'
                    : 'correct_after_errors'),
          wrongCount: wrongCount,
        ),
      );
    }
  }

  Future<void> giveUp() async {
    final match = state.match;
    final game = state.game;
    if (match == null || game == null) return;

    final foundCount = state.solvedCount;
    final totalCount = state.totalPlayers;

    final updatedStates = {...game.playerStates};
    for (final player in match.players) {
      final existing = updatedStates[player.id] ?? const LineupPlayerState();
      if (!existing.isDone) {
        updatedStates[player.id] = existing.copyWith(failed: true);
      }
    }
    final wasComplete = _allPlayersDone(match, game);
    final updatedGame = game.copyWith(
      playerStates: updatedStates,
      surrendered: true,
      completedAt: DateTime.now(),
    );
    emit(
      state.copyWith(
        game: updatedGame,
        clearSelectedPlayer: true,
        currentGuessLetters: const [],
        justCompleted: !wasComplete,
      ),
    );
    await saveState(updatedGame);
    await saveSelectedMatchId(match.id);

    if (!wasComplete) {
      unawaited(
        ranking.recordScore(
          gameId: ArenaGameIds.lineup,
          itemId: match.id,
          eventType: 'abandoned',
          wasAbandoned: true,
          foundCount: foundCount,
          totalCount: totalCount,
        ),
      );
    }
  }

  bool _allPlayersDone(LineupMatch match, LineupGameState game) {
    return match.players.every(
      (player) => (game.playerStates[player.id]?.isDone) ?? false,
    );
  }
}
