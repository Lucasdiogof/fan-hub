import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_field_background.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/presentation/layout/lineup_layout_engine.dart';

/// Campo visto de cima com os 11 slots posicionados pela [LineupLayoutEngine]
/// — este widget não calcula mais posição nenhuma sozinho, só desenha o que
/// a engine resolveu. O conteúdo de cada slot (camisa/nome/%/etc.) vem do
/// [slotBuilder], então o mesmo campo serve pra montar a escalação
/// ([LineupRenderMode.editable]) e pra mostrar a da torcida
/// ([LineupRenderMode.crowd]) sem duplicar layout entre os dois.
class LineupField extends StatelessWidget {
  const LineupField({
    required this.formation,
    required this.mode,
    required this.slotBuilder,
    super.key,
  });

  final Formation formation;
  final LineupRenderMode mode;
  final Widget Function(
    int slotIndex,
    FormationSlot slot,
    PlayerVisualFootprint footprint,
  )
  slotBuilder;

  static const _engine = LineupLayoutEngine();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
          final resolved = _engine.resolve(
            formation: formation,
            fieldSize: fieldSize,
            mode: mode,
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              children: [
                const Positioned.fill(child: LineupFieldBackground()),
                for (final layout in resolved)
                  Positioned(
                    left: layout.anchor.dx - layout.footprint.width / 2,
                    top: layout.anchor.dy - layout.footprint.height / 2,
                    width: layout.footprint.width,
                    height: layout.footprint.height,
                    child: Center(
                      child: slotBuilder(
                        layout.slotIndex,
                        layout.slot,
                        layout.footprint,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
