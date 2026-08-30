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

  static const _minAvatarSize = 30.0;
  static const _minCellWidth = 46.0;
  static const _labelAllowance = 26.0;

  // Fração do espaço real disponível que a célula pode ocupar — sobra
  // sempre uma folga visível entre linhas/jogadores vizinhos, nunca
  // encostando exatamente na distância mínima calculada.
  static const _verticalSafety = 0.85;
  static const _horizontalSafety = 0.82;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lines = _groupIntoLines(formation.slots);
          final widestLine = lines
              .map((line) => line.length)
              .reduce((a, b) => a > b ? a : b);
          // Assimétrico de propósito: a linha de cima (ataque) é a mais
          // alta — camisa + selo/percentual — e sem essa margem extra ela
          // estourava o `ClipRRect` do campo (jogador "saindo de campo"). A
          // de baixo (goleiro) não tem esse problema, por isso a folga ali
          // é bem menor.
          const topInset = AppSpacing.xxl + 8;
          const bottomInset = AppSpacing.sm + 4;
          final innerHeight = constraints.maxHeight - topInset - bottomInset;

          // O tamanho "ideal" (baseado só na linha mais cheia) presumia que
          // toda formação tem a mesma quantidade de linhas — não tem (o
          // 4-1-2-1-2, por ex., empilha 6 contra as 4-5 de formações mais
          // simples). Aqui a célula nunca passa do que o menor espaço
          // vertical/horizontal *real* entre linhas/jogadores comporta,
          // senão camisas de linhas vizinhas se tocam ou se sobrepõem —
          // ver [[project_goias_app_crowd_lineup_feature]].
          final idealAvatarSize = _avatarSizeFor(widestLine);
          final minLineGapFraction = _minLineGap(lines);
          final maxAvatarSizeByHeight =
              minLineGapFraction * innerHeight * _verticalSafety -
              _labelAllowance;
          final avatarSize = idealAvatarSize <= maxAvatarSizeByHeight
              ? idealAvatarSize
              : _clampD(maxAvatarSizeByHeight, _minAvatarSize, idealAvatarSize);
          final cellHeight = avatarSize + _labelAllowance;

          final idealCellWidth = _cellWidthFor(widestLine);
          final minSlotGapFraction = _minSlotGap(lines);
          final maxCellWidthByWidth =
              minSlotGapFraction * constraints.maxWidth * _horizontalSafety;
          final cellWidth = idealCellWidth <= maxCellWidthByWidth
              ? idealCellWidth
              : _clampD(maxCellWidthByWidth, _minCellWidth, idealCellWidth);

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

  /// Agrupa slots por `y` próximo (mesma linha tática, com tolerância pra
  /// variações leves de y dentro da mesma linha) — mesmo critério usado
  /// tanto pra dimensionar quanto pra saber o espaço real entre linhas.
  List<List<FormationSlot>> _groupIntoLines(List<FormationSlot> slots) {
    const threshold = 0.07;
    final sorted = [...slots]..sort((a, b) => a.y.compareTo(b.y));
    final lines = <List<FormationSlot>>[];
    for (final slot in sorted) {
      if (lines.isNotEmpty && slot.y - lines.last.last.y <= threshold) {
        lines.last.add(slot);
      } else {
        lines.add([slot]);
      }
    }
    return lines;
  }

  /// Menor distância vertical entre duas linhas táticas vizinhas (usa a
  /// média de `y` de cada linha como sua posição representativa).
  double _minLineGap(List<List<FormationSlot>> lines) {
    if (lines.length < 2) return 1;
    final ys = [
      for (final line in lines)
        line.map((s) => s.y).reduce((a, b) => a + b) / line.length,
    ];
    var minGap = double.infinity;
    for (var i = 1; i < ys.length; i++) {
      final gap = ys[i] - ys[i - 1];
      if (gap < minGap) minGap = gap;
    }
    return minGap;
  }

  /// Menor distância horizontal entre dois jogadores vizinhos dentro da
  /// MESMA linha (linhas diferentes não competem por espaço horizontal).
  double _minSlotGap(List<List<FormationSlot>> lines) {
    var minGap = double.infinity;
    for (final line in lines) {
      if (line.length < 2) continue;
      final xs = [for (final slot in line) slot.x]..sort();
      for (var i = 1; i < xs.length; i++) {
        final gap = xs[i] - xs[i - 1];
        if (gap < minGap) minGap = gap;
      }
    }
    return minGap.isFinite ? minGap : 1;
  }

  double _clampD(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);
}
