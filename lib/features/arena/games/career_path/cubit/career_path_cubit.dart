import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

export 'package:goias_app/shared/utils/normalize_name.dart' show normalizeName;

class CareerPathCubit extends Cubit<CareerPathState> {
  CareerPathCubit({
    required List<CareerPlayer> players,
    required this.loadRound,
    required this.saveRound,
    required this.loadSelectedId,
    required this.saveSelectedId,
  }) : assert(
         players.isNotEmpty,
         'CareerPathCubit precisa de pelo menos um jogador',
       ),
       super(CareerPathState(players: players)) {
    loadSelected();
  }

  static const maxAttempts = 5;

  final Future<CareerRoundState?> Function(String playerId) loadRound;
  final Future<void> Function(CareerRoundState round) saveRound;
  final Future<String?> Function() loadSelectedId;
  final Future<void> Function(String playerId) saveSelectedId;

  Future<void> loadSelected() async {
    final savedId = await loadSelectedId();
    final players = state.players;
    final player = (savedId != null ? _find(savedId) : null) ?? players.first;
    await _loadPlayer(player);
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
    await saveSelectedId(player.id);
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
  }

  Future<void> reveal() async {
    final round = state.round;
    if (round == null || round.isDone) return;
    final updated = round.copyWith(
      status: CareerRoundStatus.revealed,
      completedAt: DateTime.now(),
    );
    emit(state.copyWith(round: updated, justFinished: true));
    await saveRound(updated);
  }

  void acknowledgeResultShown() {
    if (!state.justFinished) return;
    emit(state.copyWith(justFinished: false));
  }
}
