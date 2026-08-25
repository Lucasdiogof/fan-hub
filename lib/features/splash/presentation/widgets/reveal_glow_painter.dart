import 'package:flutter/rendering.dart';

/// Brilho sutil na borda do círculo durante o reveal — desenhado como um
/// stroke com blur, não como uma borda sólida. `opacity` (0–1) some o glow
/// nos últimos instantes da animação, antes do vídeo tomar a tela inteira.
class RevealGlowPainter extends CustomPainter {
  const RevealGlowPainter({
    required this.center,
    required this.radius,
    required this.opacity,
  });

  final Offset center;
  final double radius;
  final double opacity;

  static const _white = Color(0xFFFFFFFF);
  static const _greenTint = Color(0xFF29A85C);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final outerGlow = Paint()
      ..color = _greenTint.withValues(alpha: 0.35 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, outerGlow);

    final innerRim = Paint()
      ..color = _white.withValues(alpha: 0.55 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(center, radius, innerRim);
  }

  @override
  bool shouldRepaint(RevealGlowPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.radius != radius ||
      oldDelegate.opacity != opacity;
}
