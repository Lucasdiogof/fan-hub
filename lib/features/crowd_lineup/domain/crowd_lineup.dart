import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';

/// O jogador mais escalado num slot da formação vencedora, com o percentual
/// de presença (votos nesse jogador ÷ votos da formação vencedora).
class CrowdSlotResult {
  const CrowdSlotResult({
    required this.slotIndex,
    required this.position,
    required this.player,
    required this.percent,
  });

  final int slotIndex;
  final PlayerPosition position;
  final SquadPlayer? player;
  final int percent;
}

/// A "Escalação da torcida": a formação mais votada e, dentro dela, o
/// jogador mais escolhido em cada slot.
class CrowdLineup {
  const CrowdLineup({
    required this.totalVotes,
    required this.topFormation,
    required this.slots,
  });

  const CrowdLineup.empty()
    : totalVotes = 0,
      topFormation = null,
      slots = const [];

  final int totalVotes;
  final Formation? topFormation;
  final List<CrowdSlotResult> slots;

  bool get hasVotes => totalVotes > 0 && topFormation != null;
}
