import 'package:flutter/material.dart';

/// Nome COMPLETO do time, em até duas linhas — nunca reticências, nunca
/// cortado. A quebra é natural, por palavras ("Grêmio / Novorizontino").
/// Tenta [sizes] do maior pro menor e só desce se uma palavra sozinha não
/// couber na largura ou se o nome passar de duas linhas. Se nem no menor
/// tamanho couber (celular muito estreito), libera uma terceira linha em vez
/// de perder letras.
class MatchTeamName extends StatelessWidget {
  const MatchTeamName(
    this.name, {
    required this.style,
    required this.alignment,
    this.sizes = const [13.0, 12.0, 11.5, 11.0],
    super.key,
  });

  final String name;

  /// Estilo-base; o `fontSize` é escolhido a partir de [sizes].
  final TextStyle style;

  /// `centerLeft` (mandante), `centerRight` (visitante) ou `center`.
  final Alignment alignment;

  /// Tamanhos de fonte tentados, do preferido ao mínimo.
  final List<double> sizes;

  TextAlign get _textAlign {
    if (alignment == Alignment.centerRight) return TextAlign.right;
    if (alignment == Alignment.center) return TextAlign.center;
    return TextAlign.left;
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // Mede com o mesmo estilo que o Text vai herdar (família da fonte do tema).
    final base = DefaultTextStyle.of(context).style;

    TextPainter painterFor(String text, double size) => TextPainter(
      text: TextSpan(
        text: text,
        style: base.merge(style.copyWith(fontSize: size)),
      ),
      textDirection: direction,
      textScaler: scaler,
      textAlign: _textAlign,
    );

    double widthOf(String text, double size) {
      final painter = painterFor(text, size)..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    int linesAt(double size, double maxWidth) {
      final painter = painterFor(name, size)..layout(maxWidth: maxWidth);
      final lines = painter.computeLineMetrics().length;
      painter.dispose();
      return lines;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final words = name.split(RegExp(r'\s+'));
        double? chosen;
        for (final size in sizes) {
          final wordFits = words.every((w) => widthOf(w, size) <= maxWidth);
          if (wordFits && linesAt(size, maxWidth) <= 2) {
            chosen = size;
            break;
          }
        }
        return Align(
          alignment: alignment,
          child: Text(
            name,
            // Sem tamanho que caiba em 2 linhas: libera a 3ª, nunca corta.
            maxLines: chosen == null ? null : 2,
            softWrap: true,
            overflow: TextOverflow.visible,
            textAlign: _textAlign,
            style: style.copyWith(fontSize: chosen ?? sizes.last),
          ),
        );
      },
    );
  }
}
