import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';

abstract interface class SocialFeedRepository {
  Future<Result<List<SocialPost>>> getFeed({SocialPlatform? platform});
}
