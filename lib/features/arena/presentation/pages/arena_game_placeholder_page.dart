import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';
import 'package:goias_app/features/arena/shared/game/arena_game_scaffold.dart';
import 'package:goias_app/features/arena/shared/game/arena_scene_game.dart';
import 'package:goias_app/shared/widgets/coming_soon_page.dart';

class ArenaGamePlaceholderPage extends StatelessWidget {
  const ArenaGamePlaceholderPage({required this.game, super.key});

  final ArenaGame game;

  @override
  Widget build(BuildContext context) {
    if (game.usesFlame) {
      return ArenaGameScaffold(
        title: game.title,
        gameFactory: ArenaSceneGame.new,
        inDevelopment: true,
      );
    }
    return ComingSoonPage(title: game.title.toUpperCase(), message: 'Este jogo está sendo preparado.');
  }
}
