import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Nome e descrição de cada um dos 9 arquétipos — conteúdo editorial fixo,
/// mesma convenção de `tactical_identity_questions.dart` (português puro,
/// sem l10n).
const _names = <TacticalArchetype, String>{
  TacticalArchetype.associativoFlexivel: 'Associativo Flexível',
  TacticalArchetype.controladorConvicto: 'Controlador Convicto',
  TacticalArchetype.construtor: 'Construtor',
  TacticalArchetype.verticalEstrategico: 'Vertical Estratégico',
  TacticalArchetype.verticalAgressivo: 'Vertical Agressivo',
  TacticalArchetype.diretoEquilibrado: 'Direto Equilibrado',
  TacticalArchetype.adaptativoTotal: 'Adaptativo Total',
  TacticalArchetype.estruturado: 'Estruturado',
  TacticalArchetype.equilibradoModerno: 'Equilibrado Moderno',
};

const _descriptions = <TacticalArchetype, String>{
  TacticalArchetype.associativoFlexivel:
      'Você gosta de controlar o jogo com a bola, aproximar jogadores e '
      'construir com paciência, mas não se prende a uma única solução. Se a '
      'partida pede adaptação, você muda sem abandonar seus princípios.',
  TacticalArchetype.controladorConvicto:
      'Você acredita que o melhor caminho é impor sua maneira de jogar. '
      'Controle, circulação e organização vêm antes da adaptação ao '
      'adversário.',
  TacticalArchetype.construtor:
      'Você prefere que o jogo seja construído com bola, aproximações e '
      'decisões conscientes. Controlar a partida importa mais do que '
      'simplesmente acelerar.',
  TacticalArchetype.verticalEstrategico:
      'Você gosta de transformar espaço em vantagem rapidamente, mas não '
      'confunde velocidade com precipitação. O contexto da partida '
      'determina quando acelerar, proteger ou mudar o plano.',
  TacticalArchetype.verticalAgressivo:
      'Seu futebol olha para frente. Recuperar, acelerar, atacar espaço e '
      'chegar ao gol rapidamente fazem parte da sua identidade, mesmo que '
      'isso signifique assumir riscos.',
  TacticalArchetype.diretoEquilibrado:
      'Você prefere objetividade e progressão, mas sabe que nem toda '
      'jogada precisa terminar rapidamente. Acelera quando existe espaço e '
      'reorganiza quando ele desaparece.',
  TacticalArchetype.adaptativoTotal:
      'Para você, não existe uma única maneira correta de jogar. '
      'Formação, altura do bloco, posse e velocidade são ferramentas '
      'escolhidas de acordo com o adversário e com a partida.',
  TacticalArchetype.estruturado:
      'Você acredita em princípios claros, organização e funções bem '
      'definidas. O time deve reconhecer sua própria identidade antes de '
      'reagir ao que o adversário propõe.',
  TacticalArchetype.equilibradoModerno:
      'Você não pertence aos extremos. Gosta de ter a bola quando ela '
      'ajuda, acelerar quando há espaço e adaptar pequenos detalhes sem '
      'abandonar a organização coletiva.',
};

extension TacticalArchetypeLabel on TacticalArchetype {
  // Nunca `name` aqui — `enum` já tem um `.name` embutido (o identificador
  // Dart, ex. "associativoFlexivel") que sempre vence sobre um getter de
  // extension com o mesmo nome, então um `name` nosso ficaria inacessível.
  String get displayName => _names[this]!;
  String get description => _descriptions[this]!;
}
