/// Capacidades REAIS do clube — cada flag existe porque a auditoria da M1
/// encontrou o runtime correspondente (não são flags especulativas).
/// Nenhum consumidor real lê isto ainda — `ArenaCatalog.games` continua
/// sendo a lista fixa de sempre (ver relatório da M1, achado #31).
class ClubCapabilities {
  const ClubCapabilities({
    required this.hasMembership,
    required this.hasStore,
    required this.hasTickets,
    required this.hasCrowdLineup,
    required this.hasPassport,
    required this.enabledArenaGames,
  });

  final bool hasMembership;
  final bool hasStore;
  final bool hasTickets;
  final bool hasCrowdLineup;
  final bool hasPassport;

  /// Códigos de `lib/features/arena/games/*` que este clube tem dataset
  /// pronto pra jogar — hoje os 6 já cadastrados no Goiás (`quiz`,
  /// `lineup`, `career_path`, `guess_player`, `player_identity`,
  /// `tactical_identity`). `penalty` fica de fora de propósito — está
  /// oculto no `ArenaCatalog` hoje (comentado), não é uma capacidade do
  /// clube, é um jogo pausado no produto.
  final Set<String> enabledArenaGames;
}
