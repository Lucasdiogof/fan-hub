import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/repositories/match_repository.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._matchRepository, this._newsRepository, this._userRepository)
    : super(const HomeState()) {
    load();
  }

  final MatchRepository _matchRepository;
  final NewsRepository _newsRepository;
  final UserRepository _userRepository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));

    final nextMatchFuture = _matchRepository.getNextMatch();
    final newsFuture = _newsRepository.getHighlights();
    final upcomingFuture = _matchRepository.getUpcomingMatches();
    final userFuture = _userRepository.getCurrentUser();

    final nextMatchResult = await nextMatchFuture;
    final newsResult = await newsFuture;
    final upcomingResult = await upcomingFuture;
    final userResult = await userFuture;

    emit(
      state.copyWith(
        loading: false,
        nextMatch: switch (nextMatchResult) { Success(:final data) => data, Error() => null },
        featuredNews: switch (newsResult) {
          Success(:final data) => data.isNotEmpty ? data.first : null,
          Error() => null,
        },
        upcomingMatches: switch (upcomingResult) { Success(:final data) => data, Error() => const [] },
        userName: switch (userResult) {
          Success(:final data) => data.name.split(' ').first,
          Error() => null,
        },
        ticketsOpenMatchIds: MockData.ticketsOpenMatchIds,
      ),
    );
  }
}
