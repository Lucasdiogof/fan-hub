import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/squad/domain/repositories/squad_repository.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class SquadCubit extends Cubit<SquadState> {
  SquadCubit(this._repository) : super(const SquadState()) {
    load();
  }

  final SquadRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getSquad();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            members: data,
            errorMessage: () => null,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: () => failure.message,
          ),
        );
    }
  }

  Future<void> refresh() => load();
}
