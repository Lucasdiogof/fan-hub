import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart'
    show LinearGradient, RadialGradient, Alignment;
import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/arena/shared/arena_assets.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Fundo completo da cena: arquibancada + faixa "Força Jovem Goiás" (foto
/// real, carregada uma única vez) integrada ao resto do cenário com
/// escurecimento gradual, gramado com marcação oficial em perspectiva e
/// vinheta geral pra dar profundidade. A fração [_backdropFraction] tem
/// que bater com a posição do gol calculada em cada jogo (ver
/// `PenaltyGame._layout`); [penaltySpotY] é a fonte única de verdade de
/// onde fica a marca — `PenaltyGame` usa exatamente esse valor pra
/// posicionar a bola, então os dois nunca podem ficar fora de sincronia.
class FieldComponent extends PositionComponent {
  static const double _backdropFraction = 0.26;

  /// Fração da altura do gramado (não da tela inteira) onde fica a marca
  /// do pênalti — 11m dos 16,5m de profundidade da grande área real, ~0.60.
  static const double _penaltySpotFraction = 0.60;

  static double _grassHeight(double screenHeight) =>
      screenHeight * (1 - _backdropFraction);

  static double penaltySpotY(double screenHeight) =>
      screenHeight * _backdropFraction +
      _grassHeight(screenHeight) * _penaltySpotFraction;

  Image? _backdrop;
  final Paint _wall = Paint()..color = const Color(0xFF0a1c10);
  final Paint _grass = Paint();
  final Paint _stripeDark = Paint()..color = const Color(0x0F000000);
  final Paint _stripeLight = Paint()..color = const Color(0x08FFFFFF);
  final Paint _lines = Paint()
    ..color = const Color(0xB0F4F8F5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _touchlines = Paint()
    ..color = const Color(0x80F4F8F5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _spotRing = Paint()
    ..color = const Color(0xB0F4F8F5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final Paint _spot = Paint()..color = const Color(0xF0F4F8F5);
  final Paint _spotShadow = Paint()..color = const Color(0x30000000);

  Paint? _backdropFade;
  Paint? _vignette;

  @override
  Future<void> onLoad() async {
    final data = await rootBundle.load(ArenaAssets.crowdBanner);
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _backdrop = frame.image;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    final backdropBottom = size.y * _backdropFraction;
    _grass.shader =
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ArenaColors.pitch, ArenaColors.pitchDark],
        ).createShader(
          Rect.fromLTWH(0, 0, size.x, size.y * (1 - _backdropFraction)),
        );

    // Esmaece a base da foto da arquibancada num verde bem escuro, pra não
    // parecer um recorte colado — a transição pro campo fica gradual.
    _backdropFade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x000a1c10), Color(0xFF0a1c10)],
        stops: [0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, backdropBottom));

    // Vinheta geral — escurece os cantos pra dar profundidade e juntar
    // arquibancada, gol e campo numa cena só, em vez de camadas soltas.
    _vignette = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.15),
        radius: 1.15,
        colors: [Color(0x00000000), Color(0x3D000000)],
        stops: [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final backdropBottom = h * _backdropFraction;

    final backdrop = _backdrop;
    if (backdrop != null) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, w, backdropBottom));
      final srcAspect = backdrop.width / backdrop.height;
      final dstW = w;
      final dstH = dstW / srcAspect;
      canvas.drawImageRect(
        backdrop,
        Rect.fromLTWH(
          0,
          0,
          backdrop.width.toDouble(),
          backdrop.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, dstW, dstH),
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (dstH < backdropBottom) {
        canvas.drawRect(
          Rect.fromLTWH(0, dstH, w, backdropBottom - dstH),
          _wall,
        );
      }
      if (_backdropFade case final fade?) {
        canvas.drawRect(Rect.fromLTWH(0, 0, w, backdropBottom), fade);
      }
      canvas.restore();
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, backdropBottom), _wall);
    }

    canvas.save();
    canvas.translate(0, backdropBottom);
    final grassH = h - backdropBottom;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, grassH), _grass);

    // Faixas de corte finas e discretas — só uma variação sutil de tom,
    // não blocos grandes — convergindo pro mesmo ponto de fuga do gol.
    const stripes = 16;
    final goalHalfWidth = w * 0.31;
    // O campo é bem mais largo que o gol — a linha lateral não pode
    // convergir só até a largura do gol, senão "sobra" gramado sem faixa.
    final pitchHalfWidth = goalHalfWidth * 1.9;
    for (var i = 0; i < stripes; i++) {
      final t0 = i / stripes;
      final t1 = (i + 1) / stripes;
      final topHalf = pitchHalfWidth * (1 - t0) + (w / 2) * t0;
      final botHalf = pitchHalfWidth * (1 - t1) + (w / 2) * t1;
      canvas.drawPath(
        Path()
          ..moveTo(w / 2 - topHalf, grassH * t0)
          ..lineTo(w / 2 + topHalf, grassH * t0)
          ..lineTo(w / 2 + botHalf, grassH * t1)
          ..lineTo(w / 2 - botHalf, grassH * t1)
          ..close(),
        i.isEven ? _stripeDark : _stripeLight,
      );
    }

    // Linhas laterais do campo convergindo pro horizonte — sem isso não
    // existia nenhuma referência de que o gramado é um campo de verdade,
    // só as faixas de corte.
    canvas.drawLine(
      Offset(0, grassH),
      Offset(w / 2 - pitchHalfWidth, 0),
      _touchlines,
    );
    canvas.drawLine(
      Offset(w, grassH),
      Offset(w / 2 + pitchHalfWidth, 0),
      _touchlines,
    );

    _renderPitchMarkings(canvas, w, grassH, goalHalfWidth);
    canvas.restore();

    if (_vignette case final vignette?) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);
    }
  }

  /// Pequena área, grande área, arco e marca do pênalti — proporções
  /// aproximadas das reais (5,5 m / 16,5 m / 11 m a partir da linha do
  /// gol), adaptadas à perspectiva simplificada da cena.
  void _renderPitchMarkings(
    Canvas canvas,
    double w,
    double grassH,
    double goalHalfWidth,
  ) {
    _box(
      canvas,
      w,
      grassH,
      halfWidthAtGoal: goalHalfWidth * 1.35,
      depthFraction: 0.24,
    );
    _box(
      canvas,
      w,
      grassH,
      halfWidthAtGoal: goalHalfWidth * 1.9,
      depthFraction: 0.68,
    );

    final spotY = grassH * _penaltySpotFraction;

    // Arco da grande área — só a parte que fica fora da linha de fundo da
    // área, centrado na marca, como no campo de verdade.
    final arcHalfWidth = goalHalfWidth * 1.9 * (1 - 0.68) + (w / 2) * 0.68;
    final arcRadius = (arcHalfWidth - w / 2).abs() + goalHalfWidth * 0.55;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w / 2, spotY), radius: arcRadius),
      0.95,
      1.25,
      false,
      _spotRing,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, spotY + 1.5), width: 15, height: 5),
      _spotShadow,
    );
    canvas.drawCircle(Offset(w / 2, spotY), 4.2, _spot);
  }

  void _box(
    Canvas canvas,
    double w,
    double grassH, {
    required double halfWidthAtGoal,
    required double depthFraction,
  }) {
    final bottomHalf =
        halfWidthAtGoal * (1 - depthFraction) + (w / 2) * depthFraction;
    final bottomY = grassH * depthFraction;
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - halfWidthAtGoal, 0)
        ..lineTo(w / 2 - bottomHalf, bottomY)
        ..lineTo(w / 2 + bottomHalf, bottomY)
        ..lineTo(w / 2 + halfWidthAtGoal, 0),
      _lines,
    );
  }
}
