import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// Nome e descrição de cada um dos 7 arquétipos — conteúdo editorial fixo,
/// mesma convenção de `player_identity_questions.dart` (português puro, sem
/// l10n).
const _names = <PlayerIdentityArchetype, String>{
  PlayerIdentityArchetype.creativity: 'O Inventor',
  PlayerIdentityArchetype.definition: 'O Decisivo',
  PlayerIdentityArchetype.leadership: 'O Líder',
  PlayerIdentityArchetype.intensity: 'O Motor',
  PlayerIdentityArchetype.technique: 'O Refinado',
  PlayerIdentityArchetype.tactics: 'O Estrategista',
  PlayerIdentityArchetype.complete: 'O Completo',
};

const _descriptions = <PlayerIdentityArchetype, String>{
  PlayerIdentityArchetype.creativity:
      'Você enxerga soluções que nem sempre estão no roteiro. Gosta de '
      'quebrar linhas, mudar o ângulo da jogada e encontrar caminhos '
      'inesperados quando o jogo parece travado.',
  PlayerIdentityArchetype.definition:
      'Quando a partida entra na zona de decisão, você quer participar. Seu '
      'instinto é transformar oportunidades em ações concretas e assumir '
      'responsabilidade nos momentos importantes.',
  PlayerIdentityArchetype.leadership:
      'Você joga pensando também em quem está ao seu lado. Organiza, '
      'orienta, assume responsabilidade e tenta dar clareza ao time quando a '
      'partida fica complicada.',
  PlayerIdentityArchetype.intensity:
      'Seu jogo acontece em alta rotação. Pressionar, disputar, atacar '
      'espaços e repetir esforços fazem parte da maneira como você influencia '
      'uma partida.',
  PlayerIdentityArchetype.technique:
      'Você confia na qualidade da execução. Controle, passe, domínio e '
      'capacidade de resolver situações com a bola são as ferramentas que '
      'mais representam sua visão do jogo.',
  PlayerIdentityArchetype.tactics:
      'Você tenta entender a partida antes de agir. Espaço, posicionamento, '
      'cobertura e movimento coletivo pesam tanto quanto a bola em suas '
      'decisões.',
  PlayerIdentityArchetype.complete:
      'Seu perfil não vive de uma única característica. Você mistura '
      'leitura, intensidade, técnica, responsabilidade e capacidade de '
      'decidir de acordo com o que a partida exige.',
};

/// Ordem de desempate quando duas ou mais dimensões batem no mesmo score
/// máximo — o primeiro da lista vence. Nunca alterar sem decisão explícita.
const playerIdentityTieBreakOrder = <PlayerIdentityDimension>[
  PlayerIdentityDimension.leadership,
  PlayerIdentityDimension.tactics,
  PlayerIdentityDimension.creativity,
  PlayerIdentityDimension.technique,
  PlayerIdentityDimension.definition,
  PlayerIdentityDimension.intensity,
];

extension PlayerIdentityArchetypeLabel on PlayerIdentityArchetype {
  String get displayName => _names[this]!;
  String get description => _descriptions[this]!;
}

PlayerIdentityArchetype archetypeForDimension(PlayerIdentityDimension d) =>
    switch (d) {
      PlayerIdentityDimension.creativity => PlayerIdentityArchetype.creativity,
      PlayerIdentityDimension.definition => PlayerIdentityArchetype.definition,
      PlayerIdentityDimension.leadership => PlayerIdentityArchetype.leadership,
      PlayerIdentityDimension.intensity => PlayerIdentityArchetype.intensity,
      PlayerIdentityDimension.technique => PlayerIdentityArchetype.technique,
      PlayerIdentityDimension.tactics => PlayerIdentityArchetype.tactics,
    };
