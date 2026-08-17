import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._newsRepository, this._userRepository)
    : super(const HomeState()) {
    load();
  }

  final NewsRepository _newsRepository;
  final UserRepository _userRepository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));

    final newsFuture = _newsRepository.getHighlights();
    final userFuture = _userRepository.getCurrentUser();

    final newsResult = await newsFuture;
    final userResult = await userFuture;

    emit(
      state.copyWith(
        loading: false,
        featuredNews: switch (newsResult) {
          Success(:final data) => data.isNotEmpty ? data.first : null,
          Error() => null,
        },
        userName: switch (userResult) {
          Success(:final data) => data.name.split(' ').first,
          Error() => null,
        },
      ),
    );
  }
}
