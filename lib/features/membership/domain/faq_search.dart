import 'package:goias_app/features/membership/domain/entities/faq_block.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';

const _diacriticsMap = {
  'á': 'a',
  'à': 'a',
  'ã': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'ô': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

String _normalize(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacriticsMap[char] ?? char);
  }
  return buffer.toString().replaceAll('-', '');
}

String flattenFaqAnswer(List<FaqBlock> blocks) {
  final buffer = StringBuffer();
  for (final block in blocks) {
    switch (block) {
      case FaqParagraphBlock(:final spans):
        for (final span in spans) {
          buffer.write(span.text);
          buffer.write(' ');
        }
      case FaqListBlock(:final items):
        for (final spans in items) {
          for (final span in spans) {
            buffer.write(span.text);
            buffer.write(' ');
          }
        }
    }
  }
  return buffer.toString();
}

bool _matchesQuery(FaqItem item, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return true;
  final haystack = _normalize(
    '${item.question} ${flattenFaqAnswer(item.answer)}',
  );
  final words = trimmed
      .split(RegExp(r'\s+'))
      .map(_normalize)
      .where((w) => w.isNotEmpty);
  return words.every(haystack.contains);
}

/// Aplica filtro de categoria + busca sem tocar na lista original — chamado
/// direto no build, é barato o bastante pras 33 perguntas do FAQ.
List<FaqCategory> filterFaqCategories({
  required List<FaqCategory> categories,
  required String? selectedCategoryId,
  required String query,
}) {
  return categories
      .where((c) => selectedCategoryId == null || c.id == selectedCategoryId)
      .map(
        (c) => FaqCategory(
          id: c.id,
          title: c.title,
          items: c.items.where((i) => _matchesQuery(i, query)).toList(),
        ),
      )
      .where((c) => c.items.isNotEmpty)
      .toList();
}
