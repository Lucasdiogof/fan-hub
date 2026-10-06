import 'package:flutter/widgets.dart';

/// Ajuste inteligente de nomes pra telas apertadas — nunca reticências no
/// meio de um nome. Em vez de cortar, escolhe a MAIOR forma do nome que cabe:
///   * pessoa (ranking): "Lucas Diogo França" → "Lucas Diogo" → "Lucas";
///     partículas ("de", "da"…) nunca terminam o nome ("deusimar ribeiro de
///     franca" → "deusimar ribeiro");
///   * jogador (escalações): nome completo → apelido provável, que é quase
///     sempre o último nome ("Wellington Saci" → "Saci", "Felipe Machado"
///     → "Machado"). Sufixos de geração ("Neto", "Júnior") não viram apelido
///     sozinhos, e quando o último nome é um prenome comum ("Carlos Alberto")
///     a forma curta é a inicial: "Carlos A.", depois só "Carlos".

const _particles = {
  'de',
  'da',
  'do',
  'dos',
  'das',
  'e',
  'di',
  'del',
  'van',
  'von',
  'la',
  'le',
};

const _generationSuffixes = {
  'junior',
  'júnior',
  'jr',
  'filho',
  'neto',
  'sobrinho',
  'segundo',
};

const _commonGivenNames = {
  'alberto',
  'augusto',
  'henrique',
  'eduardo',
  'fernando',
  'roberto',
  'antonio',
  'antônio',
  'carlos',
  'paulo',
  'pedro',
  'luiz',
  'luis',
  'luís',
  'josé',
  'jose',
  'joão',
  'joao',
  'marcos',
  'miguel',
  'gabriel',
  'rafael',
  'felipe',
  'lucas',
  'mateus',
  'matheus',
  'guilherme',
  'victor',
  'vitor',
  'thiago',
  'tiago',
  'bruno',
  'diego',
  'andré',
  'andre',
};

List<String> _words(String name) =>
    name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

String _norm(String word) => word.toLowerCase().replaceAll('.', '');

List<String> _dedupe(Iterable<String> items) {
  final seen = <String>{};
  return [
    for (final item in items)
      if (seen.add(item.toLowerCase())) item,
  ];
}

/// Formas de um nome de PESSOA, da maior pra menor. Sempre tem ao menos 1.
List<String> personNameCandidates(String name) {
  final words = _words(name);
  if (words.length <= 1) return [name.trim()];
  final out = <String>[words.join(' ')];
  for (var n = words.length - 1; n >= 1; n--) {
    final prefix = words.take(n).toList();
    if (n > 1 && _particles.contains(_norm(prefix.last))) continue;
    out.add(prefix.join(' '));
  }
  return _dedupe(out);
}

/// Formas de um nome de JOGADOR, do completo ao apelido mais provável.
List<String> playerNameCandidates(String name) {
  final words = _words(name);
  if (words.length <= 1) return [name.trim()];
  final full = words.join(' ');
  final first = words.first;

  final nicknames = <String>[];
  for (var i = 1; i < words.length; i++) {
    final suffix = words.skip(i).toList();
    if (_particles.contains(_norm(suffix.first))) continue;
    if (suffix.length == 1 && _generationSuffixes.contains(_norm(suffix[0]))) {
      continue;
    }
    nicknames.add(suffix.join(' '));
  }

  final lastIsGivenName =
      words.length == 2 && _commonGivenNames.contains(_norm(words.last));
  return _dedupe([
    full,
    if (lastIsGivenName) ...[
      '$first ${words.last[0].toUpperCase()}.',
      first,
    ] else ...[
      ...nicknames,
      first,
    ],
  ]);
}

/// Largura do [text] em uma linha, respeitando a escala de texto do usuário.
double measureTextWidth(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Texto de uma linha que escolhe, entre [candidates], a maior forma que cabe
/// na largura disponível. Se nem a menor cabe, usa a menor com reticências
/// (caso extremo: um único nome gigante).
class FittedNameText extends StatelessWidget {
  const FittedNameText(
    this.name, {
    required this.style,
    this.candidates,
    super.key,
  });

  final String name;
  final TextStyle style;

  /// Formas do nome, da maior pra menor. Padrão: [personNameCandidates].
  final List<String>? candidates;

  @override
  Widget build(BuildContext context) {
    final options = candidates ?? personNameCandidates(name);
    final scaler = MediaQuery.textScalerOf(context);
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, constraints) {
        var pick = options.last;
        if (constraints.maxWidth.isFinite) {
          for (final option in options) {
            if (measureTextWidth(option, base, scaler) <=
                constraints.maxWidth) {
              pick = option;
              break;
            }
          }
        } else {
          pick = options.first;
        }
        return Text(
          pick,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}
