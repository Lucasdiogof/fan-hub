import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/crowd_lineup/domain/position_compatibility.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _compatibility = PositionCompatibilityService();

class CrowdLineupCubit extends Cubit<CrowdLineupState> {
  CrowdLineupCubit({
    required this._repository,
    required this.matchId,
    required bool votingOpen,
  }) : super(CrowdLineupState(votingOpen: votingOpen));

  final CrowdLineupRepository _repository;
  final String matchId;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final voteResult = await _repository.getMyVote(matchId);
    final crowdResult = await _repository.getCrowdLineup(matchId);

    var next = state.copyWith(status: LoadStatus.success);

    switch (voteResult) {
      case Success(:final data) when data != null:
        next = next.copyWith(
          hasVoted: true,
          formationId: data.formationId,
          slots: Map.of(data.playerIdBySlot),
        );
      case Success():
        break;
      case Error():
        next = next.copyWith(status: LoadStatus.error);
    }

    if (crowdResult case Success(:final data)) {
      next = next.copyWith(crowd: data);
    }

    emit(next);
  }

  void selectFormation(String formationId) {
    if (formationId == state.formationId) return;
    final newFormation = formationById(formationId);
    final oldSlots = state.slots;
    final available = oldSlots.values.toSet();
    final result = <int, String>{};

    // Preserva o jogador que estava no MESMO índice, se continuar compatível
    // (qualquer nível de encaixe, não só posição exata).
    for (var i = 0; i < newFormation.slots.length; i++) {
      final pid = oldSlots[i];
      if (pid == null || !available.contains(pid)) continue;
      final fit = _compatibility.fitFor(
        squadById[pid]!,
        newFormation.slots[i].position,
      );
      if (fit != PositionFit.incompatible) {
        result[i] = pid;
        available.remove(pid);
      }
    }
    // Preenche os slots restantes com o jogador que sobrou de MELHOR
    // encaixe pra cada posição (nunca o primeiro compatível por acaso na
    // ordem do Set) — o que não achar ninguém compatível fica vazio, o
    // usuário escolhe de novo.
    for (var i = 0; i < newFormation.slots.length; i++) {
      if (result.containsKey(i)) continue;
      final position = newFormation.slots[i].position;
      String? bestPid;
      var bestScore = -1;
      for (final pid in available) {
        final score = _compatibility.scoreFor(squadById[pid]!, position);
        if (score != null && score > bestScore) {
          bestScore = score;
          bestPid = pid;
        }
      }
      if (bestPid != null) {
        result[i] = bestPid;
        available.remove(bestPid);
      }
    }

    emit(
      state.copyWith(formationId: formationId, slots: result, clearError: true),
    );
  }

  void selectPlayer(int slotIndex, String playerId) {
    final slots = Map.of(state.slots);
    // Sem repetição: se já estava em outro slot, tira de lá (move).
    slots.removeWhere((_, pid) => pid == playerId);
    slots[slotIndex] = playerId;
    emit(state.copyWith(slots: slots, clearError: true));
  }

  void removeSlot(int slotIndex) {
    final slots = Map.of(state.slots)..remove(slotIndex);
    emit(state.copyWith(slots: slots, clearError: true));
  }

  Future<bool> submit() async {
    if (!state.isComplete || !state.votingOpen || state.submitting) {
      return false;
    }
    emit(state.copyWith(submitting: true, clearError: true));
    final vote = LineupVote(
      formationId: state.formationId,
      playerIdBySlot: state.slots,
    );
    final result = await _repository.submitVote(matchId, vote);
    switch (result) {
      case Success():
        final crowd = await _repository.getCrowdLineup(matchId);
        emit(
          state.copyWith(
            submitting: false,
            hasVoted: true,
            crowd: crowd is Success<CrowdLineup> ? crowd.data : state.crowd,
          ),
        );
        return true;
      case Error(:final failure):
        emit(state.copyWith(submitting: false, errorMessage: failure.message));
        return false;
    }
  }
}
