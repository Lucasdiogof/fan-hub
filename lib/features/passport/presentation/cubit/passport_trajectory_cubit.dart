import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_trajectory_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// "Minha trajetória" — carrega tudo em paralelo (5 chamadas independentes,
/// nenhuma depende do resultado da outra). Só `getSummary` é crítico pro
/// estado de erro da tela inteira; as demais caem pro valor vazio se
/// falharem, pra uma falha isolada (ex.: `passport_stadium_summary`) não
/// travar o resto de uma tela que já teria dado pra mostrar.
class PassportTrajectoryCubit extends Cubit<PassportTrajectoryState> {
  PassportTrajectoryCubit(this._repository)
    : super(const PassportTrajectoryState());

  final PassportRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final summaryFuture = _repository.getSummary();
    final breakdownFuture = _repository.getAttendanceBreakdown();
    final stadiumFuture = _repository.getStadiumSummary();
    final attendedFuture = _repository.getAttendedMatches();
    final memorableIdFuture = _repository.getMemorableMatchId();

    final summaryResult = await summaryFuture;
    if (summaryResult is Error<PassportSummary>) {
      emit(state.copyWith(status: LoadStatus.error));
      return;
    }
    final summary = (summaryResult as Success<PassportSummary>).data;

    final breakdown = switch (await breakdownFuture) {
      Success(:final data) => data,
      Error() => PassportAttendanceBreakdown.empty,
    };
    final stadiumSummary = switch (await stadiumFuture) {
      Success(:final data) => data,
      Error() => PassportStadiumSummary.empty,
    };
    final attendedMatches = switch (await attendedFuture) {
      Success(:final data) => data,
      Error() => const <PassportMatch>[],
    };
    final memorableId = switch (await memorableIdFuture) {
      Success(:final data) => data,
      Error() => null,
    };

    PassportMatch? memorableMatch;
    for (final match in attendedMatches) {
      if (match.id == memorableId) {
        memorableMatch = match;
        break;
      }
    }

    emit(
      state.copyWith(
        status: LoadStatus.success,
        summary: summary,
        breakdown: breakdown,
        stadiumSummary: stadiumSummary,
        attendedMatches: attendedMatches,
        memorableMatch: memorableMatch,
        clearMemorableMatch: memorableMatch == null,
      ),
    );
  }

  Future<bool> selectMemorableMatch(PassportMatch match) async {
    emit(state.copyWith(savingMemorableMatch: true));
    final result = await _repository.setMemorableMatch(match.id);
    switch (result) {
      case Success():
        emit(
          state.copyWith(memorableMatch: match, savingMemorableMatch: false),
        );
        return true;
      case Error():
        emit(state.copyWith(savingMemorableMatch: false));
        return false;
    }
  }
}
