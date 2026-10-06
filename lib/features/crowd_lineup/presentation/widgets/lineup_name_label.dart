import 'package:flutter/material.dart';
import 'package:goias_app/shared/utils/display_name_fit.dart';

/// Quebra previsível em até 2 linhas — nunca o `maxLines` do Flutter
/// quebrando no meio de uma palavra por falta de espaço. Primeira palavra
/// na linha 1, o resto (se houver) na linha 2; nome de uma palavra só fica
/// numa linha só. Ex.: "Felipe Clemente" → "FELIPE" / "CLEMENTE"; "Tadeu" →
/// "TADEU".
List<String> splitNameForDisplay(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return const [''];
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return [parts.first];
  return [parts.first, parts.skip(1).join(' ')];
}

/// Nome completo abreviado numa linha só — pros formatos com `nameMaxLines`
/// 1 (o losango 4-1-2-1-2, único caso hoje). Nunca descarta o sobrenome:
/// "Lucas Halter" → "Lucas H."; nome de uma palavra só fica como está.
String abbreviateNameForDisplay(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last[0]}.';
}

/// Rótulo compartilhado pelos modos da Escalação (Torcida, Escale e
/// Adivinhe a escalação) — nome do jogador (até [maxLines] linhas) ou a sigla
/// da posição quando o slot está vazio. Largura sempre igual ao `maxWidth`
/// do footprint resolvido pela engine (nunca a largura do texto) e ALTURA
/// sempre reservada pras [maxLines] linhas — pra a camisa nunca "pular" de
/// posição por causa do tamanho do nome do vizinho.
///
/// NUNCA corta o nome com reticências: tenta o nome completo (descendo a
/// fonte até 8.5); se não couber, usa o apelido provável (ver
/// [playerNameCandidates]: "Wellington Saci" → "SACI", "Felipe Machado" →
/// "MACHADO"); só no caso extremo de uma palavra maior que o espaço a fonte
/// encolhe até caber.
class LineupNameLabel extends StatelessWidget {
  const LineupNameLabel({
    required this.text,
    required this.maxWidth,
    this.maxLines = 2,
    this.allowSplit = true,
    super.key,
  });

  final String text;
  final double maxWidth;

  /// 1 ou 2 — vem do `PlayerVisualFootprint.nameMaxLines` resolvido pela
  /// engine (cai pra 1 só quando a formação empilha tantas linhas táticas
  /// que 2 linhas de nome não caberiam sem violar o safety gap).
  final int maxLines;

  /// `false` pra rótulos que nunca são nome de jogador (ex.: sigla de
  /// posição num slot vazio) — nunca tenta quebrar nem trocar por apelido.
  final bool allowSplit;

  static const double _maxFontSize = 9.5;
  static const double _horizontalPadding = 5;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final fit = fitLineupName(
      text: text,
      available: maxWidth - 2 * _horizontalPadding,
      maxLines: maxLines,
      allowSplit: allowSplit,
      scaler: scaler,
    );
    // O dimensionador invisível sempre reserva `maxLines` linhas na fonte
    // máxima; só a pílula visível encolhe pro conteúdo real, alinhada no topo.
    return SizedBox(
      width: maxWidth,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Opacity(
            opacity: 0,
            child: _NamePill(
              lines: List.filled(maxLines, ' '),
              maxWidth: maxWidth,
              fontSize: _maxFontSize,
            ),
          ),
          _NamePill(
            lines: fit.lines,
            maxWidth: maxWidth,
            fontSize: fit.fontSize,
          ),
        ],
      ),
    );
  }
}

/// Resultado do ajuste: as linhas a exibir e o tamanho da fonte.
class LineupNameFit {
  const LineupNameFit(this.lines, this.fontSize);

  final List<String> lines;
  final double fontSize;
}

TextStyle _pillStyle(double fontSize) => TextStyle(
  color: Colors.white,
  fontSize: fontSize,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.1,
  height: 1.15,
);

/// Melhor divisão do [candidate] em até [maxLines] linhas (maiúsculas) que
/// cabe em [available] na fonte [fontSize]; `null` se nenhuma cabe.
List<String>? _fitCandidate(
  String candidate,
  int maxLines,
  double available,
  double fontSize,
  TextScaler scaler,
) {
  final upper = candidate.toUpperCase();
  final style = _pillStyle(fontSize);
  double width(String t) => measureTextWidth(t, style, scaler);
  final words = upper.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final list = words.toList();
  if (list.length <= 1 || maxLines == 1) {
    return width(upper) <= available ? [upper] : null;
  }
  List<String>? best;
  var bestWorst = double.infinity;
  for (var k = 1; k < list.length; k++) {
    final first = list.take(k).join(' ');
    final rest = list.skip(k).join(' ');
    final worst = width(first) > width(rest) ? width(first) : width(rest);
    if (worst < bestWorst) {
      bestWorst = worst;
      best = [first, rest];
    }
  }
  return bestWorst <= available ? best : null;
}

/// Escolhe o que mostrar: nome completo (fonte 9.5 → 8.5) e, se não couber,
/// cada apelido candidato; no extremo, a menor forma com a fonte encolhida.
LineupNameFit fitLineupName({
  required String text,
  required double available,
  required int maxLines,
  required bool allowSplit,
  required TextScaler scaler,
}) {
  const sizes = [9.5, 9.0, 8.5];
  final candidates = allowSplit ? playerNameCandidates(text) : [text.trim()];
  for (final candidate in candidates) {
    for (final size in sizes) {
      final lines = _fitCandidate(candidate, maxLines, available, size, scaler);
      if (lines != null) return LineupNameFit(lines, size);
    }
  }
  // Extremo: nem a menor forma cabe na fonte mínima — encolhe até caber.
  final last = candidates.last.toUpperCase();
  final natural = measureTextWidth(last, _pillStyle(sizes.last), scaler);
  final shrink = natural <= 0 || natural <= available
      ? 1.0
      : available / natural;
  return LineupNameFit([last], sizes.last * shrink);
}

class _NamePill extends StatelessWidget {
  const _NamePill({
    required this.lines,
    required this.maxWidth,
    required this.fontSize,
  });

  final List<String> lines;
  final double maxWidth;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = _pillStyle(fontSize);
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Text(
              line,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: style,
            ),
        ],
      ),
    );
  }
}
