import 'dart:ui';

import 'package:flame/components.dart';

/// Sombra da bola projetada no gramado — fica fixa na altura do chão (o
/// jogo só atualiza o X pra seguir a bola) e encolhe/clareia conforme a
/// bola sobe, dando a leitura de altura. Separada da bola de propósito.
class KeepyUppyBallShadow extends PositionComponent {
  KeepyUppyBallShadow() : super(anchor: Anchor.center);

  /// 0 = bola no chão, 1 = bola no ponto mais alto.
  double heightFraction = 0;
  double baseWidth = 44;

  final Paint _paint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  @override
  void render(Canvas canvas) {
    final f = heightFraction.clamp(0.0, 1.0);
    final scale = 1 - 0.55 * f;
    final w = baseWidth * scale;
    _paint.color = Color.fromRGBO(0, 0, 0, 0.34 * (1 - 0.6 * f));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.34),
      _paint,
    );
  }
}
