import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_content_block.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/utils/image_proxy.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class NewsArticlePage extends StatelessWidget {
  const NewsArticlePage({required this.article, super.key});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoverImage(imageUrl: article.imageUrl),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.category.isNotEmpty)
                        _CategoryBadge(category: article.category),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      if (article.publishedAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 13,
                              color: colors.textHint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              fullDateLabel(article.publishedAt!),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      for (final block in article.content)
                        _ContentBlockView(block: block),
                      const SizedBox(height: AppSpacing.lg),
                      _SourceFooter(url: article.url),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        AspectRatio(
          // Mesmo raciocínio do card da lista (`news_item_row.dart`): um
          // pouco mais largo que a proporção real da imagem (~425×480) pra
          // cortar uma fatia da faixa vazia do topo, sem chegar nos
          // escudos perto do rodapé (`Alignment.bottomCenter` garante que o
          // corte nunca vem de baixo).
          aspectRatio: 1.08,
          child: ColoredBox(
            color: colors.secondary,
            child: imageUrl.isEmpty
                ? null
                : Image.network(
                    proxiedImageUrl(imageUrl),
                    fit: BoxFit.cover,
                    // Mesmo motivo do card da lista: texto e escudos ficam
                    // perto do rodapé da arte, não do topo.
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          top: AppSpacing.md,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: () => context.canPop() ? context.pop() : context.go('/'),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ContentBlockView extends StatelessWidget {
  const _ContentBlockView({required this.block});

  final NewsContentBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: switch (block) {
        NewsParagraphBlock(:final text) => Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: colors.textPrimary,
            height: 1.6,
          ),
        ),
        NewsLinkBlock(:final text, :final url) => InkWell(
          onTap: () => openExternalUrl(context, url),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      },
    );
  }
}

class _SourceFooter extends StatelessWidget {
  const _SourceFooter({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.newsSourceLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => openExternalUrl(context, url),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.newsOpenOriginal,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
