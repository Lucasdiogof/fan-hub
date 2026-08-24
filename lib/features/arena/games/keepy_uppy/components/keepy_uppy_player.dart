import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/arena/games/keepy_uppy/keepy_uppy_models.dart';
import 'package:goias_app/features/arena/shared/arena_assets.dart';

/// Jogador de costas nas embaixadinhas. As três poses são PNGs 1024x1536 no
/// mesmo canvas — cada frame é desenhado no MESMO rect (o tamanho do
/// componente), então trocar de pose nunca muda a escala, a âncora ou a
/// posição do corpo. Foi exatamente o bug do goleiro do pênalti; aqui não
/// pode acontecer porque nada é recortado nem redimensionado por frame.
class KeepyUppyPlayer extends PositionComponent {
  KeepyUppyPlayer() : super(anchor: Anchor.bottomCenter);

  static const double aspectRatio = 1024 / 1536;

  Image? _idle;
  Image? _left;
  Image? _right;

  KeepyUppyPose pose = KeepyUppyPose.idle;

  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;
  final Paint _shadow = Paint()
    ..color = const Color(0x59000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  @override
  Future<void> onLoad() async {
    _idle = await _load(ArenaAssets.keepyPlayerIdle);
    _left = await _load(ArenaAssets.keepyPlayerJuggleLeft);
    _right = await _load(ArenaAssets.keepyPlayerJuggleRight);
  }

  Future<Image> _load(String path) async {
    final data = await rootBundle.load(path);
    final codec = await instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Image? get _current => switch (pose) {
    KeepyUppyPose.idle => _idle,
    KeepyUppyPose.juggleLeft => _left,
    KeepyUppyPose.juggleRight => _right,
  };

  @override
  void render(Canvas canvas) {
    // Sombra de contato no gramado, sob os pés (centro-baixo do componente).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y * 0.985),
        width: size.x * 0.5,
        height: size.y * 0.045,
      ),
      _shadow,
    );

    final img = _current;
    if (img == null) return;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }
}
