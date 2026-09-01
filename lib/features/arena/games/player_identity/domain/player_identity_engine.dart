import 'dart:math' as math;

import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_references.dart';

/// Toda a matemática do jogo "Que craque esmeraldino é você?" — funções
/// puras, sem estado, sem I/O (mesmo espírito de
/// `tactical_identity_engine.dart`). O resultado SEMPRE é recalculado
/// percorrendo as 10 respostas, nunca um score incremental acumulado —
/// voltar e trocar uma resposta nunca duplica nada.
class PlayerIdentityEngine {
  const PlayerIdentityEngine();

  /// Piso/teto dos atributos exibidos — alargado a pedido (era 45–98,
  /// espalhava pouco as barras de um mesmo usuário entre si). Continua
  /// nunca sendo 0–100 puro (não queremos um atributo "vergonhosamente"
  /// baixo num teste recreativo), mas o spread maior (75 em vez de 53) faz
  /// ponto forte/fraco do MESMO usuário se diferenciarem bem mais.
  static const _attributeFloor = 25;
  static const _attributeCeiling = 100;

  /// Distância RMS teórica máxima entre dois vetores de 6 dimensões nessa
  /// escala — cada dimensão pode diferir no máximo por
  /// `_attributeCeiling - _attributeFloor`; a fórmula da afinidade usa isso
  /// como o "pior caso" pra normalizar.
  static const _maxTheoreticalDistance =
      (_attributeCeiling - _attributeFloor) * 1.0;

  /// Piso/teto da % de afinidade — também alargado a pedido (era 55–98):
  /// jogadores de estilo bem diferente agora podem cair perto de 40%, não
  /// só nunca abaixo de 55%.
  static const _affinityFloor = 40.0;
  static const _affinityCeiling = 98.0;

  int _contribution(PlayerIdentityOption option, PlayerIdentityDimension d) {
    var points = 0;
    if (option.primary == d) points += option.primaryPoints;
    if (option.secondary == d) points += option.secondaryPoints;
    return points;
  }

  /// Soma das contribuições das alternativas ESCOLHIDAS, uma dimensão.
  int rawScore(List<PlayerIdentityOption> answers, PlayerIdentityDimension d) =>
      answers.fold(0, (sum, option) => sum + _contribution(option, d));

  /// Pra cada pergunta do banco inteiro, pega a maior contribuição possível
  /// naquela dimensão entre as 4 alternativas, e soma — NUNCA um /30 fixo,
  /// já que cada dimensão tem oportunidades diferentes entre as perguntas.
  int maxPossibleScore(PlayerIdentityDimension d) {
    var total = 0;
    for (final question in playerIdentityQuestions) {
      var best = 0;
      for (final option in question.options) {
        final contribution = _contribution(option, d);
        if (contribution > best) best = contribution;
      }
      total += best;
    }
    return total;
  }

  /// `_attributeFloor + round(normalized * (_attributeCeiling -
  /// _attributeFloor))`, clamp `_attributeFloor`–`_attributeCeiling`.
  int normalizedScore(int rawScore, int maxPossibleScore) {
    if (maxPossibleScore <= 0) return _attributeFloor;
    final normalized = rawScore / maxPossibleScore;
    const spread = _attributeCeiling - _attributeFloor;
    return (_attributeFloor + (normalized * spread).round()).clamp(
      _attributeFloor,
      _attributeCeiling,
    );
  }

  /// O vetor final do usuário nas seis dimensões, já normalizado.
  PlayerIdentityAttributes computeAttributes(List<PlayerIdentityOption> answers) {
    int scoreFor(PlayerIdentityDimension d) =>
        normalizedScore(rawScore(answers, d), maxPossibleScore(d));
    return PlayerIdentityAttributes(
      creativity: scoreFor(PlayerIdentityDimension.creativity),
      definition: scoreFor(PlayerIdentityDimension.definition),
      leadership: scoreFor(PlayerIdentityDimension.leadership),
      intensity: scoreFor(PlayerIdentityDimension.intensity),
      technique: scoreFor(PlayerIdentityDimension.technique),
      tactics: scoreFor(PlayerIdentityDimension.tactics),
    );
  }

  /// Distância RMS entre o vetor do usuário e o de UM jogador de
  /// referência: `sqrt(sum((user_i - player_i)^2) / 6)`.
  double distanceTo(
    PlayerIdentityAttributes attributes,
    PlayerIdentityReference reference,
  ) {
    var sumSquares = 0.0;
    for (final d in PlayerIdentityDimension.values) {
      final diff = (attributes[d] - reference[d]).toDouble();
      sumSquares += diff * diff;
    }
    return math.sqrt(sumSquares / PlayerIdentityDimension.values.length);
  }

  /// `normalizedDistance = clamp(distance/_maxTheoreticalDistance, 0, 1)`;
  /// `affinity = _affinityCeiling - normalizedDistance * (_affinityCeiling -
  /// _affinityFloor)`, arredondado pra uma casa decimal (nunca pro inteiro
  /// — ver `PlayerIdentityAffinity.affinity`), clamp
  /// `_affinityFloor`–`_affinityCeiling`.
  double affinityFor(double distance) {
    final normalizedDistance = (distance / _maxTheoreticalDistance).clamp(
      0.0,
      1.0,
    );
    const range = _affinityCeiling - _affinityFloor;
    final raw = _affinityCeiling - normalizedDistance * range;
    return ((raw * 10).round() / 10).clamp(_affinityFloor, _affinityCeiling);
  }

  /// As 19 referências ordenadas do mais próximo pro mais distante do vetor
  /// do usuário — sempre as 19, quem decide "top 3" é [closestReferences].
  List<PlayerIdentityAffinity> rankReferences(PlayerIdentityAttributes attributes) {
    final ranked =
        playerIdentityReferences.map((reference) {
          final distance = distanceTo(attributes, reference);
          return PlayerIdentityAffinity(
            reference: reference,
            distance: distance,
            affinity: affinityFor(distance),
          );
        }).toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));
    return ranked;
  }

  /// Os 3 jogadores mais próximos — sempre a partir de [rankReferences],
  /// nunca uma lista separada (evita as duas listas divergirem).
  List<PlayerIdentityAffinity> closestReferences(
    PlayerIdentityAttributes attributes, {
    int count = 3,
  }) => rankReferences(attributes).take(count).toList();

  /// A dimensão com maior score define o arquétipo — em caso de empate,
  /// `playerIdentityTieBreakOrder` decide (primeiro da lista vence). Se
  /// `max - min <= 8` (perfil muito equilibrado), vira "O Completo",
  /// independente de qual dimensão venceria.
  PlayerIdentityArchetype classifyArchetype(PlayerIdentityAttributes attributes) {
    final scores = {
      for (final d in PlayerIdentityDimension.values) d: attributes[d],
    };
    final maxScore = scores.values.reduce(math.max);
    final minScore = scores.values.reduce(math.min);
    if (maxScore - minScore <= 8) return PlayerIdentityArchetype.complete;
    for (final d in playerIdentityTieBreakOrder) {
      if (scores[d] == maxScore) return archetypeForDimension(d);
    }
    // Inalcançável: `playerIdentityTieBreakOrder` cobre as 6 dimensões.
    return archetypeForDimension(PlayerIdentityDimension.leadership);
  }

  /// As três maiores dimensões do usuário, do maior pro menor score —
  /// "Suas marcas". Em empate, segue a ordem natural de
  /// `PlayerIdentityDimension.values` (determinístico).
  List<PlayerIdentityDimension> topTraits(PlayerIdentityAttributes attributes) {
    final dimensions = [...PlayerIdentityDimension.values]
      ..sort((a, b) => attributes[b].compareTo(attributes[a]));
    return dimensions.take(3).toList();
  }

  /// Recalcula TUDO a partir das 10 respostas — chamado sempre do zero
  /// (nunca incrementalmente), então voltar e trocar uma resposta nunca
  /// duplica nada: a mesma lista de 10 respostas sempre produz o mesmo
  /// resultado, ponto.
  PlayerIdentityResult computeResult(List<PlayerIdentityOption> answers) {
    final attributes = computeAttributes(answers);
    return PlayerIdentityResult(
      attributes: attributes,
      archetype: classifyArchetype(attributes),
      topTraits: topTraits(attributes),
      closestReferences: closestReferences(attributes),
      answers: answers,
    );
  }
}
