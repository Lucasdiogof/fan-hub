import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/news/data/dto/news_article_dto.dart';
import 'package:goias_app/features/news/domain/entities/news_content_block.dart';

void main() {
  group('NewsArticleDto', () {
    final json = {
      'id': 'cuiaba-e-c-x-goias-e-c',
      'title': 'CUIABÁ E.C x GOIÁS E.C | Guia da Partida',
      'category': 'Profissional',
      'publishedAt': '2026-08-22',
      'imageUrl': 'https://static.goiasec.com.br/upload/noticia/x.jpeg',
      'url': 'https://www.goiasec.com.br/noticias/cuiaba-e-c-x-goias-e-c',
      'content': [
        {'type': 'paragraph', 'text': 'Já está disponível o Press Kit.'},
        {
          'type': 'link',
          'text': 'PRESS KIT CUIABÁ E.C x GOIÁS E.C',
          'url': 'https://static.goiasec.com.br/upload/noticia/x.pdf',
        },
      ],
    };

    test('parses the item fields the same way NewsItemDto does', () {
      final dto = NewsArticleDto.fromJson(json);
      expect(dto.item.id, 'cuiaba-e-c-x-goias-e-c');
      expect(dto.item.category, 'Profissional');
    });

    test('parses paragraph and link blocks in order', () {
      final dto = NewsArticleDto.fromJson(json);
      expect(dto.content, hasLength(2));
      expect(dto.content[0], isA<NewsParagraphBlock>());
      expect(
        (dto.content[0] as NewsParagraphBlock).text,
        'Já está disponível o Press Kit.',
      );
      final link = dto.content[1] as NewsLinkBlock;
      expect(link.text, 'PRESS KIT CUIABÁ E.C x GOIÁS E.C');
      expect(link.url, 'https://static.goiasec.com.br/upload/noticia/x.pdf');
    });

    test(
      'an unrecognized block type falls back to a paragraph rather than throwing',
      () {
        final dto = NewsArticleDto.fromJson({
          ...json,
          'content': [
            {'type': 'something-new', 'text': 'texto qualquer'},
          ],
        });
        expect(dto.content.single, isA<NewsParagraphBlock>());
        expect(
          (dto.content.single as NewsParagraphBlock).text,
          'texto qualquer',
        );
      },
    );

    test(
      'toEntity carries the item fields and the content blocks through unchanged',
      () {
        final entity = NewsArticleDto.fromJson(json).toEntity();
        expect(entity.id, json['id']);
        expect(entity.title, json['title']);
        expect(entity.publishedAt, DateTime(2026, 8, 22));
        expect(entity.content, hasLength(2));
      },
    );
  });
}
