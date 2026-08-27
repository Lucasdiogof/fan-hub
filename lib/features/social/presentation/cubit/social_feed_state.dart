import 'package:equatable/equatable.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/shared/state/load_status.dart';

class SocialFeedState extends Equatable {
  const SocialFeedState({
    this.status = LoadStatus.initial,
    this.allPosts = const [],
    this.selectedPlatform = SocialPlatform.youtube,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<SocialPost> allPosts;
  final SocialPlatform? selectedPlatform;
  final String? errorMessage;

  List<SocialPost> get posts {
    if (selectedPlatform == null) return allPosts;
    return allPosts.where((p) => p.platform == selectedPlatform).toList();
  }

  SocialFeedState copyWith({
    LoadStatus? status,
    List<SocialPost>? allPosts,
    SocialPlatform? Function()? selectedPlatform,
    String? Function()? errorMessage,
  }) {
    return SocialFeedState(
      status: status ?? this.status,
      allPosts: allPosts ?? this.allPosts,
      selectedPlatform: selectedPlatform != null ? selectedPlatform() : this.selectedPlatform,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allPosts, selectedPlatform, errorMessage];
}
