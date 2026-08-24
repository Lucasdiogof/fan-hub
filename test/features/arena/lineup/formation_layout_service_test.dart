import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/lineup/formation_layout_service.dart';

void main() {
  group('FormationLayoutService', () {
    test('gera 11 posições pra cada formação catalogada', () {
      for (final formation in [
        '4-4-2',
        '4-3-3',
        '3-5-2',
        '4-2-3-1',
        '4-1-2-1-2',
        '5-3-2',
        '3-4-3',
        '4-5-1',
      ]) {
        expect(
          FormationLayoutService.positionsFor(formation).length,
          11,
          reason: formation,
        );
      }
    });

    test('todas as coordenadas ficam dentro de 0.0–1.0', () {
      for (final position in FormationLayoutService.positionsFor('4-3-3')) {
        expect(position.dx, inInclusiveRange(0.0, 1.0));
        expect(position.dy, inInclusiveRange(0.0, 1.0));
      }
    });

    test('goleiro fica na linha mais próxima do próprio gol (y mais alto)', () {
      final positions = FormationLayoutService.positionsFor('4-4-2');
      final goalkeeperY = positions.first.dy;
      for (final position in positions.skip(1)) {
        expect(goalkeeperY, greaterThan(position.dy));
      }
    });

    test(
      'formação desconhecida cai num fallback igualmente distribuído, sem quebrar',
      () {
        final positions = FormationLayoutService.positionsFor('4-4-1-1');
        expect(positions.length, 11);
      },
    );
  });
}
