import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/data/datasources/news_remote_data_source.dart';
import 'package:goias_app/features/news/data/dto/news_article_dto.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';
import 'package:goias_app/features/news/data/repositories/news_repository_impl.dart';

const _itemJson = {
  'id': 'n-1',
  'title': 'Título',
  'category': 'Futebol',
  'publishedAt': '2026-08-18',
  'imageUrl': 'https://example.com/x.png',
  'url': 'https://example.com/n-1',
};

const _articleJson = {..._itemJson, 'content': <Map<String, String>>[]};

/// Dublê em memória — sobrescreve os 2 métodos que fazem rede, mesma ideia
/// do `_FakeLineupStorage` em `test/features/arena/lineup/lineup_page_test.dart`.
class _FakeNewsRemoteDataSource extends NewsRemoteDataSource {
  _FakeNewsRemoteDataSource() : super(Dio(), goiasClubConfig);

  List<NewsItemDto>? listResult;
  Object? listError;
  NewsArticleDto? articleResult;
  Object? articleError;

  @override
  Future<List<NewsItemDto>> getList() async {
    if (listError != null) throw listError!;
    return listResult ?? [];
  }

  @override
  Future<NewsArticleDto?> getArticle(String id) async {
    if (articleError != null) throw articleError!;
    return articleResult;
  }
}

void main() {
  group('NewsRepositoryImpl.getList', () {
    test('maps DTOs to entities on success', () async {
      final remote = _FakeNewsRemoteDataSource()
        ..listResult = [NewsItemDto.fromJson(_itemJson)];
      final repository = NewsRepositoryImpl(remote);

      final result = await repository.getList();

      expect(result, isA<Success<List<dynamic>>>());
      final items = (result as Success).data as List;
      expect(items, hasLength(1));
    });

    test('maps a DioException to a Failure instead of throwing', () async {
      final remote = _FakeNewsRemoteDataSource()
        ..listError = DioException(
          requestOptions: RequestOptions(path: '/api/news'),
        );
      final repository = NewsRepositoryImpl(remote);

      final result = await repository.getList();

      expect(result, isA<Error<dynamic>>());
    });

    test('maps any other exception to UnexpectedFailure', () async {
      final remote = _FakeNewsRemoteDataSource()..listError = Exception('boom');
      final repository = NewsRepositoryImpl(remote);

      final result = await repository.getList();

      expect(result, isA<Error<dynamic>>());
    });
  });

  group('NewsRepositoryImpl.getArticle', () {
    test(
      'returns Success(null) when the backend could not extract the article',
      () async {
        final remote = _FakeNewsRemoteDataSource()..articleResult = null;
        final repository = NewsRepositoryImpl(remote);

        final result = await repository.getArticle('n-1');

        expect(result, isA<Success<dynamic>>());
        expect((result as Success).data, isNull);
      },
    );

    test('maps a successful article DTO to the entity', () async {
      final remote = _FakeNewsRemoteDataSource()
        ..articleResult = NewsArticleDto.fromJson(_articleJson);
      final repository = NewsRepositoryImpl(remote);

      final result = await repository.getArticle('n-1');

      expect(result, isA<Success<dynamic>>());
      expect((result as Success).data, isNotNull);
    });
  });
}
