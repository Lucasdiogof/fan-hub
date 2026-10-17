import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/repositories/club_transparency_repository.dart';
import 'package:goias_app/features/club/presentation/cubit/club_transparency_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubTransparencyCubit extends Cubit<ClubTransparencyState> {
  ClubTransparencyCubit(this._repository)
    : super(const ClubTransparencyState());

  final ClubTransparencyRepository _repository;

  Future<void>? _inFlight;

  /// Uma única busca por vez: toque repetido, pull-to-refresh e
  /// reconexão enquanto já carrega reaproveitam a mesma operação em vez
  /// de disparar fetches concorrentes.
  Future<void> load() => _inFlight ??= _load().whenComplete(() {
    _inFlight = null;
  });

  Future<void> _load() async {
    // Mantém o conteúdo já exibido durante um refresh (sem piscar loader).
    if (state.status != LoadStatus.success) {
      emit(state.copyWith(status: LoadStatus.loading));
    }
    final result = await _repository.getTopics();
    if (isClosed) return;
    switch (result) {
      case Success(:final data, :final cachedAt):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            topics: data,
            errorMessage: () => null,
            isOffline: false,
            cachedAt: () => cachedAt,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: () => failure.message,
            isOffline: failure is NetworkFailure,
            cachedAt: () => null,
          ),
        );
    }
  }

  Future<void> refresh() => load();
}
