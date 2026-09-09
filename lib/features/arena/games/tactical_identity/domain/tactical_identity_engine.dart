import 'dart:math' as math;

import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Toda a matemática do jogo "Identidade Futebolística" — funções puras,
/// sem estado, sem I/O, pra poder ser testada isoladamente e pra deixar o
/// Cubit/UI livres de qualquer regra de negócio (ver spec: "respostas
/// selecionadas" são a fonte da verdade, o resultado SEMPRE é recalculado
/// percorrendo as 10 respostas, nunca um score incremental acumulado).
///
/// Desde a recalibração v2 (2026-09-01): MAPA (x/y, arquétipo) e AFINIDADE
/// COMPLETA são coisas SEPARADAS. O mapa continua sendo só x/y, sem
/// mudança nenhuma na fórmula. A afinidade completa passou a usar também
/// as 4 dimensões táticas ocultas (pressing/blockHeight/risk/
/// structuralFluidity) — dois técnicos podem estar próximos no mapa 2D e
/// ainda assim serem bem diferentes taticamente; a afinidade agora
/// consegue expressar isso, o mapa continua mostrando só posse/vertical e
/// dogmático/pragmático.
///
/// [references] é o ÚNICO dado que varia por clube (2026-09-08, arquitetura
/// multiclube) — geometria dos eixos, arquétipos, dimensões ocultas e curva
/// de afinidade são os MESMOS pra qualquer clube, nunca alterados aqui. Ver
/// `tactical_coach_reference_sets.dart` pra como resolver o dataset certo a
/// partir do `ClubConfig` ativo; para o Goiás o valor é
/// `tacticalCoachReferences`, byte a byte o mesmo dataset de sempre.
class TacticalIdentityEngine {
  // Não é `const`: `_referenceStats` é `late final` (depende de
  // [references], que varia por clube), e Dart não permite `late final` de
  // instância numa classe com construtor `const`.
  TacticalIdentityEngine(this.references);

  final List<TacticalCoachReference> references;

  int sumDeltaX(List<TacticalOption> answers) =>
      answers.fold(0, (sum, option) => sum + option.deltaX);

  int sumDeltaY(List<TacticalOption> answers) =>
      answers.fold(0, (sum, option) => sum + option.deltaY);

  /// `x = clamp(round((sumX / 20) * 100), -100, 100)`.
  int normalizeX(int sumX) => _normalize(sumX);

  /// `y = clamp(round((sumY / 20) * 100), -100, 100)`.
  int normalizeY(int sumY) => _normalize(sumY);

  int _normalize(int sum) =>
      ((sum / 20) * 100).round().clamp(-100, 100).toInt();

  /// `posse = round((100 - x) / 2)`.
  int possessionPercentage(int x) => ((100 - x) / 2).round();

  /// `vertical = 100 - posse`.
  int verticalPercentage(int possession) => 100 - possession;

  /// `pragmatico = round((100 + y) / 2)`.
  int pragmaticPercentage(int y) => ((100 + y) / 2).round();

  /// `dogmatico = 100 - pragmatico`.
  int dogmaticPercentage(int pragmatic) => 100 - pragmatic;

  TacticalAxisLean _xLean(int x) {
    if (x <= -25) return TacticalAxisLean.negative; // POSSE
    if (x >= 25) return TacticalAxisLean.positive; // VERTICAL
    return TacticalAxisLean.center;
  }

  TacticalAxisLean _yLean(int y) {
    if (y <= -25) return TacticalAxisLean.negative; // DOGMÁTICO
    if (y >= 25) return TacticalAxisLean.positive; // PRAGMÁTICO
    return TacticalAxisLean.center;
  }

  /// As 9 combinações exatas do pedido original — nunca adicionar um
  /// arquétipo a mais nem menos, sempre as mesmas 3×3 combinações de eixo.
  /// Usa SÓ x/y — o mapa nunca depende das dimensões ocultas.
  TacticalArchetype classifyArchetype(int x, int y) {
    final xLean = _xLean(x);
    final yLean = _yLean(y);
    return switch ((xLean, yLean)) {
      (TacticalAxisLean.negative, TacticalAxisLean.positive) =>
        TacticalArchetype.associativoFlexivel, // POSSE + PRAGMÁTICO
      (TacticalAxisLean.negative, TacticalAxisLean.negative) =>
        TacticalArchetype.controladorConvicto, // POSSE + DOGMÁTICO
      (TacticalAxisLean.negative, TacticalAxisLean.center) =>
        TacticalArchetype.construtor, // POSSE + CENTRO
      (TacticalAxisLean.positive, TacticalAxisLean.positive) =>
        TacticalArchetype.verticalEstrategico, // VERTICAL + PRAGMÁTICO
      (TacticalAxisLean.positive, TacticalAxisLean.negative) =>
        TacticalArchetype.verticalAgressivo, // VERTICAL + DOGMÁTICO
      (TacticalAxisLean.positive, TacticalAxisLean.center) =>
        TacticalArchetype.diretoEquilibrado, // VERTICAL + CENTRO
      (TacticalAxisLean.center, TacticalAxisLean.positive) =>
        TacticalArchetype.adaptativoTotal, // CENTRO + PRAGMÁTICO
      (TacticalAxisLean.center, TacticalAxisLean.negative) =>
        TacticalArchetype.estruturado, // CENTRO + DOGMÁTICO
      (TacticalAxisLean.center, TacticalAxisLean.center) =>
        TacticalArchetype.equilibradoModerno, // CENTRO + CENTRO
    };
  }

  /// Distância Euclidiana crua no mapa 2D — usada SÓ pra fins visuais (não
  /// mais pra afinidade, ver [_weightedDistance]).
  double euclideanDistance({
    required double userX,
    required double userY,
    required double coachX,
    required double coachY,
  }) {
    final dx = userX - coachX;
    final dy = userY - coachY;
    return math.sqrt(dx * dx + dy * dy);
  }

  int _sumHidden(
    List<TacticalOption> answers,
    int Function(TacticalOption) select,
  ) => answers.fold(0, (sum, option) => sum + select(option));

  /// Cada dimensão oculta pode variar +-2 por pergunta, 10 perguntas —
  /// soma bruta em -20..+20, normalizada pra 0..100 (unipolar, ao
  /// contrário de x/y que são bipolares -100..100).
  int _normalizeHidden(int sum) =>
      (((sum + 20) / 40) * 100).round().clamp(0, 100);

  int userPressing(List<TacticalOption> answers) =>
      _normalizeHidden(_sumHidden(answers, (o) => o.pressing));
  int userBlockHeight(List<TacticalOption> answers) =>
      _normalizeHidden(_sumHidden(answers, (o) => o.blockHeight));
  int userRisk(List<TacticalOption> answers) =>
      _normalizeHidden(_sumHidden(answers, (o) => o.risk));
  int userStructuralFluidity(List<TacticalOption> answers) =>
      _normalizeHidden(_sumHidden(answers, (o) => o.structuralFluidity));

  /// Piso/teto da % de afinidade — recreativa, nunca científica.
  static const _affinityFloor = 40.0;
  static const _affinityCeiling = 98.0;

  /// Constante da curva `similarity = exp(-_affinityK * distance)` —
  /// calibrada em `tool/tactical_identity_calibration.dart`. Nunca a
  /// fórmula linear antiga (`98 - distância*constante`): comprimia
  /// distâncias intermediárias, que é onde a maioria dos resultados reais
  /// cai.
  static const _affinityK = 1.55;

  /// x/y visíveis pesam 45% da afinidade completa (22,5% cada); as 4
  /// dimensões táticas ocultas pesam os outros 55% (13,75% cada) — ver
  /// pedido original. Somam exatamente 1.0.
  static const _weightX = 0.225;
  static const _weightY = 0.225;
  static const _weightHidden = 0.1375;

  /// Média/desvio padrão de cada uma das 6 dimensões (x, y + 4 ocultas)
  /// calculados a partir dos técnicos do CLUBE ATIVO — usados pra
  /// padronizar (z-score) antes de medir distância, mesmo raciocínio de
  /// `player_identity_engine.dart#_referenceStats`: sem isso, uma dimensão
  /// naturalmente pouco variável entre os técnicos pesaria menos na
  /// comparação só por causa da escala. `late final` de INSTÂNCIA (não mais
  /// `static`, desde a multiclube): cada clube tem seu próprio dataset.
  late final Map<String, (double mean, double stdDev)> _referenceStats =
      _computeReferenceStats();

  Map<String, (double, double)> _computeReferenceStats() {
    (double, double) stats(List<double> values) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          values.length;
      final stdDev = math.sqrt(variance);
      return (mean, stdDev == 0 ? 1.0 : stdDev);
    }

    return {
      'x': stats(references.map((c) => c.x).toList()),
      'y': stats(references.map((c) => c.y).toList()),
      'pressing': stats(references.map((c) => c.pressing.toDouble()).toList()),
      'blockHeight': stats(
        references.map((c) => c.blockHeight.toDouble()).toList(),
      ),
      'risk': stats(references.map((c) => c.risk.toDouble()).toList()),
      'structuralFluidity': stats(
        references.map((c) => c.structuralFluidity.toDouble()).toList(),
      ),
    };
  }

  double _zScore(double value, String dimension) {
    final (mean, stdDev) = _referenceStats[dimension]!;
    return (value - mean) / stdDev;
  }

  /// Distância PADRONIZADA (z-score) e PONDERADA entre o perfil completo
  /// do usuário (x, y + 4 ocultas) e UM técnico de referência — a base da
  /// afinidade completa. Nunca arredondada aqui: arredondamento só
  /// acontece na apresentação (`affinityFor`).
  double _weightedDistance({
    required int x,
    required int y,
    required int pressing,
    required int blockHeight,
    required int risk,
    required int structuralFluidity,
    required TacticalCoachReference coach,
  }) {
    final dx = _zScore(x.toDouble(), 'x') - _zScore(coach.x, 'x');
    final dy = _zScore(y.toDouble(), 'y') - _zScore(coach.y, 'y');
    final dPressing =
        _zScore(pressing.toDouble(), 'pressing') -
        _zScore(coach.pressing.toDouble(), 'pressing');
    final dBlock =
        _zScore(blockHeight.toDouble(), 'blockHeight') -
        _zScore(coach.blockHeight.toDouble(), 'blockHeight');
    final dRisk =
        _zScore(risk.toDouble(), 'risk') -
        _zScore(coach.risk.toDouble(), 'risk');
    final dFluidity =
        _zScore(structuralFluidity.toDouble(), 'structuralFluidity') -
        _zScore(coach.structuralFluidity.toDouble(), 'structuralFluidity');

    final weightedSumSquares =
        _weightX * dx * dx +
        _weightY * dy * dy +
        _weightHidden * dPressing * dPressing +
        _weightHidden * dBlock * dBlock +
        _weightHidden * dRisk * dRisk +
        _weightHidden * dFluidity * dFluidity;
    return math.sqrt(weightedSumSquares);
  }

  /// Curva NÃO LINEAR: `similarity = exp(-_affinityK * distance)`,
  /// `affinity = _affinityFloor + similarity * (_affinityCeiling -
  /// _affinityFloor)`. Precisão total até aqui — só a casa decimal final
  /// arredonda, na apresentação.
  double affinityFor(double distance) {
    final similarity = math.exp(-_affinityK * distance);
    const range = _affinityCeiling - _affinityFloor;
    final raw = _affinityFloor + similarity * range;
    return ((raw * 10).round() / 10).clamp(_affinityFloor, _affinityCeiling);
  }

  /// Todos os técnicos do clube ativo ordenados do mais próximo pro mais
  /// distante do PERFIL COMPLETO do usuário (x, y + 4 ocultas) — quem
  /// decide "top 3" é [closestCoaches]. Precisa das respostas (não só x/y)
  /// pra calcular as dimensões ocultas.
  List<CoachAffinity> rankCoaches(int x, int y, List<TacticalOption> answers) {
    final pressing = userPressing(answers);
    final blockHeight = userBlockHeight(answers);
    final risk = userRisk(answers);
    final structuralFluidity = userStructuralFluidity(answers);
    final ranked = references.map((coach) {
      final distance = _weightedDistance(
        x: x,
        y: y,
        pressing: pressing,
        blockHeight: blockHeight,
        risk: risk,
        structuralFluidity: structuralFluidity,
        coach: coach,
      );
      return CoachAffinity(
        coach: coach,
        distance: distance,
        affinity: affinityFor(distance),
      );
    }).toList()..sort((a, b) => a.distance.compareTo(b.distance));
    return ranked;
  }

  /// Os 3 técnicos mais próximos — sempre a partir de [rankCoaches], nunca
  /// uma lista separada (evita as duas listas divergirem).
  List<CoachAffinity> closestCoaches(
    int x,
    int y,
    List<TacticalOption> answers, {
    int count = 3,
  }) => rankCoaches(x, y, answers).take(count).toList();

  /// Recalcula TUDO a partir das 10 respostas — é chamado sempre do zero
  /// (nunca incrementalmente), então voltar e trocar uma resposta nunca
  /// duplica nada: a mesma lista de 10 respostas sempre produz o mesmo
  /// resultado, ponto.
  TacticalIdentityResult computeResult(List<TacticalOption> answers) {
    final sumX = sumDeltaX(answers);
    final sumY = sumDeltaY(answers);
    final x = normalizeX(sumX);
    final y = normalizeY(sumY);
    final possession = possessionPercentage(x);
    final vertical = verticalPercentage(possession);
    final pragmatic = pragmaticPercentage(y);
    final dogmatic = dogmaticPercentage(pragmatic);
    return TacticalIdentityResult(
      x: x,
      y: y,
      possession: possession,
      vertical: vertical,
      dogmatic: dogmatic,
      pragmatic: pragmatic,
      archetype: classifyArchetype(x, y),
      closestCoaches: closestCoaches(x, y, answers),
      answers: answers,
    );
  }
}
