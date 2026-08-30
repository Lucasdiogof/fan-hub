import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Pill compacta de porcentagem da Escalação da Torcida — nunca um círculo
/// grande tampando a camisa. Largura cresce só o necessário pra "6%",
/// "87%" ou "100%"; o espaço que ela reserva já entra na conta do
/// footprint do jogador (ver `LineupLayoutEngine`), então ela nunca
/// desloca o vizinho por conta própria.
class LineupPercentBadge extends StatelessWidget {
  const LineupPercentBadge({required this.percent, super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: colors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: ArenaColors.goiasOutfield,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      ),
    );
  }
}
