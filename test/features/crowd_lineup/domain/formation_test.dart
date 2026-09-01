import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/shared/domain/player_position.dart';

int _count(Formation formation, PlayerPosition position) =>
    formation.slots.where((slot) => slot.position == position).length;

void main() {
  group('distributeLine', () {
    test('a single player is always centered', () {
      expect(distributeLine(1, 0.3), [0.5]);
    });

    test('spreads N players evenly within [0.5-halfSpan, 0.5+halfSpan]', () {
      expect(distributeLine(2, 0.2), [0.3, 0.7]);
      expect(distributeLine(3, 0.2), [0.3, 0.5, 0.7]);
      expect(distributeLine(4, 0.36), [0.14, 0.38, 0.62, 0.86]);
    });
  });

  group('every formation', () {
    for (final formation in formations) {
      test('${formation.id} has exactly 11 slots, 1 of them GOL', () {
        expect(formation.slots, hasLength(11));
        expect(_count(formation, PlayerPosition.gol), 1);
      });

      test('${formation.id} has no duplicate slot coordinates', () {
        final coords = formation.slots.map((s) => (s.x, s.y)).toSet();
        expect(coords, hasLength(formation.slots.length));
      });

      test('${formation.id} keeps every coordinate within 0..1', () {
        for (final slot in formation.slots) {
          expect(slot.x, inInclusiveRange(0.0, 1.0));
          expect(slot.y, inInclusiveRange(0.0, 1.0));
        }
      });

      // A escalação precisa ocupar o campo de verdade — os 10 jogadores de
      // linha vivem entre a banda de ataque e a de defesa, nunca espremidos
      // perto da própria defesa nem enfiados na linha de fundo adversária.
      test(
        '${formation.id} spreads its 10 outfield players between the attack and defense bands',
        () {
          final outfield = formation.slots.where(
            (s) => s.position != PlayerPosition.gol,
          );
          expect(outfield, hasLength(10));
          for (final slot in outfield) {
            expect(
              slot.y,
              inInclusiveRange(0.18, 0.73),
              reason: '${formation.id}: ${slot.position} at y=${slot.y}',
            );
          }
        },
      );

      test('${formation.id} keeps its attack line advanced (y 0.18–0.22)', () {
        final attackers = formation.slots.where(
          (s) => s.line == TacticalLine.attack,
        );
        expect(attackers, isNotEmpty);
        for (final slot in attackers) {
          expect(slot.y, inInclusiveRange(0.18, 0.22));
        }
      });

      test(
        '${formation.id} keeps the goalkeeper clearly behind the defense',
        () {
          final gol = formation.slots.firstWhere(
            (s) => s.position == PlayerPosition.gol,
          );
          final defenseY = formation.slots
              .where((s) => s.position != PlayerPosition.gol)
              .map((s) => s.y)
              .reduce((a, b) => a > b ? a : b);
          expect(gol.y, greaterThan(defenseY));
          expect(gol.y, inInclusiveRange(0.86, 0.90));
        },
      );

      // Regressão pro bug reportado repetidas vezes: linhas táticas vizinhas
      // desenhadas perto demais. Agora `TacticalLine` é o agrupamento (não
      // mais uma heurística de "y próximo"), então qualquer par de linhas
      // PRESENTES na formação precisa manter esse respiro.
      test(
        '${formation.id} keeps a safe vertical gap between tactical lines',
        () {
          final byLine = <TacticalLine, double>{};
          for (final slot in formation.slots) {
            byLine[slot.line] = slot.y;
          }
          final ys = byLine.values.toList()..sort();
          for (var i = 1; i < ys.length; i++) {
            expect(
              ys[i] - ys[i - 1],
              greaterThanOrEqualTo(0.11),
              reason:
                  '${formation.id}: lines at y≈${ys[i - 1]} and '
                  'y≈${ys[i]} are too close',
            );
          }
        },
      );

      test('${formation.id} keeps a safe horizontal gap within each line', () {
        final byLine = <TacticalLine, List<double>>{};
        for (final slot in formation.slots) {
          byLine.putIfAbsent(slot.line, () => []).add(slot.x);
        }
        for (final xs in byLine.values) {
          if (xs.length < 2) continue;
          xs.sort();
          for (var i = 1; i < xs.length; i++) {
            expect(
              xs[i] - xs[i - 1],
              greaterThanOrEqualTo(0.13),
              reason:
                  '${formation.id}: slots at x=${xs[i - 1]} and '
                  'x=${xs[i]} on the same line are too close',
            );
          }
        }
      });

      // A ordem tática do campo (ataque → goleiro) precisa ser respeitada
      // por toda linha presente na formação, não só nas extremidades.
      test('${formation.id} orders its tactical lines correctly', () {
        final byLine = <TacticalLine, double>{};
        for (final slot in formation.slots) {
          byLine[slot.line] = slot.y;
        }
        final present = TacticalLine.values.where(byLine.containsKey).toList();
        for (var i = 1; i < present.length; i++) {
          expect(
            byLine[present[i]],
            greaterThan(byLine[present[i - 1]]!),
            reason:
                '${formation.id}: ${present[i - 1]} should be in front of '
                '${present[i]}',
          );
        }
      });
    }
  });

  test(
    '4-2-2-2 is 1 GOL + 4 defenders + 2 VOL + 2 MEI (half-space) + 2 ATA',
    () {
      final formation = formationById('4-2-2-2');
      expect(_count(formation, PlayerPosition.gol), 1);
      expect(_count(formation, PlayerPosition.le), 1);
      expect(_count(formation, PlayerPosition.ld), 1);
      expect(_count(formation, PlayerPosition.zag), 2);
      expect(_count(formation, PlayerPosition.vol), 2);
      expect(_count(formation, PlayerPosition.mei), 2);
      expect(_count(formation, PlayerPosition.ata), 2);
      expect(_count(formation, PlayerPosition.pe), 0);
      expect(_count(formation, PlayerPosition.pd), 0);

      // As duas MEI ficam nos half-spaces (mais estreitas que uma ponta
      // aberta) — era exatamente isto que faltava antes desta reestruturação.
      final meiXs =
          formation.slots
              .where((s) => s.position == PlayerPosition.mei)
              .map((s) => s.x)
              .toList()
            ..sort();
      expect(meiXs[0], greaterThan(0.25));
      expect(meiXs[1], lessThan(0.75));

      // Os dois ATA ficam próximos do centro, não abertos feito pontas.
      final ataXs =
          formation.slots
              .where((s) => s.position == PlayerPosition.ata)
              .map((s) => s.x)
              .toList()
            ..sort();
      expect(ataXs[0], greaterThan(0.25));
      expect(ataXs[1], lessThan(0.75));
    },
  );

  test('4-2-4 puts PE/ATA/ATA/PD nearly on the same front line', () {
    final formation = formationById('4-2-4');
    final frontLine = formation.slots.where(
      (s) => [
        PlayerPosition.pe,
        PlayerPosition.ata,
        PlayerPosition.pd,
      ].contains(s.position),
    );
    expect(frontLine, hasLength(4));
    final ys = frontLine.map((s) => s.y).toList();
    final spread =
        ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b);
    expect(spread, lessThan(0.06));
  });

  test('4-4-2 uses ME/MD wide midfielders, never PE/PD', () {
    final formation = formationById('4-4-2');
    expect(_count(formation, PlayerPosition.me), 1);
    expect(_count(formation, PlayerPosition.md), 1);
    expect(_count(formation, PlayerPosition.pe), 0);
    expect(_count(formation, PlayerPosition.pd), 0);
    expect(_count(formation, PlayerPosition.ata), 2);
  });

  test('3-5-2 has a back three, two alas and no LD/LE', () {
    final formation = formationById('3-5-2');
    expect(_count(formation, PlayerPosition.zag), 3);
    expect(_count(formation, PlayerPosition.ald), 1);
    expect(_count(formation, PlayerPosition.ale), 1);
    expect(_count(formation, PlayerPosition.ld), 0);
    expect(_count(formation, PlayerPosition.le), 0);
  });

  test(
    'formations offered to the user no longer include the retired shapes',
    () {
      const retiredIds = {
        '4-5-1',
        '4-1-3-2',
        '4-3-1-2',
        '3-4-1-2',
        '4-4-1-1',
        '4-1-2-3',
      };
      final currentIds = formations.map((f) => f.id).toSet();
      expect(currentIds.intersection(retiredIds), isEmpty);
      expect(formations, hasLength(12));
    },
  );

  test('formationById still resolves a retired id for old stored votes', () {
    final legacy = formationById('4-5-1');
    expect(legacy.id, '4-5-1');
    expect(legacy.slots, hasLength(11));
  });

  test('formationById falls back to the first formation for an unknown id', () {
    expect(formationById('unknown').id, formations.first.id);
  });
}
