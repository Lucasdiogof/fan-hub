import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/squad/domain/repositories/squad_repository.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// `load()` é chamado explicitamente por quem cria o Cubit (nunca no
/// construtor) — pra nunca disparar duas buscas concorrentes quando o
/// carregamento já acontece antes da navegação (ver `GlobalLoading.run`
/// no ponto de entrada em `profile_page.dart`).
class SquadCubit extends Cubit<SquadState> {
  SquadCubit(this._repository) : super(const SquadState());

  final SquadRepository _repository;

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
    final result = await _repository.getSquad();
    if (isClosed) return;
    switch (result) {
      case Success(:final data, :final cachedAt):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            members: data,
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
