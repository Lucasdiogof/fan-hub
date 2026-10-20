import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/membership/domain/entities/faq_block.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';
import 'package:goias_app/features/membership/domain/faq_search.dart';

FaqItem _item(String id, String q, String a) => FaqItem(
  id: id,
  question: q,
  answer: [
    FaqParagraphBlock([FaqSpan(text: a)]),
  ],
);

final _categories = [
  FaqCategory(
    id: 'planos',
    title: 'Planos',
    items: [
      _item('1', 'Como troco de plano?', 'Pelo app, em Meu plano.'),
      _item('2', 'Qual o valor da mensalidade?', 'Depende do plano escolhido.'),
    ],
  ),
  FaqCategory(
    id: 'ingressos',
    title: 'Ingressos',
    items: [
      _item('3', 'Posso transferir meu ingresso?', 'Sim, até 2 horas antes.'),
    ],
  ),
];

void main() {
  group('flattenFaqAnswer', () {
    test('junta parágrafos e listas, na ordem, separando os trechos', () {
      final text = flattenFaqAnswer(const [
        FaqParagraphBlock([
          FaqSpan(text: 'Um'),
          FaqSpan(text: 'dois', bold: true),
        ]),
        FaqListBlock([
          [FaqSpan(text: 'três')],
          [FaqSpan(text: 'quatro')],
        ]),
      ]);
      expect(text, 'Um dois três quatro ');
    });

    test('resposta sem blocos vira texto vazio', () {
      expect(flattenFaqAnswer(const []), '');
    });
  });

  group('filterFaqCategories', () {
    test('sem filtro nem busca devolve tudo', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: '',
      );
      expect(r.map((c) => c.id), ['planos', 'ingressos']);
      expect(r.first.items, hasLength(2));
    });

    test('só espaços na busca conta como busca vazia', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: '   ',
      );
      expect(r, hasLength(2));
    });

    test('filtra pela categoria escolhida', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: 'ingressos',
        query: '',
      );
      expect(r.map((c) => c.id), ['ingressos']);
    });

    test('busca ignora maiúsculas e acentos', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: 'TRANSFERIR INGRESSO',
      );
      expect(r.single.items.single.id, '3');
    });

    test('acha a palavra tanto na pergunta quanto na resposta', () {
      final naResposta = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: 'horas',
      );
      expect(naResposta.single.items.single.id, '3');
    });

    test('várias palavras precisam estar todas presentes', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: 'plano mensalidade',
      );
      expect(r.single.items.map((i) => i.id), ['2']);
    });

    test('hífen não atrapalha: "check-in" e "checkin" acham a mesma coisa', () {
      final cats = [
        FaqCategory(
          id: 'c',
          title: 'C',
          items: [_item('9', 'Como faço o check-in?', 'Pelo QR Code.')],
        ),
      ];
      for (final q in ['checkin', 'check-in', 'CHECK-IN']) {
        final r = filterFaqCategories(
          categories: cats,
          selectedCategoryId: null,
          query: q,
        );
        expect(r.single.items.single.id, '9', reason: q);
      }
    });

    test('categorias que ficam sem perguntas somem do resultado', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: 'mensalidade',
      );
      expect(r.map((c) => c.id), ['planos']);
    });

    test('nada encontrado devolve lista vazia, sem mexer na original', () {
      final r = filterFaqCategories(
        categories: _categories,
        selectedCategoryId: null,
        query: 'xyzinexistente',
      );
      expect(r, isEmpty);
      expect(_categories.first.items, hasLength(2));
    });
  });
}
