/// O voto do usuário: a formação escolhida e, por slot (índice na formação),
/// o id do jogador escalado.
class LineupVote {
  const LineupVote({required this.formationId, required this.playerIdBySlot});

  final String formationId;
  final Map<int, String> playerIdBySlot;

  bool get isComplete => playerIdBySlot.length == 11;
}
