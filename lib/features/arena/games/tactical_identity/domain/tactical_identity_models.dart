/// Uma alternativa de uma pergunta da Identidade Futebolística. Nunca existe
/// "certo/errado" — cada alternativa só desloca o perfil do usuário nos dois
/// eixos táticos PÚBLICOS ([deltaX]/[deltaY], nunca aparecem pro usuário) e,
/// desde a recalibração v2, também pequenas contribuições pras 4 dimensões
/// TÁTICAS OCULTAS ([pressing]/[blockHeight]/[risk]/[structuralFluidity]) —
/// usadas só na AFINIDADE completa com os técnicos, nunca no mapa 2D
/// (ver `tactical_identity_engine.dart`).
class TacticalOption {
  const TacticalOption({
    required this.id,
    required this.text,
    required this.deltaX,
    required this.deltaY,
    this.pressing = 0,
    this.blockHeight = 0,
    this.risk = 0,
    this.structuralFluidity = 0,
  });

  final String id;
  final String text;
  final int deltaX;
  final int deltaY;

  /// Contribuições pras dimensões ocultas — pequenas (tipicamente -2..+2),
  /// nunca mostradas ao usuário, derivadas do SIGNIFICADO real de cada
  /// alternativa (nunca alteradas só pra "encaixar matemática").
  final int pressing;
  final int blockHeight;
  final int risk;
  final int structuralFluidity;
}

class TacticalQuestion {
  const TacticalQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final String id;
  final String text;
  final List<TacticalOption> options;
}

/// Uma passagem específica de um técnico pelo Goiás — não a carreira toda
/// dele, só como aquele período se comportou taticamente. [x]/[y] são dados
/// editoriais do jogo (não estatísticas oficiais); nunca recalibrar sem
/// decisão explícita, ver `tactical_coach_references.dart`.
///
/// [pressing]/[blockHeight]/[risk]/[structuralFluidity] (0–100, desde a
/// recalibração v2) são dimensões táticas OCULTAS — nunca aparecem no mapa
/// nem em nenhuma tela, só entram no cálculo de afinidade completa. Existem
/// porque dois técnicos podem estar relativamente próximos em posse/vertical
/// e dogmático/pragmático e ainda assim serem bem diferentes taticamente
/// (ex.: pressão alta vs. baixa, bloco alto vs. baixo).
class TacticalCoachReference {
  const TacticalCoachReference({
    required this.id,
    required this.coach,
    required this.period,
    required this.x,
    required this.y,
    required this.confidence,
    required this.pressing,
    required this.blockHeight,
    required this.risk,
    required this.structuralFluidity,
    this.assetPath,
    this.imageUrl,
  });

  final String id;
  final String coach;
  final String period;
  final double x;
  final double y;
  final String confidence;
  final int pressing;
  final int blockHeight;
  final int risk;
  final int structuralFluidity;

  /// Preparado pra quando o jogo tiver fotos — nesta versão sempre `null`,
  /// a UI precisa ficar completa sem foto nenhuma.
  final String? assetPath;
  final String? imageUrl;
}

/// Classificação do eixo X (posse↔vertical) ou Y (dogmático↔pragmático)
/// isoladamente — usada só internamente pra combinar em [TacticalArchetype].
enum TacticalAxisLean { negative, center, positive }

/// Os 9 arquétipos possíveis — combinação de onde o usuário cai nos dois
/// eixos (ver `tactical_identity_engine.dart#classifyArchetype`).
enum TacticalArchetype {
  associativoFlexivel,
  controladorConvicto,
  construtor,
  verticalEstrategico,
  verticalAgressivo,
  diretoEquilibrado,
  adaptativoTotal,
  estruturado,
  equilibradoModerno,
}

/// Distância (e afinidade derivada) de UM técnico em relação ao ponto do
/// usuário — sempre calculada, nunca armazenada junto do dataset (o dataset
/// é fixo; a distância depende de quem está jogando).
class CoachAffinity {
  const CoachAffinity({
    required this.coach,
    required this.distance,
    required this.affinity,
  });

  final TacticalCoachReference coach;
  final double distance;

  /// 40.0–98.0, nunca fora dessa faixa — métrica recreativa, não
  /// científica. Uma casa decimal (nunca arredondada pro inteiro) de
  /// propósito, mesma razão de `PlayerIdentityAffinity.affinity`.
  final double affinity;
}

/// Resultado final de uma sessão completa — sempre recalculado do zero a
/// partir das 10 respostas (nunca um score incremental persistido como
/// fonte da verdade), ver `tactical_identity_engine.dart#computeResult`.
class TacticalIdentityResult {
  const TacticalIdentityResult({
    required this.x,
    required this.y,
    required this.possession,
    required this.vertical,
    required this.dogmatic,
    required this.pragmatic,
    required this.archetype,
    required this.closestCoaches,
    required this.answers,
  });

  final int x;
  final int y;

  final int possession;
  final int vertical;
  final int dogmatic;
  final int pragmatic;

  final TacticalArchetype archetype;

  /// Sempre os 3 mais próximos, ordenados do maior pro menor afinidade.
  final List<CoachAffinity> closestCoaches;

  /// A opção escolhida em cada uma das 10 perguntas, na ordem — o que
  /// realmente é persistido/auditável, nunca só o resultado agregado.
  final List<TacticalOption> answers;
}
