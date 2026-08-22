import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';

class ArenaCatalog {
  const ArenaCatalog._();

  static const games = <ArenaGame>[
    ArenaGame(
      id: 'penalty',
      title: 'Desafio dos Pênaltis',
      tagline: 'Faça 5 cobranças e tente superar seu recorde.',
      icon: Icons.sports_soccer_rounded,
      route: '/arena/penalty',
      featured: true,
    ),
    ArenaGame(
      id: 'keepy_uppy',
      title: 'Embaixadinhas',
      tagline: 'Mantenha a bola no ar o máximo que puder.',
      icon: Icons.sports_soccer_rounded,
      route: '/arena/keepy-uppy',
    ),
    ArenaGame(
      id: 'quiz',
      title: 'Quiz do Verdão',
      tagline: 'Teste o quanto você conhece o Goiás.',
      icon: Icons.psychology_alt_rounded,
      route: '/arena/quiz',
      usesFlame: false,
    ),
  ];

  static ArenaGame byRoute(String route) => games.firstWhere((game) => game.route == route);
}
