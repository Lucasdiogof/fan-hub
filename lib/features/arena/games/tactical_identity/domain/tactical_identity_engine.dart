import 'dart:math' as math;

import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Toda a matemática do jogo "Identidade Futebolística" — funções puras,
/// sem estado, sem I/O, pra poder ser testada isoladamente e pra deixar o
/// Cubit/UI livres de qualquer regra de negócio (ver spec: "respostas
/// selecionadas" são a fonte da verdade, o resultado SEMPRE é recalculado
/// percorrendo as 10 respostas, nunca um score incremental acumulado).
class TacticalIdentityEngine {
  const TacticalIdentityEngine();

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

  /// `distance = sqrt(pow(userX - coachX, 2) + pow(userY - coachY, 2))`.
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

  /// `affinity = clamp(round(98 - distance * 0.22), 55, 98)` — métrica
  /// recreativa, nunca tratada como precisão científica (ver spec).
  int affinityFor(double distance) =>
      (98 - distance * 0.22).round().clamp(55, 98).toInt();

  /// Os 12 técnicos ordenados do mais próximo pro mais distante do ponto
  /// do usuário — sempre os 12, quem decide "top 3" é [closestCoaches].
  List<CoachAffinity> rankCoaches(int x, int y) {
    final ranked =
        tacticalCoachReferences.map((coach) {
          final distance = euclideanDistance(
            userX: x.toDouble(),
            userY: y.toDouble(),
            coachX: coach.x,
            coachY: coach.y,
          );
          return CoachAffinity(
            coach: coach,
            distance: distance,
            affinity: affinityFor(distance),
          );
        }).toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));
    return ranked;
  }

  /// Os 3 técnicos mais próximos — sempre a partir de [rankCoaches], nunca
  /// uma lista separada (evita as duas listas divergirem).
  List<CoachAffinity> closestCoaches(int x, int y, {int count = 3}) =>
      rankCoaches(x, y).take(count).toList();

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
      closestCoaches: closestCoaches(x, y),
      answers: answers,
    );
  }
}
