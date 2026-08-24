import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Texto que sobe alguns pixels e some — o feedback de acerto/perfect
/// dentro do próprio jogo, perto da bola. Se autodestrói ao fim.
class KeepyUppyFeedback extends PositionComponent {
  KeepyUppyFeedback({
    required Vector2 position,
    required this.title,
    this.subtitle,
    required this.color,
    required this.big,
  }) : super(position: position, anchor: Anchor.center);

  final String title;
  final String? subtitle;
  final Color color;
  final bool big;

  static const _life = 0.7;
  double _t = 0;
  late TextPainter _titlePainter;
  TextPainter? _subPainter;

  @override
  Future<void> onLoad() async {
    _titlePainter = _paint(title, big ? 26 : 20, color);
    final sub = subtitle;
    if (sub != null) _subPainter = _paint(sub, big ? 20 : 16, color);
  }

  TextPainter _paint(String text, double size, Color c) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: c,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void update(double dt) {
    _t += dt;
    position.y -= dt * 46;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_t / _life).clamp(0.0, 1.0);
    final opacity = progress < 0.25 ? 1.0 : (1 - (progress - 0.25) / 0.75);
    canvas.saveLayer(
      null,
      Paint()..colorFilter = ColorFilter.mode(Color.fromRGBO(255, 255, 255, opacity), BlendMode.modulate),
    );
    var y = 0.0;
    _titlePainter.paint(canvas, Offset(-_titlePainter.width / 2, y));
    y += _titlePainter.height + 1;
    _subPainter?.paint(canvas, Offset(-_subPainter!.width / 2, y));
    canvas.restore();
  }
}
