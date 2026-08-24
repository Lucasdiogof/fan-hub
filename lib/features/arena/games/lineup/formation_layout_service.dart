import 'dart:ui';

/// Gera coordenadas relativas (0.0–1.0) padrão pra uma formação, em pé de
/// goleiro pra atacante (y=0 topo do campo, y=1 goleiro) — usado só quando
/// o dataset de uma partida ainda não tem `x`/`y` curados à mão por
/// jogador. Sempre que o dataset já traz `x`/`y` (caso normal, ver
/// `LineupPlayer`), este serviço nem é chamado: posição curada manual
/// sempre tem prioridade sobre a gerada.
class FormationLayoutService {
  const FormationLayoutService._();

  static const Map<String, List<int>> _known = {
    '4-4-2': [1, 4, 4, 2],
    '4-3-3': [1, 4, 3, 3],
    '3-5-2': [1, 3, 5, 2],
    '4-2-3-1': [1, 4, 2, 3, 1],
    '4-1-2-1-2': [1, 4, 1, 2, 1, 2],
    '5-3-2': [1, 5, 3, 2],
    '3-4-3': [1, 3, 4, 3],
    '4-5-1': [1, 4, 5, 1],
  };

  /// Uma posição por linha (goleiro primeiro), da esquerda pra direita —
  /// mesma ordem em que o dataset costuma listar os titulares. Formações
  /// não catalogadas caem no fallback: separa os números depois de cada
  /// "-" e distribui em linhas igualmente espaçadas.
  static List<Offset> positionsFor(String formation) {
    final lines = _known[formation] ?? _parseFallback(formation);
    final positions = <Offset>[];

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final count = lines[lineIndex];
      // Goleiro quase colado na linha de fundo, ataque perto do topo —
      // demais linhas distribuídas em passos iguais entre as duas.
      final y = lineIndex == 0
          ? 0.92
          : 0.92 - (lineIndex / (lines.length - 1)) * 0.80;
      for (var slot = 0; slot < count; slot++) {
        // slot+1 sobre count+1 deixa uma margem nas duas bordas — uma
        // linha de 2 não fica grudada nos cantos do campo.
        final x = (slot + 1) / (count + 1);
        positions.add(Offset(x, y));
      }
    }
    return positions;
  }

  static List<int> _parseFallback(String formation) {
    final parts = formation
        .split('-')
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    if (parts.isEmpty) return [1, 4, 4, 2];
    return [1, ...parts];
  }
}
