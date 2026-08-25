import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_state.dart';
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

  /// Reembaralha a ordem a cada abertura do jogo (os já concluídos ficam
  /// parados no mesmo lugar — só o restante troca de posição). Sempre
  /// começa pelo primeiro ainda não concluído nessa ordem, A NÃO SER que
  /// exista um jogador salvo (ver [saveSelectedId]) em que o usuário
  /// realmente tenha chutado algo — só navegar (`nextPlayer`/
  /// `previousPlayer`) não conta como "retomar daqui", só um chute conta
  /// (ver [guess]). Sem essa distinção, só passar o olho pelos 23
  /// jogadores e sair deixava o jogo "preso" no último olhado.
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
    await _loadPlayer(resumePlayer ?? firstIncomplete);
  }

  Future<void> nextPlayer() async {
    final index = state.currentIndex;
    if (index == null || !state.hasNext) return;
    await _loadPlayer(state.players[index + 1]);
  }

  Future<void> goToNextOrFirst() async {
    final index = state.currentIndex ?? -1;
    final next = (index + 1) % state.players.length;
    await _loadPlayer(state.players[next]);
  }

  Future<void> previousPlayer() async {
    final index = state.currentIndex;
    if (index == null || !state.hasPrevious) return;
    await _loadPlayer(state.players[index - 1]);
  }

  CareerPlayer? _find(String id) {
    for (final candidate in state.players) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  /// NÃO persiste a seleção aqui — só navegar por [nextPlayer]/
  /// [previousPlayer] não é "retomar daqui" (ver [loadSelected]); quem
  /// persiste é [guess], quando o usuário realmente chuta um nome.
  Future<void> _loadPlayer(CareerPlayer player) async {
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        player: player,
        justFinished: false,
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
  }

  void acknowledgeResultShown() {
    if (!state.justFinished) return;
    emit(state.copyWith(justFinished: false));
  }
}
