import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';

class ArenaCatalog {
  const ArenaCatalog._();

  static const games = <ArenaGame>[
    // Oculto por enquanto — reativar removendo o comentário quando voltar.
    // ArenaGame(
    //   id: 'penalty',
    //   title: 'Desafio dos Pênaltis',
    //   tagline: 'Faça 5 cobranças e tente superar seu recorde.',
    //   icon: Icons.sports_soccer_rounded,
    //   route: '/arena/penalty',
    //   featured: true,
    // ),
    ArenaGame(
      id: 'quiz',
      title: 'Quiz do Verdão',
      tagline: 'Teste o quanto você conhece o Goiás.',
      icon: Icons.psychology_alt_rounded,
      route: '/arena/quiz',
      usesFlame: false,
    ),
    ArenaGame(
      id: 'lineup',
      title: 'Adivinhe a Escalação',
      tagline: 'Descubra os 11 titulares de uma partida histórica do Goiás.',
      icon: Icons.groups_2_rounded,
      route: '/arena/lineup',
      usesFlame: false,
    ),
    ArenaGame(
      id: 'career_path',
      title: 'Adivinhe o Jogador',
      tagline: 'Descubra o jogador pela trajetória na carreira.',
      icon: Icons.timeline_rounded,
      route: '/arena/career-path',
      usesFlame: false,
    ),
    ArenaGame(
      id: 'guess_player',
      title: 'Quem Vestiu o Manto?',
      tagline: 'Descubra o jogador secreto pela foto embaçada e pelas pistas.',
      icon: Icons.face_retouching_natural_rounded,
      route: '/arena/guess-player',
      usesFlame: false,
    ),
  ];

  static ArenaGame byRoute(String route) =>
      games.firstWhere((game) => game.route == route);
}
