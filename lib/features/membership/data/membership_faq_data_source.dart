import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:goias_app/features/membership/domain/entities/faq_block.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _faqAssetPath = 'lib/assets/content/membership_faq.json';

/// Fonte do conteúdo do FAQ. Supabase é a fonte da verdade (editável sem
/// republicar o app); o asset local (extraído do HTML oficial do Sócio
/// Esmeralda) é o fallback offline / tabela vazia. Carrega e faz o parse
/// uma única vez por processo (`_cache`), reaproveitado por qualquer tela
/// que precise do FAQ.
class MembershipFaqDataSource {
  MembershipFaqDataSource(this._client);

  final SupabaseClient _client;

  static List<FaqCategory>? _cache;

  Future<List<FaqCategory>> getCategories() async {
    final cached = _cache;
    if (cached != null) return cached;

    final categories = await _loadFromSupabase() ?? await _loadFromAsset();
    _cache = categories;
    return categories;
  }

  Future<List<FaqCategory>?> _loadFromSupabase() async {
    try {
      final categoryRows = await _client
          .from('membership_faq_categories')
          .select('id, title')
          .eq('is_active', true)
          .order('sort_order');
      if (categoryRows.isEmpty) return null;

      final itemRows = await _client
          .from('membership_faq_items')
          .select('id, category_id, question, answer')
          .eq('is_active', true)
          .order('sort_order');

      final categories = <FaqCategory>[];
      for (final categoryRow in categoryRows) {
        final categoryId = categoryRow['id'] as String;
        final items = <FaqItem>[];
        for (final itemRow in itemRows) {
          if (itemRow['category_id'] != categoryId) continue;
          final item = _mapItem(itemRow);
          if (item != null) items.add(item);
        }
        if (items.isEmpty) continue;
        categories.add(
          FaqCategory(
            id: categoryId,
            title: categoryRow['title'] as String,
            items: items,
          ),
        );
      }
      return categories.isEmpty ? null : categories;
    } catch (_) {
      return null;
    }
  }

  FaqItem? _mapItem(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final question = row['question'] as String?;
    final answerRaw = row['answer'] as List?;
    if (id == null || question == null || answerRaw == null) return null;
    try {
      final answer = answerRaw
          .map((b) => _parseBlock(b as Map<String, dynamic>))
          .toList(growable: false);
      return FaqItem(id: id, question: question, answer: answer);
    } catch (_) {
      return null;
    }
  }

  Future<List<FaqCategory>> _loadFromAsset() async {
    final raw = await rootBundle.loadString(_faqAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['categories'] as List<dynamic>)
        .map((c) => _parseCategory(c as Map<String, dynamic>))
        .toList(growable: false);
  }

  FaqCategory _parseCategory(Map<String, dynamic> json) {
    return FaqCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => _parseItem(i as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  FaqItem _parseItem(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: (json['answer'] as List<dynamic>)
          .map((b) => _parseBlock(b as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  FaqBlock _parseBlock(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'list' => FaqListBlock(
        (json['items'] as List<dynamic>)
            .map(
              (item) => (item as List<dynamic>)
                  .map((s) => _parseSpan(s as Map<String, dynamic>))
                  .toList(growable: false),
            )
            .toList(growable: false),
      ),
      _ => FaqParagraphBlock(
        (json['spans'] as List<dynamic>)
            .map((s) => _parseSpan(s as Map<String, dynamic>))
            .toList(growable: false),
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
