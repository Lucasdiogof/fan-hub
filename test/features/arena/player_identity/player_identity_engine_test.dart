import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_cubit.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_engine.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_references.dart';

const _c = PlayerIdentityDimension.creativity;
const _d = PlayerIdentityDimension.definition;
const _l = PlayerIdentityDimension.leadership;
const _t = PlayerIdentityDimension.technique;

PlayerIdentityOption _optionFor(PlayerIdentityDimension dimension) {
  // Pega a primeira alternativa do banco real cuja dimensão PRIMÁRIA bate,
  // pra qualquer teste que precise "uma resposta que pontue X" continuar
  // válido mesmo se o texto das perguntas mudar — só a estrutura de pontos
  // importa aqui.
  for (final question in playerIdentityQuestions) {
    for (final option in question.options) {
      if (option.primary == dimension) return option;
    }
  }
  throw StateError('no option found for $dimension');
}

void main() {
  final engine = PlayerIdentityEngine(playerIdentityReferences);

  group('dataset integrity', () {
    test('exactly 21 player references', () {
      expect(playerIdentityReferences.length, 21);
    });

    test('exactly 10 questions, each with exactly 4 options', () {
      expect(playerIdentityQuestions.length, 10);
      for (final question in playerIdentityQuestions) {
        expect(question.options.length, 4);
      }
    });

    test(
      'every option contributes to two DIFFERENT dimensions (primary != secondary)',
      () {
        for (final question in playerIdentityQuestions) {
          for (final option in question.options) {
            expect(option.primary, isNot(option.secondary));
          }
        }
      },
    );

    test('question 7 option D is the documented +2/+2 split', () {
      final q7d = playerIdentityQuestions[6].options[3];
      expect(q7d.primaryPoints, 2);
      expect(q7d.secondaryPoints, 2);
    });

    test('every other option follows the default +3/+1 split', () {
      for (var qi = 0; qi < playerIdentityQuestions.length; qi++) {
        for (
          var oi = 0;
          oi < playerIdentityQuestions[qi].options.length;
          oi++
        ) {
          if (qi == 6 && oi == 3) continue; // a exceção documentada acima.
          final option = playerIdentityQuestions[qi].options[oi];
          expect(option.primaryPoints, 3);
          expect(option.secondaryPoints, 1);
        }
      }
    });
  });

  group('rawScore', () {
    test(
      'sums only the contributions of the selected answers for a dimension',
      () {
        final answers = [_optionFor(_c), _optionFor(_c), _optionFor(_d)];
        final raw = engine.rawScore(answers, _c);
        // As duas primeiras contribuem +3 (primária) pra criatividade; a
        // terceira só contribui se sua secundária também for criatividade —
        // como pegamos por primária, isso não é garantido, então só
        // verificamos o piso: pelo menos as duas primárias contam.
        expect(raw, greaterThanOrEqualTo(6));
      },
    );

    test('empty answers score zero on every dimension', () {
      for (final dimension in PlayerIdentityDimension.values) {
        expect(engine.rawScore(const [], dimension), 0);
      }
    });
  });

  group('maxPossibleScore', () {
    test('is NOT a flat /30 — varies per dimension', () {
      final scores = {
        for (final dimension in PlayerIdentityDimension.values)
          dimension: engine.maxPossibleScore(dimension),
      };
      // Pelo menos duas dimensões devem ter tetos diferentes — se todas
      // fossem iguais, seria sinal de um /30 fixo disfarçado.
      expect(scores.values.toSet().length, greaterThan(1));
    });

    test('equals, for each question, the best single contribution summed', () {
      for (final dimension in PlayerIdentityDimension.values) {
        var expected = 0;
        for (final question in playerIdentityQuestions) {
          var best = 0;
          for (final option in question.options) {
            var contribution = 0;
            if (option.primary == dimension) {
              contribution += option.primaryPoints;
            }
            if (option.secondary == dimension) {
              contribution += option.secondaryPoints;
            }
            if (contribution > best) best = contribution;
          }
          expected += best;
        }
        expect(engine.maxPossibleScore(dimension), expected);
      }
    });
  });

  group('normalizedScore — 25–100 bounds', () {
    test('zero raw score normalizes to the floor, 25', () {
      expect(engine.normalizedScore(0, 30), 25);
    });

    test('max possible raw score normalizes to the ceiling, 100', () {
      expect(engine.normalizedScore(30, 30), 100);
    });

    test('never produces anything below 25 for a real dimension', () {
      for (final dimension in PlayerIdentityDimension.values) {
        final max = engine.maxPossibleScore(dimension);
        expect(engine.normalizedScore(0, max), 25);
      }
    });

    test('never produces anything above 100 for a real dimension', () {
      for (final dimension in PlayerIdentityDimension.values) {
        final max = engine.maxPossibleScore(dimension);
        expect(engine.normalizedScore(max, max), 100);
      }
    });

    test(
      'a dimension with zero opportunities defaults to the floor, never a crash',
      () {
        expect(engine.normalizedScore(0, 0), 25);
      },
    );
  });

  group('distanceTo — RMS in standardized (z-score) space', () {
    test('a single-dimension difference produces a positive distance', () {
      // Não dá mais pra prever o valor exato sem reproduzir
      // mean/stdDev das 21 referências aqui (a distância agora é em
      // z-score, não na escala bruta 25-100) — só verificamos a forma:
      // diferença em UMA dimensão só produz distância positiva, e maior
      // que diferença zero.
      const attributes = PlayerIdentityAttributes(
        creativity: 50,
        definition: 50,
        leadership: 50,
        intensity: 50,
        technique: 50,
        tactics: 50,
      );
      const reference = PlayerIdentityReference(
        id: 'ref',
        name: 'Ref',
        period: '2000',
        creativity: 56,
        definition: 50,
        leadership: 50,
        intensity: 50,
        technique: 50,
        tactics: 50,
        confidence: 'high',
      );
      expect(engine.distanceTo(attributes, reference), greaterThan(0));
    });

    test('distance to an identical vector is zero', () {
      const attributes = PlayerIdentityAttributes(
        creativity: 70,
        definition: 60,
        leadership: 80,
        intensity: 55,
        technique: 65,
        tactics: 75,
      );
      const reference = PlayerIdentityReference(
        id: 'ref',
        name: 'Ref',
        period: '2000',
        creativity: 70,
        definition: 60,
        leadership: 80,
        intensity: 55,
        technique: 65,
        tactics: 75,
        confidence: 'high',
      );
      expect(engine.distanceTo(attributes, reference), 0);
    });
  });

  group('rankReferences / closestReferences', () {
    const attributes = PlayerIdentityAttributes(
      creativity: 60,
      definition: 60,
      leadership: 60,
      intensity: 60,
      technique: 60,
      tactics: 60,
    );

    test('rankReferences sorts all 21 references from nearest to farthest', () {
      final ranked = engine.rankReferences(attributes);
      expect(ranked.length, 21);
      for (var i = 1; i < ranked.length; i++) {
        expect(
          ranked[i].distance,
          greaterThanOrEqualTo(ranked[i - 1].distance),
        );
      }
    });

    test(
      'closestReferences returns exactly the top 3, matching rankReferences',
      () {
        final top3 = engine.closestReferences(attributes);
        expect(top3.length, 3);
        final ranked = engine.rankReferences(attributes);
        expect(
          top3.map((a) => a.reference.id),
          ranked.take(3).map((a) => a.reference.id),
        );
      },
    );
  });

  group('affinityFor — 40–98 bounds', () {
    test('never goes below 40, no matter how large the distance', () {
      // Distância é em espaço padronizado (z-score), sem um "máximo
      // teórico" fixo — mas a curva exp(-k*distance) satura pro piso pra
      // qualquer distância grande o bastante.
      expect(engine.affinityFor(75), 40);
      expect(engine.affinityFor(1000), 40);
    });

    test('never goes above 98, even at distance zero', () {
      expect(engine.affinityFor(0), 98);
    });
  });

  group('classifyArchetype', () {
    test('picks the dimension with the highest score', () {
      const attributes = PlayerIdentityAttributes(
        creativity: 90,
        definition: 50,
        leadership: 50,
        intensity: 50,
        technique: 50,
        tactics: 50,
      );
      expect(
        engine.classifyArchetype(attributes),
        PlayerIdentityArchetype.creativity,
      );
    });

    test(
      'tie-break: liderança beats tática beats criatividade, in that order',
      () {
        const tieLeadershipTactics = PlayerIdentityAttributes(
          creativity: 45,
          definition: 45,
          leadership: 90,
          intensity: 45,
          technique: 45,
          tactics: 90,
        );
        expect(
          engine.classifyArchetype(tieLeadershipTactics),
          PlayerIdentityArchetype.leadership,
        );

        const tieTacticsCreativity = PlayerIdentityAttributes(
          creativity: 90,
          definition: 45,
          leadership: 45,
          intensity: 45,
          technique: 45,
          tactics: 90,
        );
        expect(
          engine.classifyArchetype(tieTacticsCreativity),
          PlayerIdentityArchetype.tactics,
        );
      },
    );

    test(
      '"O Completo": max - min <= 8 overrides whichever dimension would win',
      () {
        const flat = PlayerIdentityAttributes(
          creativity: 70,
          definition: 72,
          leadership: 74,
          intensity: 68,
          technique: 71,
          tactics: 69,
        );
        expect(
          engine.classifyArchetype(flat),
          PlayerIdentityArchetype.complete,
        );
      },
    );

    test('a 9-point spread is NOT flat enough for "O Completo"', () {
      const almostFlat = PlayerIdentityAttributes(
        creativity: 70,
        definition: 61,
        leadership: 65,
        intensity: 65,
        technique: 65,
        tactics: 65,
      );
      expect(
        engine.classifyArchetype(almostFlat),
        isNot(PlayerIdentityArchetype.complete),
      );
    });
  });

  group('topTraits', () {
    test('returns the three highest dimensions, highest first', () {
      const attributes = PlayerIdentityAttributes(
        creativity: 95,
        definition: 50,
        leadership: 90,
        intensity: 45,
        technique: 85,
        tactics: 60,
      );
      expect(engine.topTraits(attributes), [_c, _l, _t]);
    });
  });

  group('computeResult — determinism and no accumulation', () {
    test('the same 10 answers always produce the same result', () {
      final answers = [
        for (final q in playerIdentityQuestions) q.options.first,
      ];
      final first = engine.computeResult(answers);
      final second = engine.computeResult(answers);
      expect(first.attributes.creativity, second.attributes.creativity);
      expect(first.archetype, second.archetype);
      expect(
        first.closestReferences.map((a) => a.reference.id),
        second.closestReferences.map((a) => a.reference.id),
      );
    });

    test(
      'going back and picking a different option for one question never '
      'accumulates on top of the old one — only the final 10 answers count',
      () {
        final cubit = PlayerIdentityCubit();
        for (final question in playerIdentityQuestions) {
          cubit.selectOption(question.options.first);
          cubit.next();
        }
        for (var i = 0; i < playerIdentityQuestions.length - 1; i++) {
          cubit.back();
        }
        cubit.selectOption(playerIdentityQuestions.first.options[1]);
        cubit.selectOption(playerIdentityQuestions.first.options[2]);
        cubit.selectOption(playerIdentityQuestions.first.options[3]);
        for (var i = 0; i < playerIdentityQuestions.length - 1; i++) {
          cubit.next();
        }
        expect(cubit.state.allAnswered, isTrue);
        final answers = cubit.finalAnswers;
        expect(answers.length, playerIdentityQuestions.length);
        expect(answers.first.id, playerIdentityQuestions.first.options[3].id);
      },
    );
  });

  test('PlayerIdentityCubit never depends on ranking/score infrastructure — '
      'its constructor takes zero arguments, so it structurally cannot call '
      'ArenaRankingRepository or any equivalent', () {
    final cubit = PlayerIdentityCubit();
    expect(cubit.state.index, 0);
  });
}
