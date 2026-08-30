import 'package:flutter/material.dart';

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

/// Rótulo compartilhado pelos dois modos da Escalação (Torcida e Escale) —
/// nome do jogador (até [maxLines] linhas, ver [splitNameForDisplay]) ou a
/// sigla da posição quando o slot está vazio. Largura sempre igual ao
/// `maxWidth` do footprint resolvido pela engine (nunca a largura do texto)
/// e ALTURA sempre reservada pras [maxLines] linhas — mesmo pra um nome de
/// uma palavra só, ou quando [maxLines] é 1 — pra a camisa nunca "pular" de
/// posição por causa do tamanho do nome do vizinho.
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
  /// posição num slot vazio) — nunca tenta quebrar em nome/sobrenome.
  final bool allowSplit;

  @override
  Widget build(BuildContext context) {
    final lines = allowSplit ? splitNameForDisplay(text) : [text];
    const style = TextStyle(
      color: Colors.white,
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
      height: 1.15,
    );
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
          for (var i = 0; i < maxLines; i++)
            Text(
              i < lines.length ? lines[i].toUpperCase() : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style,
            ),
        ],
      ),
    );
  }
}
