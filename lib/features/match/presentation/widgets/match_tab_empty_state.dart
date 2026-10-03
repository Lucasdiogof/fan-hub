import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Estado vazio compacto das abas da tela de detalhes (sem eventos, sem
/// estatísticas, sem escalação) — uma linha de texto discreta, nunca um card
/// gigante vazio.
class MatchTabEmptyState extends StatelessWidget {
  const MatchTabEmptyState({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: colors.textHint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
