import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Fundo do jogo — estádio escuro no topo que desce pra um gramado mais
/// claro embaixo, onde o jogador fica. Puro visual, redesenhado quando o
/// jogo muda de tamanho; nada de posição de gameplay depende dele.
class KeepyUppyField extends PositionComponent {
  KeepyUppyField() : super(anchor: Anchor.topLeft);

  static const _top = Color(0xFF0B3320);
  static const _mid = Color(0xFF124A2C);
  static const _grassTop = Color(0xFF1C6338);
  static const _grassBottom = Color(0xFF238045);

  final Paint _skyPaint = Paint();
  final Paint _grassPaint = Paint();
  late Paint _stripePaint;
  double _grassLineY = 0;

  void _rebuild() {
    final w = size.x;
    final h = size.y;
    _grassLineY = h * 0.5;

    _skyPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_top, _mid],
    ).createShader(Rect.fromLTWH(0, 0, w, _grassLineY));

    _grassPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_grassTop, _grassBottom],
    ).createShader(Rect.fromLTWH(0, _grassLineY, w, h - _grassLineY));

    _stripePaint = Paint()..color = const Color(0x12FFFFFF);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    if (size.x > 0 && size.y > 0) _rebuild();
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    if (_grassLineY == 0) _rebuild();

    canvas.drawRect(Rect.fromLTWH(0, 0, w, _grassLineY), _skyPaint);
    canvas.drawRect(Rect.fromLTWH(0, _grassLineY, w, h - _grassLineY), _grassPaint);

    // Faixas do gramado, cada vez mais largas conforme se aproximam da
    // câmera — dá profundidade sem precisar de textura.
    var y = _grassLineY;
    var band = (h - _grassLineY) * 0.10;
    var alt = false;
    while (y < h) {
      if (alt) canvas.drawRect(Rect.fromLTWH(0, y, w, band), _stripePaint);
      y += band;
      band *= 1.18;
      alt = !alt;
    }
  }
}
