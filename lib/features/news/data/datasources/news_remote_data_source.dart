import 'package:dio/dio.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/news/data/dto/news_article_dto.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';

/// M4.2A — o gate `?club=` do Worker (`resolveRequestedClubCode`, ver
/// `src/football/_lib/club_server_config.ts`) já existia desde a M4.1, mas
/// NUNCA era alcançado por aqui: sem o parâmetro, o Worker sempre caía no
/// default de compatibilidade (Goiás), então qualquer clube veria notícia
/// real do Goiás. Mandar `club_id`/`club` explícito é o que torna
/// `hasNews=false` uma proteção de verdade, não só cosmética.
class NewsRemoteDataSource {
  NewsRemoteDataSource(this._dio, this._clubConfig);

  final Dio _dio;
  final ClubConfig _clubConfig;

  Future<List<NewsItemDto>> getList() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/news',
      queryParameters: {'club': _clubConfig.identity.code},
    );
    final items = response.data!['items'] as List;
    return items
        .map((item) => NewsItemDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Null quando `available: false` — o backend não conseguiu extrair a
  /// matéria completa dessa vez.
  Future<NewsArticleDto?> getArticle(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/news/$id',
      queryParameters: {'club': _clubConfig.identity.code},
    );
    final data = response.data!;
    if (data['available'] != true) return null;
    return NewsArticleDto.fromJson(data['article'] as Map<String, dynamic>);
  }
}
