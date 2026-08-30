import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/presentation/layout/lineup_layout_engine.dart';

void main() {
  const engine = LineupLayoutEngine();
  // Larguras realistas de aparelho — a menor (360) já é mais estreita que a
  // maioria dos Android/iPhone em uso. Nunca testar abaixo disso: não existe
  // dispositivo real relevante mais estreito, e não é isso que a regra de
  // "tamanho fixo por breakpoint" precisa garantir.
  const fieldSizes = [Size(360, 562), Size(400, 625), Size(480, 750)];
  const criticalFormationIds = ['4-2-4', '4-1-2-1-2', '4-2-2-2', '3-5-2'];

  bool collides(ResolvedSlotLayout a, ResolvedSlotLayout b) {
    final inflated = a.footprintRect.inflate(
      LineupLayoutEngine.minSafetyGap / 2,
    );
    return inflated.overlaps(b.footprintRect);
  }

  group('resolve — fixed jersey size (regra absoluta)', () {
    for (final fieldSize in fieldSizes) {
      test(
        'every formation uses the exact same jerseySize on a '
        '${fieldSize.width}x${fieldSize.height} field',
        () {
          final sizes = <double>{};
          for (final formation in formations) {
            for (final mode in LineupRenderMode.values) {
              final resolved = engine.resolve(
                formation: formation,
                fieldSize: fieldSize,
                mode: mode,
              );
              for (final layout in resolved) {
                sizes.add(layout.footprint.jerseySize);
              }
            }
          }
          expect(
            sizes,
            hasLength(1),
            reason:
                'jerseySize varied by formation/mode on the same field: $sizes',
          );
        },
      );
    }

    test(
      'a wider field within the same breakpoint tier never shrinks the '
      'jersey — only crossing into a narrower tier does',
      () {
        // 400 e 480 caem no mesmo tier (regular) — o jersey tem que ser
        // idêntico entre eles; só uma largura abaixo do breakpoint (360)
        // pode usar o tier compacto.
        final regularA = engine.resolve(
          formation: formationById('4-3-3'),
          fieldSize: const Size(400, 625),
          mode: LineupRenderMode.crowd,
        );
        final regularB = engine.resolve(
          formation: formationById('4-3-3'),
          fieldSize: const Size(480, 750),
          mode: LineupRenderMode.crowd,
        );
        expect(
          regularA.first.footprint.jerseySize,
          regularB.first.footprint.jerseySize,
        );

        final compact = engine.resolve(
          formation: formationById('4-3-3'),
          fieldSize: const Size(360, 562),
          mode: LineupRenderMode.crowd,
        );
        expect(
          compact.first.footprint.jerseySize,
          lessThan(regularA.first.footprint.jerseySize),
        );
      },
    );

    test(
      'all 11 slots of a formation share the same jerseySize (never per-line)',
      () {
        for (final formation in formations) {
          final resolved = engine.resolve(
            formation: formation,
            fieldSize: const Size(360, 562),
            mode: LineupRenderMode.crowd,
          );
          final sizes = resolved.map((l) => l.footprint.jerseySize).toSet();
          expect(
            sizes,
            hasLength(1),
            reason: '${formation.id}: slots disagree on jerseySize: $sizes',
          );
        }
      },
    );
  });

  group('resolve — safety', () {
    for (final formation in formations) {
      for (final mode in LineupRenderMode.values) {
        for (final fieldSize in fieldSizes) {
          test(
            '${formation.id} ($mode, ${fieldSize.width}x${fieldSize.height}) '
            'has no colliding footprints and stays within the field',
            () {
              final resolved = engine.resolve(
                formation: formation,
                fieldSize: fieldSize,
                mode: mode,
              );
              expect(resolved, hasLength(11));

              for (var i = 0; i < resolved.length; i++) {
                final rect = resolved[i].footprintRect;
                expect(rect.left, greaterThanOrEqualTo(-0.01));
                expect(rect.top, greaterThanOrEqualTo(-0.01));
                expect(rect.right, lessThanOrEqualTo(fieldSize.width + 0.01));
                expect(
                  rect.bottom,
                  lessThanOrEqualTo(fieldSize.height + 0.01),
                );
                for (var j = i + 1; j < resolved.length; j++) {
                  expect(
                    collides(resolved[i], resolved[j]),
                    isFalse,
                    reason:
                        '${formation.id}: slot ${resolved[i].slotIndex} '
                        '(${resolved[i].slot.position}) collides with slot '
                        '${resolved[j].slotIndex} (${resolved[j].slot.position})',
                  );
                }
              }
            },
          );
        }
      }
    }
  });

  group('resolve — shared base between render modes', () {
    for (final id in criticalFormationIds) {
      test('$id: the jersey anchor never moves between crowd and editable', () {
        final formation = formationById(id);
        const fieldSize = Size(360, 562);
        final crowd = engine.resolve(
          formation: formation,
          fieldSize: fieldSize,
          mode: LineupRenderMode.crowd,
        );
        final editable = engine.resolve(
          formation: formation,
          fieldSize: fieldSize,
          mode: LineupRenderMode.editable,
        );

        for (var i = 0; i < formation.slots.length; i++) {
          expect(
            (crowd[i].anchor - editable[i].anchor).distance,
            lessThan(0.5),
            reason: '$id slot $i: anchor moved between render modes',
          );
        }
      });
    }
  });

  group('resolve — regression on previously problematic formations', () {
    for (final id in criticalFormationIds) {
      test('$id resolves cleanly at a typical phone width', () {
        final formation = formationById(id);
        final resolved = engine.resolve(
          formation: formation,
          fieldSize: const Size(360, 562),
          mode: LineupRenderMode.crowd,
        );
        expect(resolved, hasLength(11));
      });
    }
  });

  test('a 100% badge never needs a wider footprint than the reserved cell', () {
    // O footprint reservado (`cellWidth`) já é fixo e generoso o bastante
    // pra "6%"/"87%"/"100%" — a badge nunca decide sozinha a largura do
    // slot, então nunca pode estourá-la.
    final resolved = engine.resolve(
      formation: formationById('4-3-3'),
      fieldSize: const Size(360, 562),
      mode: LineupRenderMode.crowd,
    );
    for (final layout in resolved) {
      expect(layout.footprint.width, greaterThanOrEqualTo(46));
    }
  });

  test(
    'only formations stacking many tactical lines at once fall back to '
    '1-line names — never because of player count within a line',
    () {
      // 4-1-2-1-2 (losango) empilha 6 linhas ao mesmo tempo — é o único
      // caso que precisa ceder a segunda linha do nome pra não violar o
      // safety gap sem encolher a camisa.
      final losango = engine.resolve(
        formation: formationById('4-1-2-1-2'),
        fieldSize: const Size(360, 562),
        mode: LineupRenderMode.crowd,
      );
      expect(losango.first.footprint.nameMaxLines, 1);

      // 5-3-2 e 5-4-1 têm uma linha de 5 jogadores (a mais cheia que
      // existe) mas só 4-5 linhas no total — 2 linhas de nome continuam
      // cabendo.
      final fiveAtBack = engine.resolve(
        formation: formationById('5-3-2'),
        fieldSize: const Size(360, 562),
        mode: LineupRenderMode.crowd,
      );
      expect(fiveAtBack.first.footprint.nameMaxLines, 2);
    },
  );
}
