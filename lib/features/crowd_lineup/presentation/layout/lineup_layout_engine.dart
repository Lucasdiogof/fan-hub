import 'package:flutter/widgets.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';

/// O que muda entre "Escalação da Torcida" e "Escale" é só a renderização —
/// a engine devolve o MESMO `anchor` (centro da camisa) pros dois modos,
/// nunca reposiciona por causa do overlay. Só o `footprint` (espaço
/// reservado) muda, porque a badge de porcentagem (crowd) e o botão de
/// remover (editable) ocupam espaços diferentes.
enum LineupRenderMode { crowd, editable }

/// Espaço visual que UM jogador renderizado ocupa de verdade — camisa, nome
/// e (conforme o modo) badge de porcentagem ou botão de remover. É a base
/// do cálculo anti-colisão: dois jogadores nunca podem ter `footprint`s que
/// se sobrepõem além do `LineupLayoutEngine.minSafetyGap`.
class PlayerVisualFootprint {
  const PlayerVisualFootprint({
    required this.jerseySize,
    required this.width,
    required this.height,
    required this.nameMaxLines,
  });

  final double jerseySize;
  final double width;
  final double height;

  /// 1 ou 2 — quantas linhas o nome pode usar. Cai pra 1 só quando a
  /// formação empilha tantas linhas táticas ao mesmo tempo (ex.: o losango
  /// do 4-1-2-1-2, com 6) que não sobra altura pra 2 linhas SEM encolher a
  /// camisa — e a camisa nunca encolhe. Rótulo/nome cede espaço primeiro,
  /// exatamente a prioridade pedida.
  final int nameMaxLines;
}

/// Resultado final e completo de UM slot: onde a camisa fica (`anchor`,
/// sempre o centro dela — nome/badge nunca deslocam isto) e quanto espaço
/// reservar ao redor (`footprint`, já com folga suficiente pra nome/badge
/// caberem sem colidir com o vizinho).
class ResolvedSlotLayout {
  const ResolvedSlotLayout({
    required this.slotIndex,
    required this.slot,
    required this.anchor,
    required this.footprint,
  });

  final int slotIndex;
  final FormationSlot slot;
  final Offset anchor;
  final PlayerVisualFootprint footprint;

  Rect get footprintRect => Rect.fromCenter(
    center: anchor,
    width: footprint.width,
    height: footprint.height,
  );
}

/// Engine única de posicionamento pro campo da Escalação da Torcida e da
/// aba Escale.
///
/// Regra absoluta: **o tamanho da camisa é fixo por breakpoint de largura
/// do campo — nunca por formação, nunca por quantos jogadores existem na
/// linha mais cheia.** 4-3-3, 4-2-4, 3-5-2 e 5-4-1 no mesmo aparelho sempre
/// desenham a camisa do mesmo tamanho; o que muda entre eles é só a
/// coordenada e a largura reservada pro nome/spacing. Uma formação nunca
/// decide escala — só decide ONDE; o breakpoint decide QUANTO.
class LineupLayoutEngine {
  const LineupLayoutEngine();

  /// Respiro visual mínimo entre dois footprints — objetivo e testado (ver
  /// `lineup_layout_engine_test.dart`), nunca deixado à sorte.
  static const minSafetyGap = 8.0;

  static const _compactBreakpoint = 380.0;
  static const _jerseySizeCompact = 42.0;
  static const _jerseySizeRegular = 46.0;

  /// A partir de quantas LINHAS táticas simultâneas (não jogadores por
  /// linha — linhas empilhadas verticalmente) uma formação deixa de caber
  /// com nome em 2 linhas + badge cheia sem violar `minSafetyGap`. Hoje só
  /// o losango do 4-1-2-1-2 (6 linhas: ataque/meia/meio/volante/defesa/gol)
  /// bate nisso — as demais (até 5 linhas) sobram espaço de sobra.
  static const _manyLinesThreshold = 6;

  // Medido com folga em cima do que o `LineupNameLabel`/`LineupPercentBadge`
  // renderizam de verdade (padding do container + `height` da fonte) —
  // nunca cortado por pixel. Quando a formação empilha muitas linhas ao
  // mesmo tempo, cai pro tier "compacto": nome em 1 linha só e badge menor
  // — NUNCA a camisa, que é fixa em qualquer um dos dois tiers.
  static const _nameLineHeight = 13.0;
  static const _nameTopGap = 6.0;
  static const _percentAllowance = 20.0;
  static const _removeAllowance = 10.0;

  static const _nameTopGapCompact = 3.0;
  static const _percentAllowanceCompact = 16.0;
  static const _removeAllowanceCompact = 8.0;

  double _jerseySizeFor(double fieldWidth) =>
      fieldWidth < _compactBreakpoint ? _jerseySizeCompact : _jerseySizeRegular;

  List<ResolvedSlotLayout> resolve({
    required Formation formation,
    required Size fieldSize,
    required LineupRenderMode mode,
  }) {
    const topInset = 40.0;
    const bottomInset = 12.0;
    final innerHeight = fieldSize.height - topInset - bottomInset;

    final jerseySize = _jerseySizeFor(fieldSize.width);
    final lines = _groupByLine(formation.slots);
    final widestLine = lines.values
        .map((slots) => slots.length)
        .reduce((a, b) => a > b ? a : b);
    final manyLines = lines.length >= _manyLinesThreshold;
    final nameMaxLines = manyLines ? 1 : 2;

    // O ANCHOR nunca pode depender do modo — se dimensionássemos a altura
    // com a allowance de cada modo separadamente, os dois modos
    // convergiriam pra alturas de célula diferentes e a resolução de
    // colisão abaixo empurraria cada um pra um lugar diferente. Por isso a
    // altura "de segurança" sempre usa a MAIOR allowance entre os dois
    // modos — o modo com menos conteúdo (`editable`) só usa uma fatia menor
    // dessa mesma célula reservada, nunca uma célula própria.
    final percentAllowance = manyLines
        ? _percentAllowanceCompact
        : _percentAllowance;
    final removeAllowance = manyLines
        ? _removeAllowanceCompact
        : _removeAllowance;
    final sharedAllowance = percentAllowance > removeAllowance
        ? percentAllowance
        : removeAllowance;
    final nameAllowance =
        (manyLines ? _nameTopGapCompact : _nameTopGap) +
        _nameLineHeight * nameMaxLines;
    final sharedCellHeight = jerseySize + nameAllowance + sharedAllowance;

    // Largura da célula (reserva pro nome/spacing, NUNCA pra camisa em si)
    // — encolhe em linhas mais cheias, mas nunca abaixo do que a própria
    // camisa precisa.
    final cellWidth = _cellWidthFor(widestLine, jerseySize);

    final safetyFootprint = PlayerVisualFootprint(
      jerseySize: jerseySize,
      width: cellWidth,
      height: sharedCellHeight,
      nameMaxLines: nameMaxLines,
    );

    final anchors = <int, Offset>{};
    for (var i = 0; i < formation.slots.length; i++) {
      final slot = formation.slots[i];
      final halfW = cellWidth / 2;
      final halfH = sharedCellHeight / 2;
      final centerX = (slot.x * fieldSize.width).clamp(
        halfW,
        fieldSize.width - halfW,
      );
      final centerY = (topInset + slot.y * innerHeight).clamp(
        topInset + halfH,
        topInset + innerHeight - halfH,
      );
      anchors[i] = Offset(centerX, centerY);
    }

    final safetyResolved = [
      for (var i = 0; i < formation.slots.length; i++)
        ResolvedSlotLayout(
          slotIndex: i,
          slot: formation.slots[i],
          anchor: anchors[i]!,
          footprint: safetyFootprint,
        ),
    ];
    final corrected = _resolveCollisions(safetyResolved, fieldSize);

    // Footprint efetivamente desenhado: pode ser mais baixo no modo
    // `editable` (sem badge de %) — nunca maior que o "de segurança" usado
    // acima, então um slot livre de colisão com a caixa grande também está
    // livre de colisão com a caixa menor centrada no mesmo ponto.
    final renderFootprint = PlayerVisualFootprint(
      jerseySize: jerseySize,
      width: cellWidth,
      height:
          jerseySize +
          nameAllowance +
          _modeAllowance(mode, manyLines: manyLines),
      nameMaxLines: nameMaxLines,
    );
    return [
      for (final layout in corrected)
        ResolvedSlotLayout(
          slotIndex: layout.slotIndex,
          slot: layout.slot,
          anchor: layout.anchor,
          footprint: renderFootprint,
        ),
    ];
  }

  double _modeAllowance(LineupRenderMode mode, {required bool manyLines}) =>
      switch (mode) {
        LineupRenderMode.crowd =>
          manyLines ? _percentAllowanceCompact : _percentAllowance,
        LineupRenderMode.editable =>
          manyLines ? _removeAllowanceCompact : _removeAllowance,
      };

  /// Agrupamento por `TacticalLine` — determinístico (a mesma linha tática
  /// sempre compartilha o mesmo `y`, vindo de `tacticalLineY`), nunca uma
  /// heurística de "y próximo o suficiente".
  Map<TacticalLine, List<FormationSlot>> _groupByLine(
    List<FormationSlot> slots,
  ) {
    final map = <TacticalLine, List<FormationSlot>>{};
    for (final slot in slots) {
      map.putIfAbsent(slot.line, () => []).add(slot);
    }
    return map;
  }

  /// Largura da célula por densidade de linha — SEMPRE derivada do
  /// `jerseySize` fixo (nunca um número solto), então nunca fica menor que
  /// a própria camisa precisa. É a única coisa que se adapta por formação;
  /// a camisa em si (`jerseySize`) é a mesma em todas.
  double _cellWidthFor(int playersInLine, double jerseySize) =>
      switch (playersInLine) {
        <= 2 => jerseySize + 38,
        3 => jerseySize + 32,
        4 => jerseySize + 24,
        _ => jerseySize + 14,
      };

  /// Rede de segurança determinística, em duas passadas — nada de nudge
  /// par-a-par iterativo (que pode oscilar quando um slot está espremido
  /// entre dois vizinhos com exigências conflitantes, ex.: o VOL isolado do
  /// 4-1-4-1, entre a defesa e o meio-campo). Primeiro empilha as LINHAS
  /// inteiras verticalmente (garante o respiro entre qualquer par de linhas
  /// vizinhas de uma vez, sempre convergindo em uma passada — se uma linha
  /// não coube no espaço nominal, o gap PARA ELA cresce, a camisa nunca
  /// encolhe pra compensar); com o eixo Y já seguro entre linhas, colisão
  /// diagonal entre linhas diferentes fica geometricamente impossível. Só
  /// resta o eixo X dentro da MESMA linha, resolvido depois.
  List<ResolvedSlotLayout> _resolveCollisions(
    List<ResolvedSlotLayout> slots,
    Size fieldSize,
  ) {
    final verticallySafe = _separateLines(slots, fieldSize);
    return _spreadWithinLines(verticallySafe, fieldSize);
  }

  List<ResolvedSlotLayout> _separateLines(
    List<ResolvedSlotLayout> slots,
    Size fieldSize,
  ) {
    final indicesByLine = <TacticalLine, List<int>>{};
    for (var i = 0; i < slots.length; i++) {
      indicesByLine.putIfAbsent(slots[i].slot.line, () => []).add(i);
    }
    final lineOrder = indicesByLine.keys.toList()
      ..sort(
        (a, b) => slots[indicesByLine[a]!.first].anchor.dy.compareTo(
          slots[indicesByLine[b]!.first].anchor.dy,
        ),
      );

    final centerY = <TacticalLine, double>{
      for (final line in lineOrder)
        line: slots[indicesByLine[line]!.first].anchor.dy,
    };
    final halfHeight = <TacticalLine, double>{
      for (final line in lineOrder)
        line: slots[indicesByLine[line]!.first].footprint.height / 2,
    };

    // Empurra sempre pra baixo (nunca pra cima) — determinístico, sem
    // oscilação: cada linha só precisa respeitar a linha JÁ AJUSTADA acima
    // dela. Isso preserva a ordem tática (nunca "afunda" um atacante).
    for (var i = 1; i < lineOrder.length; i++) {
      final above = lineOrder[i - 1];
      final current = lineOrder[i];
      final minCenterGap =
          halfHeight[above]! + halfHeight[current]! + minSafetyGap;
      final actualGap = centerY[current]! - centerY[above]!;
      if (actualGap < minCenterGap) {
        centerY[current] = centerY[above]! + minCenterGap;
      }
    }

    // Se o empilhamento estourou o campo por baixo, recua tudo de volta pra
    // dentro em bloco — preserva as distâncias que acabamos de garantir.
    final lastLine = lineOrder.last;
    final overflow =
        centerY[lastLine]! + halfHeight[lastLine]! - fieldSize.height;
    if (overflow > 0) {
      for (final line in lineOrder) {
        centerY[line] = centerY[line]! - overflow;
      }
    }

    return [
      for (final slot in slots)
        ResolvedSlotLayout(
          slotIndex: slot.slotIndex,
          slot: slot.slot,
          anchor: Offset(slot.anchor.dx, centerY[slot.slot.line]!),
          footprint: slot.footprint,
        ),
    ];
  }

  /// Dentro de cada linha (já com Y garantido acima), garante o gap mínimo
  /// no eixo X entre vizinhos horizontais — mesma ideia de empilhamento, da
  /// esquerda pra direita, preservando a ordem. Numa linha muito cheia
  /// (5 jogadores), é AQUI que o aperto é resolvido — nunca encolhendo a
  /// camisa, só reduzindo o respiro/label reservado por jogador.
  List<ResolvedSlotLayout> _spreadWithinLines(
    List<ResolvedSlotLayout> slots,
    Size fieldSize,
  ) {
    final indicesByLine = <TacticalLine, List<int>>{};
    for (var i = 0; i < slots.length; i++) {
      indicesByLine.putIfAbsent(slots[i].slot.line, () => []).add(i);
    }

    final centerX = List<double>.generate(
      slots.length,
      (i) => slots[i].anchor.dx,
    );

    for (final indices in indicesByLine.values) {
      if (indices.length < 2) continue;
      final sorted = [...indices]
        ..sort((a, b) => centerX[a].compareTo(centerX[b]));
      final halfW = slots[sorted.first].footprint.width / 2;
      final minGap = halfW * 2 + minSafetyGap;

      for (var i = 1; i < sorted.length; i++) {
        final prev = sorted[i - 1];
        final cur = sorted[i];
        if (centerX[cur] - centerX[prev] < minGap) {
          centerX[cur] = centerX[prev] + minGap;
        }
      }

      final lastIndex = sorted.last;
      final overflow = centerX[lastIndex] + halfW - fieldSize.width;
      if (overflow > 0) {
        for (final index in sorted) {
          centerX[index] -= overflow;
        }
      }
    }

    return [
      for (var i = 0; i < slots.length; i++)
        ResolvedSlotLayout(
          slotIndex: slots[i].slotIndex,
          slot: slots[i].slot,
          anchor: Offset(centerX[i], slots[i].anchor.dy),
          footprint: slots[i].footprint,
        ),
    ];
  }
}
