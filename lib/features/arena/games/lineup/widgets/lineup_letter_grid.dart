import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';

/// A grade de tentativas de um jogador — [answerParts] define os grupos
/// (uma "palavra" cada), mas a digitação e a contagem de tentativas
/// tratam tudo como uma sequência única de letras; os grupos só existem
/// visualmente, como espaço entre as casas, nunca como uma casa a mais.
class LineupLetterGrid extends StatelessWidget {
  const LineupLetterGrid({
    required this.answerParts,
    required this.guesses,
    required this.currentGuessLetters,
    super.key,
  });

  final List<int> answerParts;
  final List<LineupGuess> guesses;
  final List<String> currentGuessLetters;

  // Tamanho "natural" da célula — usado como está pra respostas curtas.
  // Respostas longas (ex.: "CARLOS ALBERTO", 13 letras) que não caibam na
  // largura da tela são encolhidas de uma vez só pelo `FittedBox` lá
  // embaixo, em vez de cada célula calcular seu próprio tamanho: mais
  // simples e sem risco de math de layout entrar em conflito com o
  // `RenderFlex` (foi exatamente isso que causava um overflow gigante e
  // sem sentido antes).
  static const double _naturalCellSize = 50.0;
  static const double _gap = 8.0;
  static const double _cellSpacing = 5.0;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < LineupCubit.maxAttempts; row++) ...[
            if (row > 0) const SizedBox(height: _cellSpacing),
            _GridRow(
              answerParts: answerParts,
              cellSize: _naturalCellSize,
              cellSpacing: _cellSpacing,
              gap: _gap,
              guess: row < guesses.length ? guesses[row] : null,
              inProgressLetters: row == guesses.length
                  ? currentGuessLetters
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.answerParts,
    required this.cellSize,
    required this.cellSpacing,
    required this.gap,
    required this.guess,
    required this.inProgressLetters,
  });

  final List<int> answerParts;
  final double cellSize;
  final double cellSpacing;
  final double gap;
  final LineupGuess? guess;
  final List<String>? inProgressLetters;

  @override
  Widget build(BuildContext context) {
    var letterIndex = 0;
    final groups = <Widget>[];
    for (var g = 0; g < answerParts.length; g++) {
      if (g > 0) groups.add(SizedBox(width: gap));
      final cells = <Widget>[];
      for (var i = 0; i < answerParts[g]; i++) {
        if (i > 0) cells.add(SizedBox(width: cellSpacing));
        final letter = guess != null
            ? guess!.letters[letterIndex]
            : (inProgressLetters != null &&
                  letterIndex < inProgressLetters!.length)
            ? inProgressLetters![letterIndex]
            : null;
        final status = guess?.statuses[letterIndex];
        cells.add(_LetterCell(size: cellSize, letter: letter, status: status));
        letterIndex++;
      }
      groups.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }
    return Center(
      child: Row(mainAxisSize: MainAxisSize.min, children: groups),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.size,
    required this.letter,
    required this.status,
  });

  final double size;
  final String? letter;
  final LetterStatus? status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (
      background,
      border,
      foreground,
      icon,
      semanticLabel,
    ) = switch (status) {
      LetterStatus.correct => (
        const Color(0xFF278A52),
        const Color(0xFF278A52),
        Colors.white,
        Icons.check_rounded,
        'posição correta',
      ),
      LetterStatus.present => (
        const Color(0xFFC79A3D),
        const Color(0xFFC79A3D),
        Colors.white,
        Icons.sync_alt_rounded,
        'letra existe, posição errada',
      ),
      LetterStatus.absent => (
        colors.surfaceRaised,
        colors.border,
        colors.textHint,
        null,
        'letra não existe',
      ),
      null => (
        Colors.transparent,
        letter != null ? colors.textHint : colors.border,
        colors.textPrimary,
        null,
        null,
      ),
    };

    return Semantics(
      label: letter == null
          ? 'vazio'
          : '$letter${semanticLabel != null ? ', $semanticLabel' : ''}',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              letter ?? '',
              style: TextStyle(
                color: foreground,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (icon != null)
              Positioned(
                bottom: 1,
                right: 1,
                child: Icon(
                  icon,
                  size: size * 0.22,
                  color: foreground.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
