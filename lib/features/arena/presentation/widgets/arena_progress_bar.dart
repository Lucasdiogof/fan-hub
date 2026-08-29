import 'package:flutter/material.dart';

/// Barra de progresso fina compartilhada pela Arena — mesmo traço em
/// `ArenaChallengeCard` (grade de desafios) e `ContinuePlayingCard`, pra
/// nunca ter duas barras com espessura/raio diferentes na mesma tela.
class ArenaProgressBar extends StatelessWidget {
  const ArenaProgressBar({
    required this.fraction,
    required this.trackColor,
    required this.fillColor,
    this.minHeight = 4,
    super.key,
  });

  final double fraction;
  final Color trackColor;
  final Color fillColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: minHeight,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation(fillColor),
      ),
    );
  }
}
