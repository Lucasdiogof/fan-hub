import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GoalComponent extends PositionComponent {
  final Paint _frame = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;

  final Paint _frameShade = Paint()
    ..color = Colors.black.withValues(alpha: 0.18)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;

  final Paint _net = Paint()
    ..color = Colors.white.withValues(alpha: 0.30)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  final Paint _mouth = Paint()..color = Colors.black.withValues(alpha: 0.16);

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _mouth);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    final step = w / 11;
    for (var x = -h; x <= w + h; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), _net);
      canvas.drawLine(Offset(x, 0), Offset(x - h, h), _net);
    }
    canvas.restore();

    canvas.drawLine(Offset(3, h), const Offset(3, 0), _frameShade);
    canvas.drawLine(Offset(w - 3, h), Offset(w - 3, 0), _frameShade);
    canvas.drawLine(Offset(0, h), const Offset(0, 0), _frame);
    canvas.drawLine(Offset(w, h), Offset(w, 0), _frame);
    canvas.drawLine(const Offset(0, 0), Offset(w, 0), _frame);
  }
}
