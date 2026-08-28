import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';

String formatBrl(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final fromEnd = intPart.length - i;
    buffer.write(intPart[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return 'R\$ ${buffer.toString()},${parts[1]}';
}

/// Preço atual + "de" riscado + desconto + parcelamento — mesma composição
/// no card da listagem e no detalhe do produto, só o tamanho de fonte
/// muda. Nunca vermelho: desconto usa `colors.gold` (regra do design
/// system, ver `AppColors`).
class StorePriceBlock extends StatelessWidget {
  const StorePriceBlock({
    required this.product,
    this.compact = false,
    super.key,
  });

  final StoreProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priceSize = compact ? 15.0 : 24.0;
    final installmentValue = product.maxInstallments > 1
        ? product.price / product.maxInstallments
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.isOnSale)
          Row(
            children: [
              Text(
                formatBrl(product.originalPrice!),
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  color: colors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${product.discountPercentage}%',
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w800,
                    color: colors.gold,
                  ),
                ),
              ),
            ],
          ),
        Text(
          formatBrl(product.price),
          style: TextStyle(
            fontSize: priceSize,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        if (installmentValue != null)
          Text(
            context.l10n.storeInstallmentsLabel(
              product.maxInstallments,
              formatBrl(installmentValue),
            ),
            style: TextStyle(
              fontSize: compact ? 10.5 : 12,
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}
