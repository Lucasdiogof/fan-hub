import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Camisa de uniforme estilizada — mesmo desenho usado no jogo "Adivinhe a
/// Escalação" e na "Escalação da Torcida", pra manter uma única linguagem
/// visual de "jogador no campo" no app inteiro. [fillColor]/[numberColor]/
/// [trimColor] separados (em vez de fixos) permitem tanto o uniforme
/// principal (verde, número branco) quanto o reserva (branco, detalhes
/// verdes) sem duplicar o desenho da camisa em si.
class JerseyShirt extends StatelessWidget {
  const JerseyShirt({
    required this.size,
    this.number,
    this.fillColor = const Color(0xFF00521E),
    this.numberColor = Colors.white,
    this.trimColor = Colors.white,
    super.key,
  });

  final double size;
  final int? number;
  final Color fillColor;
  final Color numberColor;
  final Color trimColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _JerseyPainter(
          fillColor: fillColor,
          numberColor: numberColor,
          trimColor: trimColor,
          number: number,
        ),
      ),
    );
  }
}

/// Silhueta de camisa com corte de ombro/manga em curva, decote em V e
/// barra levemente arredondada — desenhada pra ler como "camisa de futebol
/// de verdade" mesmo pequena (várias juntas no campo). Preenchimento em
/// gradiente (mais claro no ombro, mais escuro na base) simula a
/// curvatura do tecido; um "brilho" translúcido no ombro e uma sombra
/// projetada dão profundidade sem pesar o desenho.
class _JerseyPainter extends CustomPainter {
  const _JerseyPainter({
    required this.fillColor,
    required this.numberColor,
    required this.trimColor,
    required this.number,
  });

  final Color fillColor;
  final Color numberColor;
  final Color trimColor;
  final int? number;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = _jerseyPath(w, h);

    canvas.drawShadow(body, Colors.black, 3, false);

    final lighter = _shade(fillColor, 0.18);
    final darker = _shade(fillColor, -0.20);
    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0),
        Offset(w * 0.5, h),
        [lighter, fillColor, darker],
        const [0.0, 0.42, 1.0],
      );
    canvas.drawPath(body, fill);

    // Contorno discreto, mais escuro que o preenchimento (não preto puro).
    canvas.drawPath(
      body,
      Paint()
        ..color = _shade(fillColor, -0.34).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Brilho sutil no topo dos ombros, simulando luz vinda de cima.
    canvas.save();
    canvas.clipPath(body);
    final sheen = Path()
      ..moveTo(w * 0.26, h * 0.02)
      ..quadraticBezierTo(w * 0.5, -h * 0.06, w * 0.74, h * 0.02)
      ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.26, h * 0.02)
      ..close();
    canvas.drawPath(
      sheen,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.restore();

    // Debrum no decote — pequeno detalhe de acabamento, cor do uniforme
    // (branco no principal, verde no reserva).
    final collar = Path()
      ..moveTo(w * 0.40, 0)
      ..quadraticBezierTo(w * 0.5, h * 0.10, w * 0.60, 0);
    canvas.drawPath(
      collar,
      Paint()
        ..color = trimColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    if (number == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: numberColor,
          fontSize: w * 0.34,
          fontWeight: FontWeight.w900,
          height: 1,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, h * 0.52 - textPainter.height / 2),
    );
  }

  Path _jerseyPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.40, 0)
      ..quadraticBezierTo(w * 0.5, h * 0.10, w * 0.60, 0)
      ..lineTo(w * 0.66, h * 0.05)
      ..quadraticBezierTo(w * 0.92, h * 0.10, w * 0.90, h * 0.26)
      ..quadraticBezierTo(w * 0.88, h * 0.37, w * 0.76, h * 0.34)
      ..quadraticBezierTo(w * 0.70, h * 0.31, w * 0.69, h * 0.38)
      ..lineTo(w * 0.69, h * 0.94)
      ..quadraticBezierTo(w * 0.69, h, w * 0.63, h)
      ..lineTo(w * 0.37, h)
      ..quadraticBezierTo(w * 0.31, h, w * 0.31, h * 0.94)
      ..lineTo(w * 0.31, h * 0.38)
      ..quadraticBezierTo(w * 0.30, h * 0.31, w * 0.24, h * 0.34)
      ..quadraticBezierTo(w * 0.12, h * 0.37, w * 0.10, h * 0.26)
      ..quadraticBezierTo(w * 0.08, h * 0.10, w * 0.34, h * 0.05)
      ..close();
  }

  Color _shade(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  bool shouldRepaint(covariant _JerseyPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.numberColor != numberColor ||
      oldDelegate.trimColor != trimColor ||
      oldDelegate.number != number;
}
