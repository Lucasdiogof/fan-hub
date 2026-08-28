import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/repositories/passport_repository.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_ranking_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Ranking do Passaporte — cubit e estado próprios, nunca reaproveita
/// `RankingCubit`/`RankingState` da Arena (pontuação e regra são outras).
class PassportRankingCubit extends Cubit<PassportRankingState> {
  PassportRankingCubit(this._repository) : super(const PassportRankingState());

  final PassportRepository _repository;

  Future<void> load({int? year}) async {
    emit(state.copyWith(status: LoadStatus.loading, year: () => year));
    final rankingResult = await _repository.getRanking(year: year);
    final myRankResult = await _repository.getMyRank(year: year);

    switch (rankingResult) {
      case Success(:final data):
        final myRank = myRankResult is Success<({int rank, int matchCount})?>
            ? myRankResult.data
            : null;
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            entries: data,
            errorMessage: () => null,
            myRank: () => myRank?.rank,
            myMatchCount: () => myRank?.matchCount,
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

  Future<void> selectYear(int? year) => load(year: year);

  Future<void> refresh() => load(year: state.year);
}
