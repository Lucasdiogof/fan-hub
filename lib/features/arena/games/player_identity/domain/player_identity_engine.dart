import 'dart:math' as math;

import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';

/// Toda a matemática do jogo "Que craque é você?" — funções puras, sem
/// estado, sem I/O (mesmo espírito de `tactical_identity_engine.dart`). O
/// resultado SEMPRE é recalculado percorrendo as 10 respostas, nunca um
/// score incremental acumulado — voltar e trocar uma resposta nunca
/// duplica nada.
///
/// [references] é o ÚNICO dado que varia por clube (2026-09-08, arquitetura
/// multiclube) — perguntas, fórmula, dimensões e curva de afinidade são os
/// MESMOS pra qualquer clube, nunca alterados aqui. Ver
/// `player_identity_reference_sets.dart` pra como resolver o dataset certo
/// a partir do `ClubConfig` ativo; para o Goiás o valor é
/// `playerIdentityReferences`, byte a byte o mesmo dataset de sempre.
class PlayerIdentityEngine {
  // Não é `const`: `_referenceStats` é `late final` (depende de [references],
  // que varia por clube), e Dart não permite `late final` de instância numa
  // classe com construtor `const`.
  PlayerIdentityEngine(this.references);

  final List<PlayerIdentityReference> references;

  /// Piso/teto dos atributos exibidos — alargado a pedido (era 45–98,
  /// espalhava pouco as barras de um mesmo usuário entre si). Continua
  /// nunca sendo 0–100 puro (não queremos um atributo "vergonhosamente"
  /// baixo num teste recreativo), mas o spread maior (75 em vez de 53) faz
  /// ponto forte/fraco do MESMO usuário se diferenciarem bem mais.
  static const _attributeFloor = 25;
  static const _attributeCeiling = 100;

  /// Piso/teto da % de afinidade — jogadores de estilo bem diferente podem
  /// cair perto de 40%, os realmente parecidos perto de 98%.
  static const _affinityFloor = 40.0;
  static const _affinityCeiling = 98.0;

  /// Constante da curva de afinidade (`similarity = exp(-_affinityK *
  /// distance)`) — calibrada em `tool/player_identity_calibration.dart`
  /// contra as metas do pedido: empate visual raro, sem concentrar tudo em
  /// 85–95% nem em 55–65%, gap médio Top1→Top2 relevante. Nunca a fórmula
  /// linear antiga (`98 - distância*constante`): ela comprimia demais
  /// distâncias intermediárias, que é justamente onde a maioria dos
  /// resultados reais cai.
  static const _affinityK = 0.62;

  /// Média/desvio padrão de cada dimensão calculados a partir das
  /// referências do CLUBE ATIVO — usados pra padronizar (z-score) os
  /// vetores antes de medir distância. Sem isso, uma dimensão naturalmente
  /// pouco variável entre os jogadores de referência (ex.: intensidade,
  /// historicamente mais parecida no elenco) pesaria MENOS na comparação do
  /// que uma dimensão naturalmente dispersa (ex.: criatividade) só por
  /// causa da escala — não porque seja de fato menos relevante pro estilo
  /// de ninguém. `late final` de INSTÂNCIA (não mais `static`, desde a
  /// multiclube): cada clube tem seu próprio dataset, então as estatísticas
  /// não podem ser compartilhadas entre instâncias com [references]
  /// diferentes — continua calculado uma vez só, na primeira leitura desta
  /// instância.
  late final Map<PlayerIdentityDimension, (double mean, double stdDev)>
  _referenceStats = _computeReferenceStats();

  Map<PlayerIdentityDimension, (double, double)> _computeReferenceStats() {
    final stats = <PlayerIdentityDimension, (double, double)>{};
    for (final d in PlayerIdentityDimension.values) {
      final values = references.map((r) => r[d].toDouble()).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          values.length;
      final stdDev = math.sqrt(variance);
      // Guarda contra divisão por zero — nunca acontece com o dataset
      // atual (nenhuma dimensão é constante entre as 21 referências), mas
      // uma dimensão futura sem variância não pode derrubar o cálculo.
      stats[d] = (mean, stdDev == 0 ? 1.0 : stdDev);
    }
    return stats;
  }

  double _zScore(int value, PlayerIdentityDimension d) {
    final (mean, stdDev) = _referenceStats[d]!;
    return (value - mean) / stdDev;
  }

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

  /// Distância RMS no espaço PADRONIZADO (z-score) entre o vetor do
  /// usuário e o de UM jogador de referência — nunca a distância bruta nas
  /// escalas originais (ver `_referenceStats`/`_zScore`). Nunca arredondada
  /// aqui: arredondamento só acontece na apresentação (`affinityFor`).
  double distanceTo(
    PlayerIdentityAttributes attributes,
    PlayerIdentityReference reference,
  ) {
    var sumSquares = 0.0;
    for (final d in PlayerIdentityDimension.values) {
      final diff = _zScore(attributes[d], d) - _zScore(reference[d], d);
      sumSquares += diff * diff;
    }
    return math.sqrt(sumSquares / PlayerIdentityDimension.values.length);
  }

  /// Curva NÃO LINEAR: `similarity = exp(-_affinityK * distance)`,
  /// `affinity = _affinityFloor + similarity * (_affinityCeiling -
  /// _affinityFloor)`. Precisão total até aqui (distância em double, sem
  /// arredondar em nenhum passo intermediário) — só a casa decimal final
  /// arredonda, na apresentação.
  double affinityFor(double distance) {
    final similarity = math.exp(-_affinityK * distance);
    const range = _affinityCeiling - _affinityFloor;
    final raw = _affinityFloor + similarity * range;
    return ((raw * 10).round() / 10).clamp(_affinityFloor, _affinityCeiling);
  }

  /// Todas as referências do clube ativo, ordenadas do mais próximo pro
  /// mais distante do vetor do usuário — sempre todas elas, quem decide
  /// "top 3" é [closestReferences].
  List<PlayerIdentityAffinity> rankReferences(PlayerIdentityAttributes attributes) {
    final ranked =
        references.map((reference) {
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
