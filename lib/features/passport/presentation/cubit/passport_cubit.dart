import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Tela principal do Passaporte — um Cubit só, criado na entrada da tela
/// (`sl<PassportCubit>()..loadInitial()`), sem sub-navegação: seleção,
/// filtro e alterações pendentes vivem juntas aqui porque a experiência
/// inteira (selecionar ano, marcar várias partidas, salvar tudo de uma vez)
/// acontece numa tela só.
class PassportCubit extends Cubit<PassportState> {
  PassportCubit(this._repository) : super(const PassportState());

  final PassportRepository _repository;

  Future<void> loadInitial() async {
    emit(state.copyWith(seasonsStatus: LoadStatus.loading));
    final result = await _repository.getSeasons();
    switch (result) {
      case Success(:final data):
        final defaultYear = data.isEmpty ? null : data.first.season;
        emit(
          state.copyWith(
            seasonsStatus: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            seasons: data,
            selectedYear: () => defaultYear,
          ),
        );
        if (defaultYear != null) {
          unawaited(_loadMatchesForYear(defaultYear));
        }
        unawaited(loadSummary());
      case Error(:final failure):
        emit(
          state.copyWith(
            seasonsStatus: LoadStatus.error,
            matchesErrorMessage: () => failure.message,
          ),
        );
    }
  }

  Future<void> selectYear(int year) async {
    if (year == state.selectedYear) return;
    emit(state.copyWith(selectedYear: () => year));
    await _loadMatchesForYear(year);
  }

  Future<void> _loadMatchesForYear(int year) async {
    emit(state.copyWith(matchesStatus: LoadStatus.loading));
    final result = await _repository.getMatchesForYear(year);
    switch (result) {
      case Success(:final data):
        final marked = data.where((m) => m.isFinished && m.attended).length;
        emit(
          state.copyWith(
            matchesStatus: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            matches: data,
            matchesErrorMessage: () => null,
            markedCountsByYear: {...state.markedCountsByYear, year: marked},
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            matchesStatus: LoadStatus.error,
            matchesErrorMessage: () => failure.message,
          ),
        );
    }
  }

  Future<void> retryLoadYear() async {
    final year = state.selectedYear;
    if (year != null) await _loadMatchesForYear(year);
  }

  Future<void> loadSummary() async {
    final result = await _repository.getSummary();
    if (result is Success<PassportSummary>) {
      emit(state.copyWith(summary: result.data));
    }
  }

  void setFilter(PassportFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void setCompetitionFilter(String? competitionCode) {
    emit(state.copyWith(competitionFilter: () => competitionCode));
  }

  void toggleAttendance(PassportMatch match) {
    if (!match.canMarkAttendance) return;
    final newValue = !state.effectiveAttended(match);
    final updated = Map<String, bool>.from(state.pendingChanges);
    if (newValue == match.attended) {
      updated.remove(match.id);
    } else {
      updated[match.id] = newValue;
    }
    emit(
      state.copyWith(
        pendingChanges: updated,
        saveStatus: LoadStatus.initial,
        saveErrorMessage: () => null,
      ),
    );
  }

  /// Nunca envia as 1.697 partidas — só o delta pendente. Em erro, as
  /// seleções locais continuam intactas pra o usuário tentar de novo sem
  /// perder nada.
  Future<void> save() async {
    if (state.saveStatus == LoadStatus.loading || state.pendingChanges.isEmpty) {
      return;
    }
    emit(state.copyWith(saveStatus: LoadStatus.loading));
    final changes = state.pendingChanges.entries
        .map((e) => PassportAttendanceChange(matchId: e.key, attended: e.value))
        .toList(growable: false);
    final result = await _repository.saveAttendances(changes);
    switch (result) {
      case Success(:final data):
        final rejected = data.where((r) => !r.applied).toList();
        final appliedIds = data.where((r) => r.applied).map((r) => r.matchId).toSet();
        final updatedMatches = [
          for (final m in state.matches)
            if (appliedIds.contains(m.id))
              m.copyWith(attended: state.pendingChanges[m.id])
            else
              m,
        ];
        final remainingPending = Map<String, bool>.from(state.pendingChanges)
          ..removeWhere((id, _) => appliedIds.contains(id));
        final year = state.selectedYear;
        final updatedCounts = year == null
            ? state.markedCountsByYear
            : {
                ...state.markedCountsByYear,
                year: updatedMatches
                    .where((m) => m.season == year && m.isFinished && m.attended)
                    .length,
              };
        emit(
          state.copyWith(
            matches: updatedMatches,
            pendingChanges: remainingPending,
            saveStatus: rejected.isEmpty ? LoadStatus.success : LoadStatus.error,
            saveErrorMessage: () => rejected.isEmpty
                ? null
                : 'Algumas partidas não puderam ser salvas.',
            markedCountsByYear: updatedCounts,
          ),
        );
        unawaited(loadSummary());
      case Error(:final failure):
        // Mantém as seleções locais — o usuário tenta de novo sem perder
        // nada do que já tinha marcado.
        emit(
          state.copyWith(
            saveStatus: LoadStatus.error,
            saveErrorMessage: () => failure.message,
          ),
        );
    }
  }
}
