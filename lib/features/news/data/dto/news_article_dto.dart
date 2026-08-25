import 'package:goias_app/features/news/data/dto/news_content_block_dto.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_content_block.dart';

class NewsArticleDto {
  const NewsArticleDto({required this.item, required this.content});

  factory NewsArticleDto.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List)
        .map((block) => parseNewsContentBlock(block as Map<String, dynamic>))
        .toList();
    return NewsArticleDto(item: NewsItemDto.fromJson(json), content: content);
  }

  final NewsItemDto item;
  final List<NewsContentBlock> content;

  NewsArticle toEntity() {
    final base = item.toEntity();
    return NewsArticle(
      id: base.id,
      title: base.title,
      category: base.category,
      publishedAt: base.publishedAt,
      imageUrl: base.imageUrl,
      url: base.url,
      content: content,
    );
  }
}
