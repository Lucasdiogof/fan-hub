import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/arena/shared/arena_assets.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

enum KeeperPose { idle, diveLeft, diveRight, center }

/// Goleiro adversário visto de frente.
///
/// Duas formas de desenhar, escolhidas automaticamente em [onLoad]:
/// - **Sprite** (`_renderSprite`), se [ArenaAssets.goalkeeperSheet] existir
///   — 5 frames horizontais (idle, impulso, início do mergulho, mergulho
///   estendido, queda), desenhados sempre pro lado esquerdo; `diveRight`
///   reusa os MESMOS frames espelhados horizontalmente (`canvas.scale(-1,
///   1)`), não existe um segundo sheet pro lado direito. A escolha do
///   frame usa o mesmo [_diveT] que já controlava a animação procedural.
/// - **Procedural** (`_renderProcedural`), como fallback enquanto o sprite
///   sheet não estiver disponível: postura de pronto-defesa (pernas
///   afastadas, joelhos flexionados, tronco levemente inclinado à frente,
///   braços abertos), com o mergulho animado via deslocamento horizontal +
///   impulso vertical + rotação do corpo, tudo aplicado só no `render` (o
///   `position` do componente nunca muda, fica sempre no plano do gol).
class GoalkeeperComponent extends PositionComponent {
  GoalkeeperComponent({required this.jersey}) : super(size: Vector2(70, 120), anchor: Anchor.bottomCenter);

  final Color jersey;
  KeeperPose pose = KeeperPose.idle;

  bool _diving = false;
  double _diveT = 0;
  static const double _diveDuration = 0.34;

  // --- Sprite sheet (opcional) -------------------------------------------
  static const int _spriteFrameCount = 5;
  static const int _idleFrame = 0;
  static const int _pushFrame = 1;
  static const int _diveStartFrame = 2;
  static const int _diveExtendedFrame = 3;
  static const int _landFrame = 4;

  Image? _sheet;
  double _sheetFrameW = 0;
  double _sheetFrameH = 0;
  bool get _hasSprite => _sheet != null;

  @override
  Future<void> onLoad() async {
    try {
      final data = await rootBundle.load(ArenaAssets.goalkeeperSheet);
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

  /// Início do mergulho (ou só reação central) — chamado uma vez por
  /// cobrança, no instante de contato do pé com a bola.
  void dive(KeeperPose target) {
    pose = target;
    _diving = target != KeeperPose.idle;
    _diveT = 0;
  }

  void resetToIdle() {
    pose = KeeperPose.idle;
    _diving = false;
    _diveT = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_diving) return;
    _diveT = min(1, _diveT + dt / _diveDuration);
  }

  late final Paint _body = Paint()..color = jersey;
  late final Paint _bodyShade = Paint()..color = Color.lerp(jersey, const Color(0xFF000000), 0.3)!;
  final Paint _skin = Paint()..color = ArenaColors.skin;
  final Paint _short = Paint()..color = const Color(0xFF0d0f11);
  final Paint _sock = Paint()..color = const Color(0xFF0d0f11);
  final Paint _boot = Paint()..color = const Color(0xFF16191c);
  final Paint _glove = Paint()..color = const Color(0xFFdfe3e6);
  final Paint _gloveShade = Paint()
    ..color = const Color(0xFFb9c0c4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final Paint _hair = Paint()..color = const Color(0xFF20140c);
  final Paint _shadow = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  late final Paint _arm = Paint()
    ..color = jersey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    if (_hasSprite) {
      _renderSprite(canvas);
    } else {
      _renderProcedural(canvas);
    }
  }

  /// Escolhe o frame certo pro estado atual e desenha só ele, mais a sombra
  /// no gramado. Nenhuma translação/rotação é aplicada aqui: cada frame do
  /// sheet já vem desenhado com o deslocamento do corpo "embutido" na
  /// própria arte (padding extra em volta do goleiro nos frames de
  /// mergulho) — é assim que combinamos com quem for desenhar os sprites.
  /// `diveRight` é `diveLeft` espelhado, não um sheet separado.
  void _renderSprite(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h - 2), width: w * 0.7, height: h * 0.05), _shadow);

    final int frame;
    if (!_diving) {
      frame = _idleFrame;
    } else if (pose == KeeperPose.center) {
      frame = _pushFrame;
    } else if (_diveT < 0.2) {
      frame = _pushFrame;
    } else if (_diveT < 0.45) {
      frame = _diveStartFrame;
    } else if (_diveT < 0.85) {
      frame = _diveExtendedFrame;
    } else {
      frame = _landFrame;
    }

    final src = Rect.fromLTWH(frame * _sheetFrameW, 0, _sheetFrameW, _sheetFrameH);
    final dst = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()..filterQuality = FilterQuality.medium;

    if (pose == KeeperPose.diveRight) {
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(_sheet!, src, dst, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(_sheet!, src, dst, paint);
    }
  }

  void _renderProcedural(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h - 2), width: w * 0.7, height: h * 0.05), _shadow);

    final eased = Curves.easeOut.transform(_diveT);
    final direction = switch (pose) {
      KeeperPose.diveLeft => -1.0,
      KeeperPose.diveRight => 1.0,
      KeeperPose.idle || KeeperPose.center => 0.0,
    };
    // Leve inclinação de pronto-defesa mesmo parado; no mergulho o corpo
    // some pro lado (translação), sobe num arco curto (impulso) e gira.
    final dx = direction * w * 0.92 * eased;
    final dy = -sin(min(_diveT, 0.9) * pi / 0.9) * h * (direction == 0 ? 0.10 : 0.30) * (_diving ? 1 : 0);
    final rotation = 0.10 + direction * eased * 0.85;

    final headY = h * 0.10;
    final headR = w * 0.145;
    final torsoTop = h * 0.24;
    final torsoBottom = h * 0.58;
    final shortsBottom = h * 0.72;
    final kneeY = h * 0.85;
    final stance = w * (0.08 + 0.02 * eased.abs());

    canvas.save();
    canvas.translate(cx + dx, h + dy);
    canvas.rotate(rotation);
    canvas.translate(-cx, -h);

    final torso = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - w * 0.26, torsoTop, w * 0.52, torsoBottom - torsoTop),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    canvas.drawRRect(torso, _body);
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.26, torsoTop, w * 0.16, torsoBottom - torsoTop), _bodyShade);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.24, torsoBottom - 4, w * 0.48, shortsBottom - torsoBottom + 4),
        const Radius.circular(6),
      ),
      _short,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - stance - w * 0.16, shortsBottom - 4, w * 0.16, kneeY - shortsBottom + 4),
        const Radius.circular(5),
      ),
      _sock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + stance, shortsBottom - 4, w * 0.16, kneeY - shortsBottom + 4),
        const Radius.circular(5),
      ),
      _sock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - stance * 1.6 - w * 0.17, kneeY - 3, w * 0.2, h - kneeY + 3),
        const Radius.circular(5),
      ),
      _boot,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + stance * 0.6, kneeY - 3, w * 0.2, h - kneeY + 3),
        const Radius.circular(5),
      ),
      _boot,
    );

    _renderArms(canvas, w, h, torsoTop, direction, eased);

    canvas.drawCircle(Offset(cx, headY + headR * 0.15), headR, _skin);
    canvas.drawPath(
      Path()
        ..moveTo(cx - headR * 1.05, headY + headR * 0.6)
        ..quadraticBezierTo(cx - headR * 1.15, headY - headR * 0.8, cx, headY - headR * 1.25)
        ..quadraticBezierTo(cx + headR * 1.15, headY - headR * 0.8, cx + headR * 1.05, headY + headR * 0.6)
        ..quadraticBezierTo(cx + headR * 0.9, headY - headR * 0.05, cx, headY - headR * 0.3)
        ..quadraticBezierTo(cx - headR * 0.9, headY - headR * 0.05, cx - headR * 1.05, headY + headR * 0.6)
        ..close(),
      _hair,
    );

    canvas.restore();
  }

  void _renderArms(Canvas canvas, double w, double h, double torsoTop, double direction, double eased) {
    final armPaint = _arm;
    final shoulderY = torsoTop + h * 0.06;
    final left = Offset(w * 0.24, shoulderY);
    final right = Offset(w * 0.76, shoulderY);

    late final Offset leftHand;
    late final Offset rightHand;
    if (direction == 0) {
      // Idle: mãos prontas à frente do corpo. Reação central (pose
      // `center`, disparada por `dive`): sobem juntas, sem deslocar o
      // corpo — o "salto" pequeno vem só do `dy` calculado em `render`.
      final lift = eased * h * 0.30;
      leftHand = Offset(left.dx - w * 0.05, shoulderY + h * 0.24 - lift);
      rightHand = Offset(right.dx + w * 0.05, shoulderY + h * 0.24 - lift);
    } else {
      // Mergulho: o braço do lado do mergulho estica bem na direção da
      // bola, o outro acompanha o corpo — junto com a rotação em `render`,
      // isso é o que faz parecer salto e não arrasto lateral.
      final reach = w * (0.30 + 0.45 * eased);
      final lift = h * 0.10 * eased;
      leftHand = Offset(left.dx + direction * reach * 0.85, shoulderY - lift - h * 0.06 * eased);
      rightHand = Offset(right.dx + direction * reach, shoulderY - lift - h * 0.10 * eased);
    }

    canvas.drawLine(left, leftHand, armPaint);
    canvas.drawLine(right, rightHand, armPaint);
    canvas.drawCircle(leftHand, w * 0.078, _glove);
    canvas.drawCircle(leftHand, w * 0.078, _gloveShade);
    canvas.drawCircle(rightHand, w * 0.078, _glove);
    canvas.drawCircle(rightHand, w * 0.078, _gloveShade);
  }
}
