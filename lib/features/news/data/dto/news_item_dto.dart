import 'package:goias_app/features/news/domain/entities/news_item.dart';

class NewsItemDto {
  const NewsItemDto({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAt,
    required this.imageUrl,
    required this.url,
  });

  factory NewsItemDto.fromJson(Map<String, dynamic> json) {
    return NewsItemDto(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      publishedAt: json['publishedAt'] as String,
      imageUrl: json['imageUrl'] as String,
      url: json['url'] as String,
    );
  }

  final String id;
  final String title;
  final String category;
  final String publishedAt;
  final String imageUrl;
  final String url;

  NewsItem toEntity() {
    return NewsItem(
      id: id,
      title: title,
      category: category,
      publishedAt: publishedAt.isEmpty ? null : DateTime.tryParse(publishedAt),
      imageUrl: imageUrl,
      url: url,
    );
  }
}
