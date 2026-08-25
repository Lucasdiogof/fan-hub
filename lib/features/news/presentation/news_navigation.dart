import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';

/// Busca a matéria completa antes de navegar (mesmo padrão de
/// `GlobalLoading.run` usado no resto do app). Se o backend não conseguiu
/// extrair o conteúdo — ou a busca falhou por qualquer motivo — cai pro
/// link oficial em vez de mostrar uma tela quebrada.
Future<void> openNewsArticle(BuildContext context, NewsItem item) async {
  final repository = sl<NewsRepository>();
  NewsArticle? article;

  await GlobalLoading.run(context, () async {
    final result = await repository.getArticle(item.id);
    article = switch (result) {
      Success(:final data) => data,
      Error() => null,
    };
  });

  if (!context.mounted) return;

  if (article != null) {
    unawaited(context.push('/news/article', extra: article));
  } else {
    unawaited(openExternalUrl(context, item.url));
  }
}
