import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NewsCategory { futebol, clube, base, feminino }

extension NewsCategoryLabel on NewsCategory {
  String get label => switch (this) {
    NewsCategory.futebol => 'Futebol',
    NewsCategory.clube => 'Clube',
    NewsCategory.base => 'Base',
    NewsCategory.feminino => 'Feminino',
  };
}

class NewsArticle extends Equatable {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.body,
    required this.publishedAt,
    required this.coverColor,
  });

  final String id;
  final String title;
  final NewsCategory category;
  final String summary;
  final String body;
  final DateTime publishedAt;
  final Color coverColor;

  @override
  List<Object?> get props => [id, title, category, summary, body, publishedAt, coverColor];
}
