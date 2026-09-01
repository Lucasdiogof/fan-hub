import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_cubit.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_engine.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';

TacticalOption _opt(int deltaX, int deltaY, {String id = 'x'}) =>
    TacticalOption(id: id, text: 'x', deltaX: deltaX, deltaY: deltaY);

List<TacticalOption> _answers(List<(int, int)> deltas) => [
  for (var i = 0; i < deltas.length; i++)
    _opt(deltas[i].$1, deltas[i].$2, id: 'a$i'),
];

void main() {
  const engine = TacticalIdentityEngine();

  group('sumDeltaX / sumDeltaY', () {
    test('sums deltaX across all answers', () {
      final answers = _answers([(2, 0), (-1, 0), (0, 0)]);
      expect(engine.sumDeltaX(answers), 1);
    });

    test('sums deltaY across all answers', () {
      final answers = _answers([(0, 2), (0, -1), (0, 2)]);
      expect(engine.sumDeltaY(answers), 3);
    });

    test('empty list sums to zero', () {
      expect(engine.sumDeltaX(const []), 0);
      expect(engine.sumDeltaY(const []), 0);
    });
  });

  group('normalizeX / normalizeY', () {
    test('normalizeX follows clamp(round((sumX/20)*100), -100, 100)', () {
      expect(engine.normalizeX(20), 100);
      expect(engine.normalizeX(-20), -100);
      expect(engine.normalizeX(0), 0);
      expect(engine.normalizeX(10), 50);
      expect(engine.normalizeX(-10), -50);
    });

    test('normalizeX clamps sums beyond the theoretical +-20 range', () {
      expect(engine.normalizeX(40), 100);
      expect(engine.normalizeX(-40), -100);
    });

    test('normalizeY follows the same formula as normalizeX', () {
      expect(engine.normalizeY(20), 100);
      expect(engine.normalizeY(-20), -100);
      expect(engine.normalizeY(6), 30);
    });
  });

  group('possession / vertical percentages', () {
    test('possessionPercentage = round((100 - x) / 2)', () {
      expect(engine.possessionPercentage(-100), 100);
      expect(engine.possessionPercentage(100), 0);
      expect(engine.possessionPercentage(0), 50);
    });

    test('verticalPercentage = 100 - possession', () {
      expect(engine.verticalPercentage(100), 0);
      expect(engine.verticalPercentage(0), 100);
      expect(engine.verticalPercentage(31), 69);
    });
  });

  group('dogmatic / pragmatic percentages', () {
    test('pragmaticPercentage = round((100 + y) / 2)', () {
      expect(engine.pragmaticPercentage(-100), 0);
      expect(engine.pragmaticPercentage(100), 100);
      expect(engine.pragmaticPercentage(0), 50);
    });

    test('dogmaticPercentage = 100 - pragmatic', () {
      expect(engine.dogmaticPercentage(100), 0);
      expect(engine.dogmaticPercentage(0), 100);
      expect(engine.dogmaticPercentage(84), 16);
    });
  });

  group('classifyArchetype — the 9 combinations', () {
    test('POSSE + PRAGMÁTICO => Associativo Flexível', () {
      expect(
        engine.classifyArchetype(-50, 50),
        TacticalArchetype.associativoFlexivel,
      );
    });

    test('POSSE + DOGMÁTICO => Controlador Convicto', () {
      expect(
        engine.classifyArchetype(-50, -50),
        TacticalArchetype.controladorConvicto,
      );
    });

    test('POSSE + CENTRO => Construtor', () {
      expect(engine.classifyArchetype(-50, 0), TacticalArchetype.construtor);
    });

    test('VERTICAL + PRAGMÁTICO => Vertical Estratégico', () {
      expect(
        engine.classifyArchetype(50, 50),
        TacticalArchetype.verticalEstrategico,
      );
    });

    test('VERTICAL + DOGMÁTICO => Vertical Agressivo', () {
      expect(
        engine.classifyArchetype(50, -50),
        TacticalArchetype.verticalAgressivo,
      );
    });

    test('VERTICAL + CENTRO => Direto Equilibrado', () {
      expect(
        engine.classifyArchetype(50, 0),
        TacticalArchetype.diretoEquilibrado,
      );
    });

    test('CENTRO + PRAGMÁTICO => Adaptativo Total', () {
      expect(
        engine.classifyArchetype(0, 50),
        TacticalArchetype.adaptativoTotal,
      );
    });

    test('CENTRO + DOGMÁTICO => Estruturado', () {
      expect(engine.classifyArchetype(0, -50), TacticalArchetype.estruturado);
    });

    test('CENTRO + CENTRO => Equilibrado Moderno', () {
      expect(
        engine.classifyArchetype(0, 0),
        TacticalArchetype.equilibradoModerno,
      );
    });

    test('boundary: x = -25 already counts as POSSE (<=-25)', () {
      expect(engine.classifyArchetype(-25, 0), TacticalArchetype.construtor);
    });

    test('boundary: x = -24 still counts as CENTRO', () {
      expect(
        engine.classifyArchetype(-24, 0),
        TacticalArchetype.equilibradoModerno,
      );
    });

    test('boundary: x = 25 already counts as VERTICAL (>=25)', () {
      expect(
        engine.classifyArchetype(25, 0),
        TacticalArchetype.diretoEquilibrado,
      );
    });
  });

  group('euclideanDistance', () {
    test('matches sqrt(dx^2 + dy^2)', () {
      final distance = engine.euclideanDistance(
        userX: 0,
        userY: 0,
        coachX: 3,
        coachY: 4,
      );
      expect(distance, 5);
    });

    test('distance to the exact same point is zero', () {
      final distance = engine.euclideanDistance(
        userX: 10,
        userY: -20,
        coachX: 10,
        coachY: -20,
      );
      expect(distance, 0);
    });
  });

  group('rankCoaches / closestCoaches', () {
    test('rankCoaches sorts all 12 coaches from nearest to farthest', () {
      final answers = _answers(List.filled(10, (0, 0)));
      final ranked = engine.rankCoaches(0, 0, answers);
      expect(ranked.length, 12);
      for (var i = 1; i < ranked.length; i++) {
        expect(
          ranked[i].distance,
          greaterThanOrEqualTo(ranked[i - 1].distance),
        );
      }
    });

    test('closestCoaches returns exactly the top 3', () {
      final answers = _answers(List.filled(10, (0, 0)));
      final top3 = engine.closestCoaches(0, 0, answers);
      expect(top3.length, 3);
      final ranked = engine.rankCoaches(0, 0, answers);
      expect(
        top3.map((c) => c.coach.id),
        ranked.take(3).map((c) => c.coach.id),
      );
    });
  });

  group('affinityFor', () {
    test('never goes below the floor (40), even for a very distant point', () {
      // Uma distância bem maior que qualquer distância real observada no
      // espaço z-score do dataset — usada só pra exercitar o clamp inferior
      // de affinityFor, não representa mais uma distância euclidiana 2D
      // (a partir da recalibração v2, affinityFor opera sobre a distância
      // ponderada em z-score das 6 dimensões, não mais x/y puro).
      expect(engine.affinityFor(1000), 40);
    });

    test('never goes above 98, even at distance zero', () {
      expect(engine.affinityFor(0), 98);
    });
  });

  group('computeResult — determinism and no accumulation', () {
    test('the same 10 answers always produce the same result', () {
      final answers = _answers(List.filled(10, (1, 2)));
      final first = engine.computeResult(answers);
      final second = engine.computeResult(answers);
      expect(first.x, second.x);
      expect(first.y, second.y);
      expect(first.archetype, second.archetype);
      expect(
        first.closestCoaches.map((c) => c.coach.id),
        second.closestCoaches.map((c) => c.coach.id),
      );
    });

    test(
      'going back and picking a different option for one question never '
      'accumulates on top of the old one — only the final 10 answers count',
      () {
        final cubit = TacticalIdentityCubit();
        for (final question in tacticalIdentityQuestions) {
          cubit.selectOption(question.options.first);
          // No-op na última pergunta (`next()` já se protege sozinho).
          cubit.next();
        }
        // Volta e troca a resposta da pergunta 1 múltiplas vezes.
        for (var i = 0; i < tacticalIdentityQuestions.length - 1; i++) {
          cubit.back();
        }
        cubit.selectOption(tacticalIdentityQuestions.first.options[1]);
        cubit.selectOption(tacticalIdentityQuestions.first.options[2]);
        cubit.selectOption(tacticalIdentityQuestions.first.options[3]);
        // Anda de novo até o fim.
        for (var i = 0; i < tacticalIdentityQuestions.length - 1; i++) {
          cubit.next();
        }
        expect(cubit.state.allAnswered, isTrue);
        final answers = cubit.finalAnswers;
        // Exatamente 10 respostas, uma por pergunta — trocar 3 vezes a
        // mesma pergunta nunca duplicou nada na lista final.
        expect(answers.length, tacticalIdentityQuestions.length);
        expect(answers.first.id, tacticalIdentityQuestions.first.options[3].id);
      },
    );
  });

  group('dataset integrity', () {
    test('exactly 12 coach references', () {
      expect(tacticalCoachReferences.length, 12);
    });

    test('exactly 10 questions, each with exactly 4 options', () {
      expect(tacticalIdentityQuestions.length, 10);
      for (final question in tacticalIdentityQuestions) {
        expect(question.options.length, 4);
      }
    });
  });

  group('extremes', () {
    test('maximum POSSE (x = -100)', () {
      final result = engine.computeResult(_answers(List.filled(10, (-2, 0))));
      expect(result.x, -100);
      expect(result.possession, 100);
      expect(result.vertical, 0);
    });

    test('maximum VERTICAL (x = +100)', () {
      final result = engine.computeResult(_answers(List.filled(10, (2, 0))));
      expect(result.x, 100);
      expect(result.possession, 0);
      expect(result.vertical, 100);
    });

    test('maximum DOGMÁTICO (y = -100)', () {
      final result = engine.computeResult(_answers(List.filled(10, (0, -2))));
      expect(result.y, -100);
      expect(result.dogmatic, 100);
      expect(result.pragmatic, 0);
    });

    test('maximum PRAGMÁTICO (y = +100)', () {
      final result = engine.computeResult(_answers(List.filled(10, (0, 2))));
      expect(result.y, 100);
      expect(result.dogmatic, 0);
      expect(result.pragmatic, 100);
    });

    test('center — approximately 0/0', () {
      final result = engine.computeResult(_answers(List.filled(10, (0, 0))));
      expect(result.x, 0);
      expect(result.y, 0);
      expect(result.archetype, TacticalArchetype.equilibradoModerno);
    });

    test('POSSE + PRAGMÁTICO extreme', () {
      final result = engine.computeResult(_answers(List.filled(10, (-2, 2))));
      expect(result.archetype, TacticalArchetype.associativoFlexivel);
    });

    test('VERTICAL + PRAGMÁTICO extreme', () {
      final result = engine.computeResult(_answers(List.filled(10, (2, 2))));
      expect(result.archetype, TacticalArchetype.verticalEstrategico);
    });

    test('POSSE + DOGMÁTICO extreme', () {
      final result = engine.computeResult(_answers(List.filled(10, (-2, -2))));
      expect(result.archetype, TacticalArchetype.controladorConvicto);
    });

    test('VERTICAL + DOGMÁTICO extreme', () {
      final result = engine.computeResult(_answers(List.filled(10, (2, -2))));
      expect(result.archetype, TacticalArchetype.verticalAgressivo);
    });
  });

  test('TacticalIdentityCubit never depends on ranking/score infrastructure — '
      'its constructor takes zero arguments, so it structurally cannot call '
      'ArenaRankingRepository or any equivalent', () {
    final cubit = TacticalIdentityCubit();
    expect(cubit.state.index, 0);
  });
}
