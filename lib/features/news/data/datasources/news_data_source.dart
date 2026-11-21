import 'package:goias_app/features/news/data/dto/news_article_dto.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';

/// Fonte das notícias (contrato JSON único, ver DTOs). Implementações:
/// `NewsRemoteDataSource` (Worker) e `NewsSnapshotDataSource` (Supabase) —
/// coexistem só durante o rollout (ver `NewsSource`).
abstract interface class NewsDataSource {
  Future<List<NewsItemDto>> getList();

  /// Null quando `available: false` — o backend não conseguiu extrair a
  /// matéria completa dessa vez (a UI abre o link externo).
  Future<NewsArticleDto?> getArticle(String id);
}
