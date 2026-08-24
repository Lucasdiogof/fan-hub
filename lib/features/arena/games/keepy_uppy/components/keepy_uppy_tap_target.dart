import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// O alvo "TOQUE AQUI" sob os pés do jogador — círculos concêntricos
/// achatados (perspectiva do gramado), um pulso contínuo e um destaque
/// sutil quando a bola entra na janela de toque. É desenhado no mundo do
/// jogo, nunca um botão de UI.
class KeepyUppyTapTarget extends PositionComponent {
  KeepyUppyTapTarget() : super(anchor: Anchor.center);

  double radius = 70;
  bool active = false;

  double _pulse = 0;
  double _activeGlow = 0;

  static const _green = Color(0xFF3DDC84);
  late final TextPainter _label = TextPainter(
    text: const TextSpan(
      text: 'TOQUE AQUI',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void update(double dt) {
    _pulse = (_pulse + dt * 0.85) % 1;
    final target = active ? 1.0 : 0.0;
    _activeGlow += (target - _activeGlow) * min(1, dt * 10);
  }

  @override
  void render(Canvas canvas) {
    final rx = radius * (1 + 0.06 * _activeGlow);
    final ry = rx * 0.4;

    // Mancha verde preenchida no centro.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 1.05, height: ry * 1.05),
      Paint()..color = _green.withValues(alpha: 0.12 + 0.14 * _activeGlow),
    );

    // Anel interno sólido.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 1.1, height: ry * 1.1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _green.withValues(alpha: 0.55 + 0.35 * _activeGlow),
    );

    // Anel externo tracejado.
    _drawDashedOval(canvas, rx * 1.6, ry * 1.6,
        Colors.white.withValues(alpha: 0.5 + 0.3 * _activeGlow));

    // Pulso que se expande e some.
    final p = _pulse;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: rx * (1.1 + p * 0.9),
        height: ry * (1.1 + p * 0.9),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _green.withValues(alpha: (1 - p) * 0.4),
    );

    _label.paint(canvas, Offset(-_label.width / 2, ry * 1.6 + 8));
  }

  void _drawDashedOval(Canvas canvas, double width, double height, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    const segments = 40;
    for (var i = 0; i < segments; i++) {
      if (i.isOdd) continue;
      final start = (i / segments) * 2 * pi;
      const sweep = (1 / segments) * 2 * pi;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }
}
