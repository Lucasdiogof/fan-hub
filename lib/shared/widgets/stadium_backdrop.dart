import 'dart:math';

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Fundo que sugere uma cena de estádio à noite — holofotes, grão de foto,
/// vinheta — sem depender de uma fotografia real (que exigiria baixar um
/// asset de origem não verificada). Aceita [imageAsset] para quando uma foto
/// oficial (Serrinha, torcida) entrar no projeto: nesse caso a imagem some
/// para o lugar do gradiente e o resto das camadas (overlay, vinheta, grão)
/// continuam por cima, sem precisar tocar em quem usa este widget.
///
/// [tint] permite reaproveitar a mesma linguagem visual em contextos que não
/// são o verde do clube (ex.: capa de notícia), preservando o "clima" de
/// fotografia editorial em vez de um gradiente genérico.
class StadiumBackdrop extends StatelessWidget {
  const StadiumBackdrop({
    this.tint,
    this.imageAsset,
    this.showFloodlights = true,
    this.overlayOpacity = 0.55,
    super.key,
  });

  final Color? tint;
  final String? imageAsset;

  /// Os feixes de holofote (formas triangulares) — desliga pra um clima só
  /// de foto + escurecimento, sem elementos geométricos por cima.
  final bool showFloodlights;

  /// Intensidade do escurecimento aplicado sobre a fotografia (0–1). Só
  /// entra quando [imageAsset] está presente.
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = tint ?? colors.deepGreen;
    final mid = tint != null
        ? Color.lerp(tint, Colors.black, 0.4)!
        : colors.darkGreen;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageAsset != null)
          Image.asset(imageAsset!, fit: BoxFit.cover)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [mid, base],
              ),
            ),
          ),
        if (showFloodlights)
          Positioned.fill(child: CustomPaint(painter: _FloodlightPainter())),
        const Positioned.fill(child: CustomPaint(painter: _GrainPainter())),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.15,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.42),
              ],
              stops: const [0.55, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
              stops: const [0.4, 1],
            ),
          ),
        ),
        if (imageAsset != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: base.withValues(alpha: overlayOpacity),
            ),
          ),
      ],
    );
  }
}

class _FloodlightPainter extends CustomPainter {
  _FloodlightPainter();

  void _beam(
    Canvas canvas,
    Offset origin,
    double angle,
    double spread,
    double length,
    double opacity,
  ) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(
        origin.dx + length * cos(angle - spread),
        origin.dy + length * sin(angle - spread),
      )
      ..lineTo(
        origin.dx + length * cos(angle + spread),
        origin.dy + length * sin(angle + spread),
      )
      ..close();
    final rect = Rect.fromCircle(center: origin, radius: length);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _beam(
      canvas,
      Offset(size.width * 0.08, -size.height * 0.05),
      pi / 2.5,
      0.3,
      size.height * 1.2,
      0.11,
    );
    _beam(
      canvas,
      Offset(size.width * 0.92, -size.height * 0.05),
      pi - pi / 2.5,
      0.3,
      size.height * 1.2,
      0.08,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    var seed = 17;
    for (var y = 0.0; y < size.height; y += 5.5) {
      for (var x = 0.0; x < size.width; x += 5.5) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final v = seed % 100;
        if (v < 6) {
          paint.color = Colors.white.withValues(alpha: 0.025 + (v % 3) * 0.01);
          canvas.drawCircle(Offset(x + (seed % 5), y + (seed % 4)), 0.8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
