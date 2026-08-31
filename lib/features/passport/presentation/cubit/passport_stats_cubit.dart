import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_stats_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Números da trajetória do usuário no Passaporte (vitórias/empates/
/// derrotas vistas, jogos em casa/fora, gols) — cubit próprio, carregado só
/// quando a tela de estatísticas abre, nunca junto do resto do Passaporte.
class PassportStatsCubit extends Cubit<PassportStatsState> {
  PassportStatsCubit(this._repository) : super(const PassportStatsState());

  final PassportRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getAttendanceBreakdown();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, breakdown: data));
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
