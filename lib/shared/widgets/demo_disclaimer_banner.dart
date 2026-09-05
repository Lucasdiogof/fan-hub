import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Aviso "isto é demonstração" pra momentos transacionais (antes de
/// confirmar compra/adesão) — mesmo visual em Loja/Ingressos/Sócio, nunca
/// um `Container` reinventado em cada tela. Título em negrito + corpo,
/// nunca um modal: fica visível na própria tela, no momento da decisão.
class DemoDisclaimerBanner extends StatelessWidget {
  const DemoDisclaimerBanner({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
