import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._footballRepository) : super(const HomeState()) {
    load();
  }

  final FootballRepository _footballRepository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));

    final result = await _footballRepository.getGoiasSnapshot();
    switch (result) {
      case Success(:final data):
        final match = data.nextMatch;
        final stillUpcoming = match != null && DateTime.now().isBefore(match.kickoff);
        emit(
          state.copyWith(
            loading: false,
            nextMatch: stillUpcoming ? match : null,
            clearNextMatch: !stillUpcoming,
          ),
        );
      case Error():
        emit(state.copyWith(loading: false, clearNextMatch: true));
    }
  }
}
