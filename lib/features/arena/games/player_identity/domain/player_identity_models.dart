/// As seis dimensões comportamentais do jogo "Que craque esmeraldino é
/// você?" — nunca reordenar (a ordem aqui é a mesma usada em qualquer vetor
/// `[creativity, definition, leadership, intensity, technique, tactics]` do
/// motor/dataset).
enum PlayerIdentityDimension {
  creativity,
  definition,
  leadership,
  intensity,
  technique,
  tactics,
}

/// Uma alternativa de uma pergunta — contribui +3 pra [primary] e +1 pra
/// [secondary] (a pergunta 7 opção D foge disso: +2/+2, ver
/// `player_identity_questions.dart`). Nunca existe "certo/errado".
class PlayerIdentityOption {
  const PlayerIdentityOption({
    required this.id,
    required this.text,
    required this.primary,
    required this.secondary,
    this.primaryPoints = 3,
    this.secondaryPoints = 1,
  });

  final String id;
  final String text;
  final PlayerIdentityDimension primary;
  final PlayerIdentityDimension secondary;
  final int primaryPoints;
  final int secondaryPoints;
}

class PlayerIdentityQuestion {
  const PlayerIdentityQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final String id;
  final String text;
  final List<PlayerIdentityOption> options;
}

/// Um jogador histórico do Goiás usado como referência de estilo — os
/// valores 0–100 são vetores EDITORIAIS (não ratings oficiais), ver
/// `player_identity_references.dart`.
class PlayerIdentityReference {
  const PlayerIdentityReference({
    required this.id,
    required this.name,
    required this.period,
    required this.creativity,
    required this.definition,
    required this.leadership,
    required this.intensity,
    required this.technique,
    required this.tactics,
    required this.confidence,
    this.assetPath,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String period;
  final int creativity;
  final int definition;
  final int leadership;
  final int intensity;
  final int technique;
  final int tactics;
  final String confidence;

  /// Preparado pra quando o jogo tiver fotos — nesta versão sempre `null`,
  /// a UI precisa ficar completa sem foto nenhuma.
  final String? assetPath;
  final String? imageUrl;

  int operator [](PlayerIdentityDimension dimension) => switch (dimension) {
    PlayerIdentityDimension.creativity => creativity,
    PlayerIdentityDimension.definition => definition,
    PlayerIdentityDimension.leadership => leadership,
    PlayerIdentityDimension.intensity => intensity,
    PlayerIdentityDimension.technique => technique,
    PlayerIdentityDimension.tactics => tactics,
  };
}

/// O vetor final do usuário nas seis dimensões — cada valor já normalizado
/// pra faixa 45–98 (nunca o rawScore cru), ver
/// `player_identity_engine.dart#computeAttributes`.
class PlayerIdentityAttributes {
  const PlayerIdentityAttributes({
    required this.creativity,
    required this.definition,
    required this.leadership,
    required this.intensity,
    required this.technique,
    required this.tactics,
  });

  final int creativity;
  final int definition;
  final int leadership;
  final int intensity;
  final int technique;
  final int tactics;

  int operator [](PlayerIdentityDimension dimension) => switch (dimension) {
    PlayerIdentityDimension.creativity => creativity,
    PlayerIdentityDimension.definition => definition,
    PlayerIdentityDimension.leadership => leadership,
    PlayerIdentityDimension.intensity => intensity,
    PlayerIdentityDimension.technique => technique,
    PlayerIdentityDimension.tactics => tactics,
  };
}

/// Distância (RMS) e afinidade de UM jogador de referência em relação ao
/// vetor do usuário — sempre calculada, nunca armazenada junto do dataset.
class PlayerIdentityAffinity {
  const PlayerIdentityAffinity({
    required this.reference,
    required this.distance,
    required this.affinity,
  });

  final PlayerIdentityReference reference;
  final double distance;

  /// 55.0–98.0, nunca fora dessa faixa — "afinidade de estilo", não uma
  /// probabilidade/precisão científica. Uma casa decimal (não arredondada
  /// pro inteiro) de propósito: a distância real quase nunca é idêntica
  /// entre duas referências, mas arredondar pro inteiro fazia o topo 3
  /// empatar com frequência em jogadores de estilo parecido (ex.: Dimba e
  /// Dill têm vetores bem próximos) — o que parecia "estático" pro usuário,
  /// mesmo sendo matemática de verdade.
  final double affinity;
}

/// Os 6 arquétipos "puros" (um por dimensão dominante) + o especial "O
/// Completo" pra perfis muito equilibrados.
enum PlayerIdentityArchetype {
  creativity,
  definition,
  leadership,
  intensity,
  technique,
  tactics,
  complete,
}

/// Resultado final de uma sessão completa — sempre recalculado do zero a
/// partir das 10 respostas (nunca um score incremental persistido como
/// fonte da verdade), ver `player_identity_engine.dart#computeResult`.
class PlayerIdentityResult {
  const PlayerIdentityResult({
    required this.attributes,
    required this.archetype,
    required this.topTraits,
    required this.closestReferences,
    required this.answers,
  });

  final PlayerIdentityAttributes attributes;
  final PlayerIdentityArchetype archetype;

  /// As 3 maiores dimensões do usuário, do maior pro menor — "Suas marcas".
  final List<PlayerIdentityDimension> topTraits;

  /// Sempre os 3 jogadores mais próximos, ordenados do maior pro menor
  /// afinidade.
  final List<PlayerIdentityAffinity> closestReferences;

  /// A opção escolhida em cada uma das 10 perguntas, na ordem — o que
  /// realmente é persistido/auditável, nunca só o resultado agregado.
  final List<PlayerIdentityOption> answers;
}
