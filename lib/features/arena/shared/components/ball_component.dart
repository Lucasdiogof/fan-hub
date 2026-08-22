import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Alignment, RadialGradient;

/// Bola clássica branca e preta, desenhada 100% em Canvas — pequena e
/// proporcional ao jogador, não mais um recorte de foto (a foto real, numa
/// tela pequena de celular, ficava grande demais e chamava atenção como se
/// fosse um botão de UI). O raio é fixo por instância, então toda a
/// geometria (gradiente, painéis, sombra) é pré-computada uma única vez no
/// construtor — `render` só desenha, sem alocar Path/Paint por frame.
class BallComponent extends PositionComponent {
  BallComponent({double radius = 11}) : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    _build();
  }

  double get radius => size.x / 2;

  final Paint _shadow = Paint()..color = const Color(0x40140b06);
  late final Paint _base;
  late final Paint _rimPaint;
  final Paint _panelPaint = Paint()..color = const Color(0xFF20242A);
  final List<Path> _panels = [];
  double _rimWidth = 1;

  void _build() {
    final r = radius;
    final c = Offset(r, r);
    _base = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.42),
        radius: 1.05,
        colors: [Color(0xFFFFFFFF), Color(0xFFECEEED), Color(0xFFCBCFCC)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    _rimWidth = max(0.7, r * 0.07);
    _rimPaint = Paint()
      ..color = const Color(0x2E141414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _rimWidth;

    _panels
      ..clear()
      ..addAll([
        _pentagon(Offset(r * 0.92, r * 0.9), r * 0.36),
        _pentagon(Offset(r * 1.58, r * 0.58), r * 0.22, rotation: 0.55),
        _pentagon(Offset(r * 0.55, r * 1.6), r * 0.20, rotation: -0.4),
        _pentagon(Offset(r * 1.5, r * 1.5), r * 0.18, rotation: 1.1),
      ]);
  }

  /// Um pentágono simples por "painel" — não tenta replicar a tesselação
  /// real da bola (o pedido explícito era não perseguir isso), só sugerir a
  /// textura clássica preto-e-branco à distância de um celular.
  Path _pentagon(Offset center, double size, {double rotation = 0}) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = rotation + (pi * 2 / 5) * i - pi / 2;
      final p = Offset(center.dx + cos(a) * size, center.dy + sin(a) * size);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void render(Canvas canvas) {
    final d = radius * 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(radius, d * 0.95), width: d * 0.78, height: d * 0.24),
      _shadow,
    );

    final c = Offset(radius, radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: radius)));
    canvas.drawCircle(c, radius, _base);
    for (final panel in _panels) {
      canvas.drawPath(panel, _panelPaint);
    }
    canvas.restore();
    canvas.drawCircle(c, radius - _rimWidth / 2, _rimPaint);
  }
}
