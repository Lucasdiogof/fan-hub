import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/repositories/club_board_repository.dart';
import 'package:goias_app/features/club/presentation/cubit/club_board_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubBoardCubit extends Cubit<ClubBoardState> {
  ClubBoardCubit(this._repository) : super(const ClubBoardState());

  final ClubBoardRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getBoard();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            sections: data,
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
