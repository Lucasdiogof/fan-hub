import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_field_background.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';

/// Campo visto de cima com os 11 slots posicionados pela formação. O
/// conteúdo de cada slot (camisa/nome/%/etc.) vem do [slotBuilder], então o
/// mesmo campo serve pra montar a escalação e pra mostrar a da torcida.
///
/// Em vez de posicionar cada slot livremente pelas coordenadas x/y curadas
/// (que geravam sobreposição em linhas de 4-5 jogadores), agrupamos os
/// slots por linha tática — mesmo `y` (com uma tolerância pequena, já que
/// o dataset varia o y de cada jogador levemente pra um visual mais
/// natural) — e distribuímos cada linha num `Row` de `Expanded`s. Cada
/// jogador ganha um slot só seu: a largura nunca depende do conteúdo, então
/// duas camisas/nomes jamais se sobrepõem, mesmo na linha mais cheia (até 5
/// titulares lado a lado). O índice original de cada slot (usado pelo
/// cubit/estado) é preservado — só a ORDEM DE DESENHO muda, não os dados.
class LineupField extends StatelessWidget {
  const LineupField({
    required this.formation,
    required this.slotBuilder,
    super.key,
  });

  final Formation formation;
  final Widget Function(int slotIndex, FormationSlot slot, double avatarSize)
  slotBuilder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lines = _clusterLines(formation.slots);
          final widestLine = lines.fold(
            0,
            (max, line) => line.length > max ? line.length : max,
          );
          final avatarSize = _avatarSizeFor(widestLine);
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              children: [
                const Positioned.fill(child: LineupFieldBackground()),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final line in lines)
                          Row(
                            children: [
                              for (final entry in line)
                                Expanded(
                                  child: Center(
                                    child: slotBuilder(
                                      entry.$1,
                                      entry.$2,
                                      avatarSize,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
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

  /// Linhas mais cheias precisam de camisas menores pra caber com folga.
  double _avatarSizeFor(int playersInLine) => switch (playersInLine) {
    <= 2 => 54,
    3 => 50,
    4 => 46,
    _ => 42,
  };

  /// Agrupa slots (guardando o índice original) por linha tática: ordena
  /// por `y` e encadeia num mesmo grupo enquanto o salto pro próximo `y`
  /// for pequeno — funciona tanto pra linhas com o mesmo `y` exato quanto
  /// pras levemente escalonadas (ex.: zagueiros centrais um pouco mais
  /// baixos que os laterais na mesma linha defensiva).
  List<List<(int, FormationSlot)>> _clusterLines(List<FormationSlot> slots) {
    const threshold = 0.07;
    final indexed = [for (var i = 0; i < slots.length; i++) (i, slots[i])]
      ..sort((a, b) => a.$2.y.compareTo(b.$2.y));

    final lines = <List<(int, FormationSlot)>>[];
    for (final entry in indexed) {
      if (lines.isEmpty || entry.$2.y - lines.last.last.$2.y > threshold) {
        lines.add([entry]);
      } else {
        lines.last.add(entry);
      }
    }
    for (final line in lines) {
      line.sort((a, b) => a.$2.x.compareTo(b.$2.x));
    }
    return lines;
  }
}
