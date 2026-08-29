import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_field_background.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';

/// Campo visto de cima com os 11 slots posicionados pela formação. O
/// conteúdo de cada slot (camisa/nome/%/etc.) vem do [slotBuilder], então o
/// mesmo campo serve pra montar a escalação e pra mostrar a da torcida.
///
/// Cada slot é desenhado exatamente na coordenada x/y curada da formação
/// (fração 0..1 do campo) — nunca por "linha do meio pra baixo" genérico.
/// Isso é o que faz um half-space (ex.: os MEI do 4-2-2-2, x=0.35/0.65)
/// ficar visivelmente mais estreito que uma ponta aberta (PE/PD, x~0.18/0.82)
/// em vez de as duas renderizarem no mesmo lugar só porque "são a mesma
/// linha". O tamanho da célula (camisa + rótulo) é fixo em dp, não em
/// fração, pra nunca esticar/cortar o conteúdo — só sua POSIÇÃO central é
/// normalizada. Cada célula é presa dentro da área do campo (nunca deixa a
/// camisa sair pela borda) via clamp na coordenada central.
class LineupField extends StatelessWidget {
  const LineupField({
    required this.formation,
    required this.slotBuilder,
    super.key,
  });

  final Formation formation;
  final Widget Function(
    int slotIndex,
    FormationSlot slot,
    double avatarSize,
    double cellWidth,
  )
  slotBuilder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widestLine = _widestLineCount(formation.slots);
          final avatarSize = _avatarSizeFor(widestLine);
          final cellWidth = _cellWidthFor(widestLine);
          final cellHeight = avatarSize + 26;
          // Assimétrico de propósito: a linha de cima (ataque) é a mais
          // alta — camisa + selo/percentual — e sem essa margem extra ela
          // estourava o `ClipRRect` do campo (jogador "saindo de campo"). A
          // de baixo (goleiro) não tem esse problema, por isso a folga ali
          // é bem menor.
          const topInset = AppSpacing.xxl + 8;
          const bottomInset = AppSpacing.sm + 4;
          final innerHeight = constraints.maxHeight - topInset - bottomInset;

          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              children: [
                const Positioned.fill(child: LineupFieldBackground()),
                for (var i = 0; i < formation.slots.length; i++)
                  _positionedSlot(
                    slot: formation.slots[i],
                    fieldWidth: constraints.maxWidth,
                    topInset: topInset,
                    innerHeight: innerHeight,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
                    child: slotBuilder(
                      i,
                      formation.slots[i],
                      avatarSize,
                      cellWidth,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _positionedSlot({
    required FormationSlot slot,
    required double fieldWidth,
    required double topInset,
    required double innerHeight,
    required double cellWidth,
    required double cellHeight,
    required Widget child,
  }) {
    final halfW = cellWidth / 2;
    final halfH = cellHeight / 2;
    final centerX = (slot.x * fieldWidth).clamp(halfW, fieldWidth - halfW);
    final centerY = (topInset + slot.y * innerHeight).clamp(
      topInset + halfH,
      topInset + innerHeight - halfH,
    );
    return Positioned(
      left: centerX - halfW,
      top: centerY - halfH,
      width: cellWidth,
      height: cellHeight,
      child: Center(child: child),
    );
  }

  /// Linhas mais cheias precisam de camisas (e rótulos) menores pra caber
  /// com folga — usado só pra dimensionar, nunca pra posicionar.
  double _avatarSizeFor(int playersInLine) => switch (playersInLine) {
    <= 2 => 54,
    3 => 50,
    4 => 46,
    _ => 42,
  };

  /// Largura da célula (camisa + rótulo do nome) — precisa encolher junto
  /// com a camisa nas linhas mais cheias (ex.: a linha de 5 zagueiros do
  /// 5-3-2/5-4-1), senão os rótulos de slots vizinhos se tocam.
  double _cellWidthFor(int playersInLine) => switch (playersInLine) {
    <= 2 => 84,
    3 => 78,
    4 => 70,
    _ => 60,
  };

  /// Só pra dimensionar (ver acima), não pra posicionar: agrupa slots por
  /// `y` próximo (mesma linha tática, com tolerância pra variações leves de
  /// y dentro da mesma linha) e devolve o tamanho da linha mais cheia.
  int _widestLineCount(List<FormationSlot> slots) {
    const threshold = 0.07;
    final ys = [for (final slot in slots) slot.y]..sort();
    var widest = 1;
    var current = 1;
    for (var i = 1; i < ys.length; i++) {
      if (ys[i] - ys[i - 1] <= threshold) {
        current++;
      } else {
        current = 1;
      }
      if (current > widest) widest = current;
    }
    return widest;
  }
}
