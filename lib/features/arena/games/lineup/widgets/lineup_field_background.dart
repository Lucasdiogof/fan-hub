import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Campo visto de cima, só as marcações essenciais (linha central, círculo,
/// pequenas áreas) — mesma paleta que o resto da Arena usa pro gramado
/// (`ArenaColors.pitch`/`pitchLine`), sem depender do Flame: aqui é um
/// desenho estático, não uma cena animada.
class LineupFieldBackground extends StatelessWidget {
  const LineupFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FieldPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = ArenaColors.pitch;
    canvas.drawRect(Offset.zero & size, fill);

    // Listras alternadas simulando corte de grama, bem sutis.
    final stripeWidth = size.height / 10;
    final stripe = Paint()
      ..color = ArenaColors.pitchDark.withValues(alpha: 0.5);
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeWidth, size.width, stripeWidth),
        stripe,
      );
    }

    final line = Paint()
      ..color = ArenaColors.pitchLine.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), line);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      line,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.14,
      line,
    );

    final penaltyWidth = size.width * 0.5;
    final penaltyHeight = size.height * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        0,
        penaltyWidth,
        penaltyHeight,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) => false;
}
