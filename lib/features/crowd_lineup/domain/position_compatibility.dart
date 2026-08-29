import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';
import 'package:goias_app/shared/domain/player_position.dart';

/// Nível de encaixe de um jogador num slot tático — nunca deduzido olhando
/// índice/ordem na tela, sempre calculado aqui a partir de
/// [SquadPlayer.allowedPositions] + [_naturalAdaptations].
enum PositionFit { exactPrimary, exactSecondary, natural, incompatible }

/// Camada tática sobre o cadastro real do elenco. [SquadPlayer.allowedPositions]
/// nunca é alterado por causa disto — isto só decide se/quanto um jogador
/// serve pra um slot que a formação pediu.
class PositionCompatibilityService {
  const PositionCompatibilityService();

  static const int exactPrimaryScore = 100;
  static const int exactSecondaryScore = 90;

  /// slot → [(posição natural do jogador, score), ...] em ordem de
  /// prioridade. Cada entrada aqui é uma adaptação REAL de futebol, nunca
  /// genérica ("jogador ofensivo" não vira MEI só por ser ofensivo) — ver a
  /// spec de cada posição. Assimétrico de propósito: a mesma dupla de
  /// posições pode aparecer nos dois sentidos com pesos diferentes (ex.:
  /// `pd` preenchendo `md` vale mais que `md` preenchendo `pd` — jogar mais
  /// avançado e recuar é mais natural que o contrário).
  static const Map<PlayerPosition, List<(PlayerPosition, int)>>
  _naturalAdaptations = {
    PlayerPosition.gol: [],
    PlayerPosition.zag: [],
    PlayerPosition.ld: [(PlayerPosition.ald, 80)],
    PlayerPosition.le: [(PlayerPosition.ale, 80)],
    PlayerPosition.ald: [
      (PlayerPosition.ld, 85),
      (PlayerPosition.md, 75),
      (PlayerPosition.pd, 65),
    ],
    PlayerPosition.ale: [
      (PlayerPosition.le, 85),
      (PlayerPosition.me, 75),
      (PlayerPosition.pe, 65),
    ],
    PlayerPosition.vol: [(PlayerPosition.mc, 78)],
    PlayerPosition.mc: [(PlayerPosition.vol, 80), (PlayerPosition.mei, 68)],
    PlayerPosition.mei: [(PlayerPosition.mc, 72), (PlayerPosition.sa, 68)],
    PlayerPosition.md: [(PlayerPosition.pd, 80), (PlayerPosition.ald, 72)],
    PlayerPosition.me: [(PlayerPosition.pe, 80), (PlayerPosition.ale, 72)],
    PlayerPosition.pd: [(PlayerPosition.md, 70)],
    PlayerPosition.pe: [(PlayerPosition.me, 70)],
    PlayerPosition.sa: [(PlayerPosition.ata, 80), (PlayerPosition.mei, 68)],
    PlayerPosition.ata: [(PlayerPosition.sa, 80)],
  };

  /// Nível de encaixe (sem número) — usado pra decidir se o jogador aparece
  /// como candidato ao slot.
  PositionFit fitFor(SquadPlayer player, PlayerPosition slot) {
    if (player.primaryPosition == slot) return PositionFit.exactPrimary;
    if (player.secondaryPositions.contains(slot)) {
      return PositionFit.exactSecondary;
    }
    return _bestNaturalScore(player, slot) != null
        ? PositionFit.natural
        : PositionFit.incompatible;
  }

  /// Score numérico pra ordenar candidatos dentro do bottom sheet — maior é
  /// melhor encaixe. `null` quando incompatível (não deve aparecer na lista).
  int? scoreFor(SquadPlayer player, PlayerPosition slot) {
    return switch (fitFor(player, slot)) {
      PositionFit.exactPrimary => exactPrimaryScore,
      PositionFit.exactSecondary => exactSecondaryScore,
      PositionFit.natural => _bestNaturalScore(player, slot),
      PositionFit.incompatible => null,
    };
  }

  int? _bestNaturalScore(SquadPlayer player, PlayerPosition slot) {
    final adaptations = _naturalAdaptations[slot] ?? const [];
    int? best;
    for (final (playerPosition, score) in adaptations) {
      if (!player.allowedPositions.contains(playerPosition)) continue;
      if (best == null || score > best) best = score;
    }
    return best;
  }
}
