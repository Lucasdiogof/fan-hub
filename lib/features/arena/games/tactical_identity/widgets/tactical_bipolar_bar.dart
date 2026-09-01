import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Barra bipolar — os dois lados de UM eixo só, nunca duas progress bars
/// independentes (ver spec: "isso representa melhor o fato de serem dois
/// lados do MESMO eixo"). [rightPercent] decide a posição do marcador
/// (0 = extremo esquerdo, 100 = extremo direito); `leftPercent` é sempre
/// `100 - rightPercent`, só recebido separado pra não recalcular na tela.
class TacticalBipolarBar extends StatelessWidget {
  const TacticalBipolarBar({
    required this.leftLabel,
    required this.leftPercent,
    required this.rightLabel,
    required this.rightPercent,
    super.key,
  });

  final String leftLabel;
  final int leftPercent;
  final String rightLabel;
  final int rightPercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fraction = (rightPercent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$leftLabel $leftPercent%',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '$rightLabel $rightPercent%',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const markerSize = 16.0;
            final trackWidth = constraints.maxWidth;
            final markerLeft = (fraction * trackWidth - markerSize / 2).clamp(
              0.0,
              trackWidth - markerSize,
            );
            return SizedBox(
              height: markerSize,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Marca central (0/0 do eixo) — referência visual de
                  // "meio do caminho" entre os dois extremos.
                  Positioned(
                    left: trackWidth / 2 - 1,
                    child: Container(width: 2, height: 8, color: colors.border),
                  ),
                  Positioned(
                    left: markerLeft,
                    child: Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
