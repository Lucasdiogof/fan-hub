import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:goias_app/features/membership/domain/entities/faq_block.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';

const _faqAssetPath = 'lib/assets/content/membership_faq.json';

/// Fonte única do conteúdo do FAQ — extraído do HTML oficial do Sócio
/// Esmeralda e guardado como dado estruturado, não texto solto. Carrega e
/// faz o parse uma única vez por processo (`_cache`), reaproveitado por
/// qualquer tela que precise do FAQ.
class MembershipFaqDataSource {
  static List<FaqCategory>? _cache;

  Future<List<FaqCategory>> getCategories() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_faqAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final categories = (json['categories'] as List<dynamic>)
        .map((c) => _parseCategory(c as Map<String, dynamic>))
        .toList(growable: false);

    _cache = categories;
    return categories;
  }

  FaqCategory _parseCategory(Map<String, dynamic> json) {
    return FaqCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>).map((i) => _parseItem(i as Map<String, dynamic>)).toList(growable: false),
    );
  }

  FaqItem _parseItem(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: (json['answer'] as List<dynamic>).map((b) => _parseBlock(b as Map<String, dynamic>)).toList(growable: false),
    );
  }

  FaqBlock _parseBlock(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'list' => FaqListBlock(
        (json['items'] as List<dynamic>)
            .map((item) => (item as List<dynamic>).map((s) => _parseSpan(s as Map<String, dynamic>)).toList(growable: false))
            .toList(growable: false),
      ),
      _ => FaqParagraphBlock(
        (json['spans'] as List<dynamic>).map((s) => _parseSpan(s as Map<String, dynamic>)).toList(growable: false),
      ),
    };
  }

  FaqSpan _parseSpan(Map<String, dynamic> json) {
    return FaqSpan(
      text: json['text'] as String,
      bold: json['bold'] as bool? ?? false,
      link: json['link'] as String?,
    );
  }
}
