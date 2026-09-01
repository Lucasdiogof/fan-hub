import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Uma barra de atributo (0–100, mas na prática sempre 45–98, ver
/// `PlayerIdentityEngine.normalizedScore`) — o pedido explícito foi "seis
/// barras elegantes", NUNCA um gráfico de radar (poluído no mobile).
class PlayerIdentityAttributeBar extends StatelessWidget {
  const PlayerIdentityAttributeBar({
    required this.label,
    required this.value,
    this.highlighted = false,
    super.key,
  });

  final String label;
  final int value;

  /// `true` pras dimensões em "Suas marcas" — barra em destaque.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final barColor = highlighted ? colors.primary : colors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: barColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
