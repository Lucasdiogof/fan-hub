import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/repositories/club_transparency_repository.dart';
import 'package:goias_app/features/club/presentation/cubit/club_transparency_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubTransparencyCubit extends Cubit<ClubTransparencyState> {
  ClubTransparencyCubit(this._repository)
    : super(const ClubTransparencyState());

  final ClubTransparencyRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getTopics();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            topics: data,
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
