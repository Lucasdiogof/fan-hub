import 'package:flutter/material.dart';

/// Textura quase imperceptível — linhas diagonais bem finas e de baixa
/// opacidade, só pra dar uma sutileza de tecido/material a um fundo sólido
/// escuro. 1 a cada 10 linhas é um branco mais forte (um pequeno acento
/// rítmico); as outras 9 continuam bem sutis. Estática (sem animação) e
/// nunca competindo com texto ou produto. Usada nos cards de destaque da
/// Home (`ArenaSpotlightCard`, `StoreEntryCard`) pro mesmo "efeitinho" nos
/// dois.
class DiagonalTexture extends StatelessWidget {
  const DiagonalTexture({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DiagonalTexturePainter());
  }
}

class _DiagonalTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final faintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    const gap = 14.0;
    const accentEvery = 10;
    final diagonal = size.width + size.height;
    var lineIndex = 0;
    for (var offset = -size.height; offset < diagonal; offset += gap) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        lineIndex % accentEvery == 0 ? accentPaint : faintPaint,
      );
      lineIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
