import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/features/social/domain/repositories/social_feed_repository.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class SocialFeedCubit extends Cubit<SocialFeedState> {
  SocialFeedCubit(this._repository) : super(const SocialFeedState()) {
    load();
  }

  final SocialFeedRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getFeed(platform: state.selectedPlatform);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(
          status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
          posts: data,
          errorMessage: () => null,
        ));
      case Error(:final failure):
        emit(state.copyWith(
          status: LoadStatus.error,
          errorMessage: () => failure.message,
        ));
    }
  }

  void selectPlatform(SocialPlatform? platform) {
    if (platform == state.selectedPlatform) return;
    emit(state.copyWith(selectedPlatform: () => platform));
    load();
  }

  Future<void> refresh() => load();
}
