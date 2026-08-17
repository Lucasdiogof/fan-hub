import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Cabeçalho das colunas da classificação — mobile mostra só P/J/V/SG, como
/// pedido (nada de dez colunas apertadas).
class StandingsHeader extends StatelessWidget {
  const StandingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: colors.textHint);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('#', style: style)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('CLUBE', style: style)),
          _ColumnLabel('P', style),
          _ColumnLabel('J', style),
          _ColumnLabel('V', style),
          _ColumnLabel('SG', style, width: 32),
        ],
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.label, this.style, {this.width = 24});

  final String label;
  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: Text(label, textAlign: TextAlign.center, style: style));
  }
}
