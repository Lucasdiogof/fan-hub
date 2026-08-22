import 'dart:ui';

import 'package:flame/game.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/arena/shared/components/ball_component.dart';
import 'package:goias_app/features/arena/shared/components/field_component.dart';

enum ArenaGameStatus { loadingAssets, ready, playing, paused, finished }

class ArenaSceneGame extends FlameGame {
  ArenaGameStatus status = ArenaGameStatus.loadingAssets;

  late final BallComponent _ball;

  @override
  Color backgroundColor() => ArenaColors.arenaBottom;

  @override
  Future<void> onLoad() async {
    await add(FieldComponent());
    _ball = BallComponent(radius: 18)..position = size / 2;
    await add(_ball);
    status = ArenaGameStatus.ready;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _ball.position = size / 2;
    }
  }
}
