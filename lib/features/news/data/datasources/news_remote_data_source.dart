import 'package:dio/dio.dart';
import 'package:goias_app/features/news/data/dto/news_article_dto.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';

class NewsRemoteDataSource {
  NewsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NewsItemDto>> getList() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/news');
    final items = response.data!['items'] as List;
    return items
        .map((item) => NewsItemDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Null quando `available: false` — o backend não conseguiu extrair a
  /// matéria completa dessa vez.
  Future<NewsArticleDto?> getArticle(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/news/$id');
    final data = response.data!;
    if (data['available'] != true) return null;
    return NewsArticleDto.fromJson(data['article'] as Map<String, dynamic>);
  }
}
