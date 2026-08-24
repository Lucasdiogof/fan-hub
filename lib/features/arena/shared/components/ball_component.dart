import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Alignment, RadialGradient;
import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/arena/shared/arena_assets.dart';

/// Bola de futebol clássica. Usa o asset [ArenaAssets.ball] (PNG quadrado,
/// fundo transparente, bola de borda a borda) quando disponível; enquanto
/// o arquivo não existir cai no desenho procedural em Canvas, sem erro.
///
/// A sombra no chão é sempre feita por código e desenhada ANTES de aplicar
/// a rotação — ela não gira nem se deforma junto com a bola. O giro do
/// chute ([spin]) é aplicado só na imagem, em torno do centro, então a bola
/// gira sem distorção. A escala de perspectiva (`scale`, definida pelo jogo
/// conforme a bola se afasta) continua encolhendo bola e sombra juntas.
class BallComponent extends PositionComponent {
  BallComponent({double radius = 11}) : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    _build();
  }

  double get radius => size.x / 2;

  /// Giro atual da bola, em radianos — aplicado só ao sprite/desenho da
  /// bola, nunca à sombra.
  double spin = 0;

  /// Sombra própria no chão logo abaixo da bola. Desligada em jogos que
  /// gerenciam a sombra separadamente (ex.: embaixadinhas, onde a sombra
  /// fica fixa no gramado e encolhe conforme a bola sobe).
  bool groundShadow = true;

  Image? _sprite;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high;

  @override
  Future<void> onLoad() async {
    try {
      final data = await rootBundle.load(ArenaAssets.ball);
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _sprite = frame.image;
    } catch (_) {
      _sprite = null;
    }
  }

  // --- Sombra (sempre por código) ----------------------------------------
  late final Paint _shadow;

  // --- Fallback procedural -----------------------------------------------
  late final Paint _base;
  late final Paint _rimPaint;
  late final Paint _innerShadePaint;
  final Paint _panelPaint = Paint()..color = const Color(0xFF1C2024);
  final List<Path> _panels = [];
  double _rimWidth = 1;

  void _build() {
    final r = radius;
    final c = Offset(r, r);

    _base = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.38, -0.44),
        radius: 1.15,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF6F7F6),
          Color(0xFFDEE1DF),
          Color(0xFFB7BCB9),
        ],
        stops: [0.0, 0.42, 0.78, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    _innerShadePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.5, 0.55),
        radius: 0.9,
        colors: [Color(0x00000000), Color(0x1F0A0A08)],
        stops: [0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    _rimWidth = max(0.8, r * 0.075);
    _rimPaint = Paint()
      ..color = const Color(0x3A121212)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _rimWidth;

    _panels
      ..clear()
      ..addAll([
        _pentagon(Offset(r * 1.0, r * 0.86), r * 0.30),
        for (var i = 0; i < 5; i++)
          _pentagon(
            Offset(r * 1.0 + cos(i * pi * 2 / 5 - pi / 2) * r * 0.62, r * 0.86 + sin(i * pi * 2 / 5 - pi / 2) * r * 0.62),
            r * 0.20,
            rotation: pi + i * pi * 2 / 5,
          ),
      ]);

    _shadow = Paint()
      ..color = const Color(0x4D0E0A06)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(0.6, r * 0.14));
  }

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

    // Sombra no chão — por código, desenhada fora da rotação: fica assentada
    // no gramado enquanto a bola gira por cima.
    if (groundShadow) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(radius, d * 0.96), width: d * 0.72, height: d * 0.2),
        _shadow,
      );
    }

    canvas.save();
    if (spin != 0) {
      canvas
        ..translate(radius, radius)
        ..rotate(spin)
        ..translate(-radius, -radius);
    }

    final sprite = _sprite;
    if (sprite != null) {
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromLTWH(0, 0, d, d),
        _spritePaint,
      );
      canvas.restore();
      return;
    }

    final c = Offset(radius, radius);
    final circle = Rect.fromCircle(center: c, radius: radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawCircle(c, radius, _base);
    for (final panel in _panels) {
      canvas.drawPath(panel, _panelPaint);
    }
    canvas.drawRect(circle, _innerShadePaint);
    canvas.restore();
    canvas.drawCircle(c, radius - _rimWidth / 2, _rimPaint);

    canvas.restore();
  }
}
