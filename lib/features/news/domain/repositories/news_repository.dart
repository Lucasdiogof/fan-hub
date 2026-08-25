import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';

abstract class NewsRepository {
  Future<Result<List<NewsItem>>> getList();

  /// Null quando o backend não conseguiu extrair a matéria completa — quem
  /// chama cai pro link externo do [NewsItem] já em mãos, nunca trata como
  /// erro técnico.
  Future<Result<NewsArticle?>> getArticle(String id);
}
