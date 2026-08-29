import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/shared/domain/player_position.dart';

int _count(Formation formation, PlayerPosition position) =>
    formation.slots.where((slot) => slot.position == position).length;

void main() {
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

      // Uma escalação é uma representação visual, não um mapa de calor —
      // os 10 jogadores de linha precisam ocupar o campo de verdade, não
      // ficar todos espremidos perto da própria defesa. Trava a faixa
      // vertical pra este bug (time inteiro recuado) não voltar.
      test(
        '${formation.id} spreads its 10 outfield players from attack to defense',
        () {
          final outfield = formation.slots.where(
            (s) => s.position != PlayerPosition.gol,
          );
          expect(outfield, hasLength(10));
          for (final slot in outfield) {
            expect(
              slot.y,
              inInclusiveRange(0.15, 0.72),
              reason: '${formation.id}: ${slot.position} at y=${slot.y}',
            );
          }
          final mostAdvanced = outfield
              .map((s) => s.y)
              .reduce((a, b) => a < b ? a : b);
          expect(
            mostAdvanced,
            lessThan(0.25),
            reason: '${formation.id}: front line must reach near the box',
          );
        },
      );

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
          expect(gol.y, inInclusiveRange(0.8, 0.95));
        },
      );
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
