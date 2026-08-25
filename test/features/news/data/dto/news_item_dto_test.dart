import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/news/data/dto/news_item_dto.dart';

void main() {
  group('NewsItemDto', () {
    final json = {
      'id': 'goias-lanca-nova-colecao-diadora-2026',
      'title': 'GOIÁS LANÇA NOVA COLEÇÃO DIADORA 2026',
      'category': 'Marketing',
      'publishedAt': '2026-08-18',
      'imageUrl': 'https://static.goiasec.com.br/upload/noticia/x.png',
      'url':
          'https://www.goiasec.com.br/noticias/goias-lanca-nova-colecao-diadora-2026',
    };

    test('parses from json correctly', () {
      final dto = NewsItemDto.fromJson(json);
      expect(dto.id, 'goias-lanca-nova-colecao-diadora-2026');
      expect(dto.title, 'GOIÁS LANÇA NOVA COLEÇÃO DIADORA 2026');
      expect(dto.category, 'Marketing');
      expect(dto.publishedAt, '2026-08-18');
    });

    test('toEntity parses a non-empty publishedAt into a DateTime', () {
      final entity = NewsItemDto.fromJson(json).toEntity();
      expect(entity.publishedAt, DateTime(2026, 8, 18));
    });

    test(
      'toEntity treats an empty publishedAt as null instead of a parse error',
      () {
        final dto = NewsItemDto.fromJson({...json, 'publishedAt': ''});
        expect(dto.toEntity().publishedAt, isNull);
      },
    );

    test('toEntity treats an unparseable publishedAt as null, not a crash', () {
      final dto = NewsItemDto.fromJson({
        ...json,
        'publishedAt': 'não é uma data',
      });
      expect(dto.toEntity().publishedAt, isNull);
    });

    test('all entity fields carry through unchanged', () {
      final entity = NewsItemDto.fromJson(json).toEntity();
      expect(entity.id, json['id']);
      expect(entity.title, json['title']);
      expect(entity.category, json['category']);
      expect(entity.imageUrl, json['imageUrl']);
      expect(entity.url, json['url']);
    });
  });
}
