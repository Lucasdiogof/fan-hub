import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/presentation/cubit/favorites_cubit.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final available = product.isAvailable;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => context.push('/store/product/${product.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.card),
                        ),
                        child: Opacity(
                          opacity: available ? 1 : 0.45,
                          child: Image.asset(
                            product.thumbnail,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _Badge(product: product),
                    ),
                    Positioned(
                      right: AppSpacing.xs,
                      top: AppSpacing.xs,
                      child: _FavoriteButton(productId: product.id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    StorePriceBlock(product: product, compact: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (label, bg, fg) = switch (product) {
      _ when !product.isAvailable => (
        l10n.storeBadgeSoldOut,
        colors.secondary,
        colors.textSecondary,
      ),
      _ when product.isOnSale => (
        l10n.storeBadgeOnSale,
        colors.gold,
        colors.onPrimary,
      ),
      _ => (null, null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFavorite = context.select(
      (FavoritesCubit cubit) => cubit.state.contains(productId),
    );
    return Semantics(
      button: true,
      toggled: isFavorite,
      label: isFavorite
          ? context.l10n.storeRemoveFavorite
          : context.l10n.storeAddFavorite,
      child: InkWell(
        onTap: () => context.read<FavoritesCubit>().toggle(productId),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: isFavorite ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
