import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';

class MockNewsRepository implements NewsRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Result<List<NewsArticle>>> getHighlights() async {
    await Future<void>.delayed(_latency);
    final sorted = [...MockData.news]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return Success(sorted.take(3).toList());
  }

  @override
  Future<Result<List<NewsArticle>>> getLatest({NewsCategory? category}) async {
    await Future<void>.delayed(_latency);
    final filtered = category == null
        ? MockData.news
        : MockData.news.where((n) => n.category == category).toList();
    final sorted = [...filtered]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return Success(sorted);
  }

  @override
  Future<Result<NewsArticle>> getById(String id) async {
    await Future<void>.delayed(_latency);
    for (final article in MockData.news) {
      if (article.id == id) return Success(article);
    }
    return const Error(UnexpectedFailure('Notícia não encontrada.'));
  }
}
