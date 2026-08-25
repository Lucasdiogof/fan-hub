import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight, Curves;
import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/arena/shared/arena_assets.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Cobrador visto de costas.
///
/// Duas formas de desenhar, escolhidas automaticamente em [onLoad]:
/// - **Sprite** (`_renderSprite`), se [ArenaAssets.playerKickSheet] existir
///   — 6 frames horizontais (idle, passo esquerdo, passo direito, prepara
///   chute, contato, follow-through), escolhidos a partir do MESMO
///   progresso (`_runT`/`_kickT`) que já controlava a animação
///   procedural — não existe uma segunda linha do tempo pra manter em
///   sincronia.
/// - **Procedural** (`_renderProcedural`), como fallback enquanto o sprite
///   sheet não estiver disponível: proporções atléticas (~7,5 cabeças de
///   altura), pescoço, ombros arredondados, braços e coxas afunilados.
///   Uniforme inspirado na camisa oficial: gola branca envolvendo a nuca,
///   frisos brancos descendo dos ombros, escudo simplificado nas costas,
///   punho branco na manga, textura losangular sutil e número nas costas.
///
/// Em ambos os casos [onContactFrame] dispara exatamente uma vez por
/// chute, no instante visual em que o pé alcança a bola — é isso que
/// `PenaltyGame` usa pra iniciar a trajetória da bola, nunca um
/// `Future.delayed`/`Timer` arbitrário desacoplado da animação.
class PlayerComponent extends PositionComponent {
  PlayerComponent({
    required this.jersey,
    this.shorts = ArenaColors.goiasShorts,
    this.number = '10',
  }) : super(size: Vector2(96, 192), anchor: Anchor.bottomCenter) {
    _buildTexture();
  }

  final Color jersey;
  final Color shorts;
  final String number;

  /// Chamado uma vez por chute, no frame de contato do pé com a bola.
  void Function()? onContactFrame;

  // --- Sprite sheet (opcional) -------------------------------------------
  static const int _spriteFrameCount = 6;
  static const int _idleFrame = 0;
  static const int _stepLeftFrame = 1;
  static const int _stepRightFrame = 2;
  static const int _prepareFrame = 3;
  static const int _contactFrame = 4;
  static const int _followFrame = 5;

  Image? _sheet;
  double _sheetFrameW = 0;
  double _sheetFrameH = 0;
  bool get _hasSprite => _sheet != null;

  @override
  Future<void> onLoad() async {
    try {
      final data = await rootBundle.load(ArenaAssets.playerKickSheet);
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _sheet = frame.image;
      _sheetFrameW = _sheet!.width / _spriteFrameCount;
      _sheetFrameH = _sheet!.height.toDouble();
    } catch (_) {
      // Sheet ainda não fornecido (ou inválido) — fica no fallback
      // procedural, sem erro nenhum pro resto do jogo.
      _sheet = null;
    }
  }

  late final Paint _jerseyDark = Paint()
    ..color = Color.lerp(jersey, const Color(0xFF000000), 0.35)!;
  late final Paint _jerseyLight = Paint()
    ..color = Color.lerp(jersey, const Color(0xFFFFFFFF), 0.08)!;
  final Paint _white = Paint()..color = const Color(0xFFF4F8F5);
  final Paint _shortsPaint = Paint()..color = ArenaColors.goiasShorts;
  final Paint _sock = Paint()..color = const Color(0xFF063014);
  final Paint _boot = Paint()..color = const Color(0xFF14100c);
  final Paint _skin = Paint()..color = ArenaColors.skin;
  final Paint _skinShade = Paint()
    ..color = Color.lerp(ArenaColors.skin, const Color(0xFF000000), 0.15)!;
  final Paint _hair = Paint()..color = const Color(0xFF20140c);
  final Paint _hairShine = Paint()..color = const Color(0x1AFFFFFF);
  final Paint _texture = Paint()
    ..color = const Color(0x24FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  late final Paint _piping = Paint()
    ..color = const Color(0xFFF4F8F5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  final Paint _badgeRing = Paint()
    ..color = const Color(0xFFF4F8F5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3;
  final Paint _shadow = Paint()
    ..color = const Color(0x3A000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  late final Path _diamondPath;
  late final Path _collarPath;
  late final Path _leftPipingPath;
  late final Path _rightPipingPath;
  late final TextPainter _numberPainter;

  bool _kicking = false;
  double _kickT = 0;
  bool _running = false;
  double _runT = 0;
  bool _contactFired = false;

  /// Fração de [_kickT] (0..1, sobre os mesmos 0.4s da animação, sprite ou
  /// procedural) em que o pé visualmente alcança a bola — usada tanto pra
  /// escolher o frame de contato do sprite quanto pra disparar
  /// [onContactFrame] no fallback procedural. Um único número controla as
  /// duas coisas, então sprite e procedural nunca podem dessincronizar.
  static const double _contactAt = 0.35;

  /// Pequena corrida de aproximação até a bola — 2-3 passadas, pernas
  /// alternando — disparada assim que o usuário solta o swipe. Continua
  /// até [stopRunning] ser chamado (quando o jogador chega no ponto de
  /// contato) ou até [playKick] substituir a animação.
  void startRunning() {
    _running = true;
    _runT = 0;
  }

  void stopRunning() => _running = false;

  /// Dispara a animação de chute: pequena preparação (perna vai pra trás),
  /// impacto (perna avança rápido) e finalização — não bloqueia nada além
  /// de si mesma, corre em paralelo com a trajetória da bola. [onContactFrame]
  /// dispara sozinho, em [update], no instante certo — quem chama
  /// [playKick] não precisa (nem deve) agendar nada por fora.
  void playKick() {
    _running = false;
    _kicking = true;
    _kickT = 0;
    _contactFired = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_running) _runT += dt;
    if (!_kicking) return;
    _kickT += dt / 0.4;
    if (!_contactFired && _kickT >= _contactAt) {
      _contactFired = true;
      onContactFrame?.call();
    }
    if (_kickT >= 1) {
      _kickT = 1;
      _kicking = false;
    }
  }

  /// Ângulo (rad) da perna de chute: recua, avança rápido, assenta.
  double get _legSwing {
    final t = _kickT;
    if (t <= 0) return 0;
    if (t < 0.3) {
      final k = t / 0.3;
      return Curves.easeOut.transform(k) * -0.55;
    }
    if (t < 0.6) {
      final k = (t - 0.3) / 0.3;
      return -0.55 + Curves.easeIn.transform(k) * 1.15;
    }
    final k = (t - 0.6) / 0.4;
    return 0.60 - Curves.easeOut.transform(k) * 0.60;
  }

  /// Alternância simples das duas pernas durante a corrida de aproximação.
  double get _leftRunSwing => _running ? sin(_runT * 11) * 0.42 : 0;
  double get _rightRunSwing => _running ? -sin(_runT * 11) * 0.42 : 0;

  void _buildTexture() {
    final w = size.x;
    final h = size.y;
    final path = Path();
    const step = 9.0;
    for (var x = -h.toInt(); x < w + h; x += step.toInt()) {
      path.moveTo(x.toDouble(), 40);
      path.lineTo(x + (h - 40), h);
    }
    for (var x = -h.toInt(); x < w + h; x += step.toInt()) {
      path.moveTo(x.toDouble(), h);
      path.lineTo(x + (h - 40), 40);
    }
    _diamondPath = path;

    final cx = w / 2;
    final torsoTop = h * 0.205;

    // Gola branca envolvendo a nuca (vista de costas — não é o "V" da
    // gola vista de frente) — referência: banda curva sólida na base do
    // pescoço, como na camisa oficial.
    _collarPath = Path()
      ..moveTo(cx - w * 0.17, torsoTop - 1)
      ..quadraticBezierTo(cx - w * 0.11, torsoTop - 15, cx, torsoTop - 17)
      ..quadraticBezierTo(
        cx + w * 0.11,
        torsoTop - 15,
        cx + w * 0.17,
        torsoTop - 1,
      )
      ..quadraticBezierTo(cx + w * 0.12, torsoTop + 7, cx, torsoTop + 5)
      ..quadraticBezierTo(
        cx - w * 0.12,
        torsoTop + 7,
        cx - w * 0.17,
        torsoTop - 1,
      )
      ..close();

    // Frisos brancos descendo dos ombros até a lateral do tronco, um de
    // cada lado da coluna — igual à referência oficial.
    _leftPipingPath = Path()
      ..moveTo(cx - w * 0.13, torsoTop + 3)
      ..quadraticBezierTo(cx - w * 0.24, h * 0.36, cx - w * 0.235, h * 0.58);
    _rightPipingPath = Path()
      ..moveTo(cx + w * 0.13, torsoTop + 3)
      ..quadraticBezierTo(cx + w * 0.24, h * 0.36, cx + w * 0.235, h * 0.58);

    _numberPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: const TextStyle(
          color: Color(0xFFF4F8F5),
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void render(Canvas canvas) {
    if (_hasSprite) {
      _renderSprite(canvas);
    } else {
      _renderProcedural(canvas);
    }
  }

  /// Escolhe o frame certo pro estado atual (idle / correndo — alternando
  /// passo esquerdo e direito — / preparando o chute / contato /
  /// follow-through) e desenha só ele, mais a sombra no gramado. Nenhuma
  /// rotação de "lean" é aplicada aqui: o próprio frame já vem desenhado
  /// com a pose e a inclinação certas.
  void _renderSprite(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h - 3),
        width: w * 0.62,
        height: h * 0.05,
      ),
      _shadow,
    );

    final int frame;
    if (_kicking) {
      frame = _kickT < _contactAt
          ? _prepareFrame
          : (_kickT < 0.7 ? _contactFrame : _followFrame);
    } else if (_running) {
      frame = sin(_runT * 11) >= 0 ? _stepLeftFrame : _stepRightFrame;
    } else {
      frame = _idleFrame;
    }

    final src = Rect.fromLTWH(
      frame * _sheetFrameW,
      0,
      _sheetFrameW,
      _sheetFrameH,
    );
    final dst = Rect.fromLTWH(0, 0, w, h);
    canvas.drawImageRect(
      _sheet!,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _renderProcedural(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    final neckTop = h * 0.145;
    final torsoTop = h * 0.205;
    final torsoBottom = h * 0.615;
    final shortsBottom = h * 0.745;
    final thighBottom = h * 0.80;
    final sockBottom = h * 0.945;
    final legGap = w * 0.03;
    final hipW = w * 0.19;
    final kneeW = w * 0.15;
    final bodyLean = _kicking ? _legSwing * 0.10 : (_running ? 0.09 : 0.0);

    // Sombra no gramado — fora do lean do corpo, sempre "no chão" sob os
    // pés, pra não parecer que o jogador flutua.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h - 3),
        width: w * 0.62,
        height: h * 0.05,
      ),
      _shadow,
    );

    canvas.save();
    canvas.translate(cx, torsoBottom);
    canvas.rotate(bodyLean);
    canvas.translate(-cx, -torsoBottom);

    // Pescoço, entre a cabeça e a gola.
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.075, neckTop, w * 0.15, torsoTop - neckTop + 6),
      _skin,
    );

    final torso = Path()
      ..moveTo(cx - w * 0.30, torsoTop + 6)
      ..quadraticBezierTo(
        cx - w * 0.34,
        (torsoTop + torsoBottom) / 2,
        cx - w * 0.24,
        torsoBottom,
      )
      ..lineTo(cx + w * 0.24, torsoBottom)
      ..quadraticBezierTo(
        cx + w * 0.34,
        (torsoTop + torsoBottom) / 2,
        cx + w * 0.30,
        torsoTop + 6,
      )
      ..lineTo(cx + w * 0.15, torsoTop - 4)
      ..lineTo(cx, torsoTop + 8)
      ..lineTo(cx - w * 0.15, torsoTop - 4)
      ..close();

    canvas.save();
    canvas.clipPath(torso);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _jerseyDark);
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.34, torsoTop, w * 0.3, torsoBottom - torsoTop),
      _jerseyLight,
    );
    canvas.drawPath(_diamondPath, _texture);
    canvas.restore();

    // Ombros arredondados — cobrem a costura reta entre torso e braço.
    canvas.drawCircle(
      Offset(cx - w * 0.30, torsoTop + 10),
      w * 0.075,
      _jerseyDark,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.30, torsoTop + 10),
      w * 0.075,
      _jerseyDark,
    );

    canvas.drawPath(_collarPath, _white);
    canvas.drawPath(_leftPipingPath, _piping);
    canvas.drawPath(_rightPipingPath, _piping);
    canvas.drawCircle(Offset(cx, torsoTop + 16), 6, _badgeRing);

    _drawArm(
      canvas,
      side: -1,
      shoulderX: cx - w * 0.335,
      shoulderY: torsoTop + 8,
      armLen: (torsoBottom - torsoTop) * 0.82,
      w: w,
    );
    _drawArm(
      canvas,
      side: 1,
      shoulderX: cx + w * 0.335,
      shoulderY: torsoTop + 8,
      armLen: (torsoBottom - torsoTop) * 0.82,
      w: w,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - w * 0.25,
          torsoBottom - 4,
          w * 0.5,
          shortsBottom - torsoBottom + 4,
        ),
        const Radius.circular(6),
      ),
      _shortsPaint,
    );

    // Perna esquerda — alterna durante a corrida, fixa no resto do tempo.
    canvas.save();
    canvas.translate(cx - legGap - hipW / 2, shortsBottom);
    canvas.rotate(_leftRunSwing);
    canvas.translate(-(cx - legGap - hipW / 2), -shortsBottom);
    _drawLeg(
      canvas,
      hipX: cx - legGap - hipW,
      hipW: hipW,
      kneeW: kneeW,
      shortsBottom: shortsBottom,
      thighBottom: thighBottom,
      sockBottom: sockBottom,
      h: h,
    );
    canvas.restore();
    // Perna direita — alterna durante a corrida e gira em volta do quadril
    // durante playKick (recuo → impacto → finalização).
    canvas.save();
    canvas.translate(cx + legGap + hipW / 2, shortsBottom);
    canvas.rotate(_kicking ? _legSwing : _rightRunSwing);
    canvas.translate(-(cx + legGap + hipW / 2), -shortsBottom);
    _drawLeg(
      canvas,
      hipX: cx + legGap,
      hipW: hipW,
      kneeW: kneeW,
      shortsBottom: shortsBottom,
      thighBottom: thighBottom,
      sockBottom: sockBottom,
      h: h,
    );
    canvas.restore();

    _numberPainter.paint(
      canvas,
      Offset(
        cx - _numberPainter.width / 2,
        torsoTop + (torsoBottom - torsoTop) * 0.32,
      ),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.075),
        width: w * 0.28,
        height: h * 0.15,
      ),
      _skin,
    );
    _drawHair(canvas, cx, w, h);

    canvas.restore();
  }

  /// Braço afunilado (mais largo no ombro, mais estreito no punho) com uma
  /// leve quebra no cotovelo — em vez do retângulo de largura constante da
  /// versão anterior.
  void _drawArm(
    Canvas canvas, {
    required int side,
    required double shoulderX,
    required double shoulderY,
    required double armLen,
    required double w,
  }) {
    final elbowY = shoulderY + armLen * 0.52;
    final wristY = shoulderY + armLen;
    final bend = side * w * 0.025;

    final outerTop = Offset(shoulderX + side * w * 0.045, shoulderY);
    final innerTop = Offset(shoulderX - side * w * 0.045, shoulderY);
    final outerElbow = Offset(shoulderX + bend + side * w * 0.05, elbowY);
    final innerElbow = Offset(shoulderX + bend - side * w * 0.025, elbowY);
    final outerWrist = Offset(
      shoulderX + bend * 1.6 + side * w * 0.032,
      wristY,
    );
    final innerWrist = Offset(shoulderX + bend * 1.6 - side * w * 0.02, wristY);

    final arm = Path()
      ..moveTo(outerTop.dx, outerTop.dy)
      ..quadraticBezierTo(
        outerElbow.dx,
        outerElbow.dy,
        outerWrist.dx,
        outerWrist.dy,
      )
      ..lineTo(innerWrist.dx, innerWrist.dy)
      ..quadraticBezierTo(
        innerElbow.dx,
        innerElbow.dy,
        innerTop.dx,
        innerTop.dy,
      )
      ..close();
    canvas.drawPath(arm, _jerseyDark);

    final cuffMid = Offset((outerWrist.dx + innerWrist.dx) / 2, wristY - 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: cuffMid,
        width: (outerWrist.dx - innerWrist.dx).abs() + 6,
        height: 11,
      ),
      _white,
    );
    canvas.drawCircle(
      Offset(cuffMid.dx, wristY + 6),
      (outerWrist.dx - innerWrist.dx).abs() * 0.65,
      _skin,
    );
  }

  void _drawLeg(
    Canvas canvas, {
    required double hipX,
    required double hipW,
    required double kneeW,
    required double shortsBottom,
    required double thighBottom,
    required double sockBottom,
    required double h,
  }) {
    final inset = (hipW - kneeW) / 2;
    final thigh = Path()
      ..moveTo(hipX, shortsBottom - 6)
      ..lineTo(hipX + hipW, shortsBottom - 6)
      ..lineTo(hipX + hipW - inset, thighBottom)
      ..lineTo(hipX + inset, thighBottom)
      ..close();
    canvas.drawPath(thigh, _skin);
    canvas.drawPath(
      Path()
        ..moveTo(hipX + hipW * 0.55, shortsBottom - 4)
        ..lineTo(hipX + hipW - inset * 0.6, thighBottom - 2)
        ..lineTo(hipX + hipW - inset, thighBottom)
        ..lineTo(hipX + hipW, shortsBottom - 6)
        ..close(),
      _skinShade,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          hipX + inset,
          thighBottom,
          kneeW,
          sockBottom - thighBottom,
        ),
        const Radius.circular(4),
      ),
      _sock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          hipX + inset - 1,
          sockBottom - 2,
          kneeW + 2,
          h - sockBottom + 2,
        ),
        const Radius.circular(4),
      ),
      _boot,
    );
  }

  /// Cabelo curto e escuro, visto de costas — silhueta cheia cobrindo o
  /// alto e a lateral da cabeça (a versão antiga era só uma tira fina no
  /// topo e deixava o boneco com cara de careca).
  void _drawHair(Canvas canvas, double cx, double w, double h) {
    final headCenter = Offset(cx, h * 0.075);
    final headRx = w * 0.14;
    final headRy = h * 0.075;
    canvas.drawPath(
      Path()
        ..moveTo(headCenter.dx - headRx * 1.05, headCenter.dy + headRy * 0.55)
        ..quadraticBezierTo(
          headCenter.dx - headRx * 1.15,
          headCenter.dy - headRy * 0.75,
          headCenter.dx,
          headCenter.dy - headRy * 1.2,
        )
        ..quadraticBezierTo(
          headCenter.dx + headRx * 1.15,
          headCenter.dy - headRy * 0.75,
          headCenter.dx + headRx * 1.05,
          headCenter.dy + headRy * 0.55,
        )
        ..quadraticBezierTo(
          headCenter.dx + headRx * 0.9,
          headCenter.dy - headRy * 0.05,
          cx,
          headCenter.dy - headRy * 0.3,
        )
        ..quadraticBezierTo(
          headCenter.dx - headRx * 0.9,
          headCenter.dy - headRy * 0.05,
          headCenter.dx - headRx * 1.05,
          headCenter.dy + headRy * 0.55,
        )
        ..close(),
      _hair,
    );
    canvas.drawPath(
      Path()
        ..moveTo(headCenter.dx - headRx * 0.5, headCenter.dy - headRy * 0.9)
        ..quadraticBezierTo(
          cx,
          headCenter.dy - headRy * 1.25,
          headCenter.dx + headRx * 0.2,
          headCenter.dy - headRy * 0.85,
        )
        ..lineTo(headCenter.dx - headRx * 0.2, headCenter.dy - headRy * 0.75)
        ..close(),
      _hairShine,
    );
  }
}
