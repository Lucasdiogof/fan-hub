/// Capacidades REAIS do clube — cada flag existe porque a auditoria da M1
/// (e a M4.2A, pra `hasNews`/`hasSocial`) encontrou o runtime
/// correspondente (não são flags especulativas). M4.2A liga isto de
/// verdade: Home/bottom-nav/Perfil/rotas/deep-links agora leem estas
/// flags — nunca mais "sempre visível" hardcoded (ver
/// `docs/multiclub/44_m4_2_club_capabilities_report.md`).
///
/// `Squad`/`Notifications` NÃO ganharam capability própria de propósito —
/// são infraestrutura básica que todo clube tem (elenco + preferências de
/// notificação), sem nenhum precedente de produto pra "esconder" nenhuma
/// das duas; os repositories delas já são `club_id`-scoped desde M3.1/M3.2,
/// então "capability=true sempre" não é um risco de vazamento, é só uma
/// decisão de escopo (ver relatório).
class ClubCapabilities {
  const ClubCapabilities({
    required this.hasMembership,
    required this.hasStore,
    required this.hasTickets,
    required this.hasCrowdLineup,
    required this.hasPassport,
    required this.hasNews,
    required this.hasSocial,
    required this.hasClubContent,
    required this.hasMatches,
    required this.enabledArenaGames,
  });

  final bool hasMembership;
  final bool hasStore;
  final bool hasTickets;
  final bool hasCrowdLineup;
  final bool hasPassport;

  /// Aba "Jogos" + calendário/detalhe de partida (`/match/:id`) — depende
  /// do Worker de futebol do PRÓPRIO clube estar no ar (`ClubIntegrations.
  /// workerBaseUrl` configurado e testado). `false` enquanto esse Worker
  /// não existir — nunca usa o Worker de outro clube nem por omissão.
  final bool hasMatches;

  /// História, títulos, diretoria, hino e parceiros (`/clube` e
  /// `/partners`) — conteúdo editorial estático que hoje só existe pro
  /// Goiás (ver `docs/multiclub/...`). Elenco (`/squad`) fica de fora de
  /// propósito, mesma razão do comentário de classe acima: já é
  /// `club_id`-scoped de verdade, não depende deste gate.
  final bool hasClubContent;

  /// Notícias (site oficial, via Worker `/api/news`).
  final bool hasNews;

  /// Redes sociais oficiais dentro do app (Instagram/YouTube/X, via Worker
  /// `/api/social/feed`) — separada de `hasNews` porque um clube pode ter
  /// uma sem a outra (ex.: site de notícias mas sem integração social
  /// ainda, ou vice-versa).
  final bool hasSocial;

  /// Códigos de `lib/features/arena/games/*` que este clube tem dataset
  /// pronto pra jogar — hoje os 6 já cadastrados no Goiás (`quiz`,
  /// `lineup`, `career_path`, `guess_player`, `player_identity`,
  /// `tactical_identity`). `penalty` fica de fora de propósito — está
  /// oculto no `ArenaCatalog` hoje (comentado), não é uma capacidade do
  /// clube, é um jogo pausado no produto.
  final Set<String> enabledArenaGames;
}
