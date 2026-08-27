import 'package:goias_app/features/social/domain/entities/social_post.dart';

class SocialPostDto {
  const SocialPostDto({
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
    this.likes,
    this.comments,
    this.views,
    this.reposts,
  });

  factory SocialPostDto.fromJson(Map<String, dynamic> json) {
    return SocialPostDto(
      id: json['id'] as String,
      platform: json['platform'] as String,
      authorName: json['authorName'] as String,
      authorHandle: json['authorHandle'] as String,
      mediaType: json['mediaType'] as String,
      publishedAt: json['publishedAt'] as String,
      permalink: json['permalink'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      likes: json['likes'] as int?,
      comments: json['comments'] as int?,
      views: json['views'] as int?,
      reposts: json['reposts'] as int?,
    );
  }

  final String id;
  final String platform;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final String? title;
  final String? text;
  final String mediaType;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String publishedAt;
  final String permalink;
  final int? likes;
  final int? comments;
  final int? views;
  final int? reposts;

  SocialPost toEntity() {
    final hasMetrics =
        likes != null || comments != null || views != null || reposts != null;
    return SocialPost(
      id: id,
      platform: _parsePlatform(platform),
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatarUrl: authorAvatarUrl,
      title: title,
      text: text,
      mediaType: _parseMediaType(mediaType),
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      publishedAt: DateTime.parse(publishedAt),
      permalink: permalink,
      metrics: hasMetrics
          ? SocialMetrics(
              likes: likes,
              comments: comments,
              views: views,
              reposts: reposts,
            )
          : null,
    );
  }

  static SocialPlatform _parsePlatform(String raw) => switch (raw) {
    'youtube' => SocialPlatform.youtube,
    'instagram' => SocialPlatform.instagram,
    'x' => SocialPlatform.x,
    _ => SocialPlatform.youtube,
  };

  static SocialMediaType _parseMediaType(String raw) => switch (raw) {
    'text' => SocialMediaType.text,
    'image' => SocialMediaType.image,
    'video' => SocialMediaType.video,
    'carousel' => SocialMediaType.carousel,
    _ => SocialMediaType.text,
  };
}
