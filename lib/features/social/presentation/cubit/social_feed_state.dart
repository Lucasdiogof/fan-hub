import 'package:equatable/equatable.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/shared/state/load_status.dart';

class SocialFeedState extends Equatable {
  const SocialFeedState({
    this.status = LoadStatus.initial,
    this.posts = const [],
    this.selectedPlatform,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<SocialPost> posts;
  final SocialPlatform? selectedPlatform;
  final String? errorMessage;

  SocialFeedState copyWith({
    LoadStatus? status,
    List<SocialPost>? posts,
    SocialPlatform? Function()? selectedPlatform,
    String? Function()? errorMessage,
  }) {
    return SocialFeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      selectedPlatform: selectedPlatform != null ? selectedPlatform() : this.selectedPlatform,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, posts, selectedPlatform, errorMessage];
}
