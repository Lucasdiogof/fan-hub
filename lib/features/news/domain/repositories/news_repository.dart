import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';

abstract class NewsRepository {
  Future<Result<List<NewsArticle>>> getHighlights();

  Future<Result<List<NewsArticle>>> getLatest({NewsCategory? category});

  Future<Result<NewsArticle>> getById(String id);
}
