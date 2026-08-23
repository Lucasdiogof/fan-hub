import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Alignment, RadialGradient;

/// Bola clássica branca e preta, desenhada 100% em Canvas — pequena e
/// proporcional ao jogador. O raio é fixo por instância, então toda a
/// geometria (gradiente, painéis, sombra) é pré-computada uma única vez no
/// construtor — `render` só desenha, sem alocar Path/Paint por frame.
///
/// Segunda passada de acabamento sobre a versão anterior: gradiente com
/// mais paradas (realce na luz, sombra própria do lado oposto — não só um
/// clareado uniforme), painéis com tamanho/distribuição mais parecidos com
/// os de uma bola de verdade (não quatro pentágonos soltos do mesmo
/// tamanho), aro externo mais definido e sombra no chão com blur (mais
/// suave, "assentada", igual à do jogador/goleiro) em vez de uma elipse de
/// borda dura.
class BallComponent extends PositionComponent {
  BallComponent({double radius = 11}) : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    _build();
  }

  double get radius => size.x / 2;

  late final Paint _shadow;
  late final Paint _base;
  late final Paint _rimPaint;
  late final Paint _innerShadePaint;
  final Paint _panelPaint = Paint()..color = const Color(0xFF1C2024);
  final List<Path> _panels = [];
  double _rimWidth = 1;

  void _build() {
    final r = radius;
    final c = Offset(r, r);

    // Esfera: realce na luz (canto superior-esquerdo), meio-tom, e uma
    // sombra própria mais escura do lado oposto — não um clareado plano.
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

    // Sombreamento extra concentrado no quadrante oposto à luz, por cima
    // do gradiente base — reforça a curvatura sem precisar de mais paradas
    // no shader principal (que já fica sutil demais se for muito longo).
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

    // Cinco painéis centrais bem distribuídos (padrão clássico de bola,
    // não quatro formas soltas de tamanho arbitrário) + dois parciais nas
    // bordas pra sugerir a curvatura continuando além do que se vê de
    // frente.
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

  /// Um pentágono simples por "painel" — não tenta replicar a tesselação
  /// real da bola, só sugerir a textura clássica preto-e-branco à
  /// distância de um celular.
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
      Rect.fromCenter(center: Offset(radius, d * 0.96), width: d * 0.72, height: d * 0.2),
      _shadow,
    );

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
  }
}
