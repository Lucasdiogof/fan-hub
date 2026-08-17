import 'package:equatable/equatable.dart';

enum SocialPlatform { instagram, youtube, x }

enum SocialMediaType { text, image, video, carousel }

class SocialMetrics extends Equatable {
  const SocialMetrics({this.likes, this.comments, this.views, this.reposts});

  final int? likes;
  final int? comments;
  final int? views;
  final int? reposts;

  @override
  List<Object?> get props => [likes, comments, views, reposts];
}

class SocialPost extends Equatable {
  const SocialPost({
    required this.id,
    required this.platform,
    required this.authorName,
    required this.authorHandle,
    required this.mediaType,
    required this.publishedAt,
    required this.permalink,
    this.authorAvatarUrl,
    this.title,
    this.text,
    this.imageUrl,
    this.thumbnailUrl,
    this.metrics,
  });

  final String id;
  final SocialPlatform platform;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final String? title;
  final String? text;
  final SocialMediaType mediaType;
  final String? imageUrl;
  final String? thumbnailUrl;
  final DateTime publishedAt;
  final String permalink;
  final SocialMetrics? metrics;

  @override
  List<Object?> get props => [
    id,
    platform,
    authorName,
    authorHandle,
    authorAvatarUrl,
    title,
    text,
    mediaType,
    imageUrl,
    thumbnailUrl,
    publishedAt,
    permalink,
    metrics,
  ];
}
