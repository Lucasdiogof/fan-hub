import 'package:goias_app/core/club/club_capabilities.dart';

/// Rota de destino pra QUALQUER caminho bloqueado por capability — genérica
/// de propósito (ver `FeatureUnavailablePage`), nunca revela pro usuário
/// qual capability faltou.
const featureUnavailableRoute = '/feature-unavailable';

/// Jogos do Arena com rota própria (`/arena/<slug>`) mapeados pro código
/// exato usado em `ClubCapabilities.enabledArenaGames` — única fonte dessa
/// correspondência, nunca duplicada dentro do checker abaixo.
const _arenaGameRoutes = {
  '/arena/quiz': 'quiz',
  '/arena/lineup': 'lineup',
  '/arena/career-path': 'career_path',
  '/arena/guess-player': 'guess_player',
  '/arena/tactical-identity': 'tactical_identity',
  '/arena/player-identity': 'player_identity',
};

bool _matches(String location, String prefix) =>
    location == prefix || location.startsWith('$prefix/');

/// M4.2A — decide se [location] deve ser bloqueada pra quem tem
/// [capabilities], e devolve o destino do redirect (sempre
/// [featureUnavailableRoute]) ou `null` se a rota está liberada.
///
/// Função pura, sem `BuildContext`/GoRouter — chamada de dentro do
/// `redirect` do `GoRouter` (ver `app_router.dart`), mas testável sozinha
/// sem nenhum framework de widget. Cobre TODA rota interna gateada — deep
/// link/URL direta nunca burla isto, porque roda pra QUALQUER navegação,
/// não só a partir de um card/botão dentro do app.
///
/// Ordem importa: os jogos específicos do Arena são checados ANTES do
/// gate geral de `/arena` (senão um jogo desabilitado cairia no branch
/// errado); Passaporte é checado antes do gate geral de `/arena` pelo
/// mesmo motivo (é um sub-caminho de `/arena`, mas com capability própria,
/// nunca a de `enabledArenaGames`).
String? capabilityGateRedirect(String location, ClubCapabilities capabilities) {
  for (final entry in _arenaGameRoutes.entries) {
    if (_matches(location, entry.key) &&
        !capabilities.enabledArenaGames.contains(entry.value)) {
      return featureUnavailableRoute;
    }
  }

  if (_matches(location, '/arena/passport')) {
    if (!capabilities.hasPassport) return featureUnavailableRoute;
  } else if (_matches(location, '/arena')) {
    // Hub/ranking do Arena — visível se o clube tiver QUALQUER jogo
    // habilitado; nunca uma capability `hasArena` própria e redundante.
    if (capabilities.enabledArenaGames.isEmpty) return featureUnavailableRoute;
  }

  if (_matches(location, '/store') && !capabilities.hasStore) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/membership') && !capabilities.hasMembership) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/tickets') && !capabilities.hasTickets) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/crowd-lineup') && !capabilities.hasCrowdLineup) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/news') && !capabilities.hasNews) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/clube') && !capabilities.hasClubContent) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/partners') && !capabilities.hasClubContent) {
    return featureUnavailableRoute;
  }
  if (_matches(location, '/match') && !capabilities.hasMatches) {
    return featureUnavailableRoute;
  }

  // Squad (`/squad`) e Notificações (`/profile/notifications`) NUNCA são
  // gateadas de propósito — ver o comentário em `ClubCapabilities`.
  return null;
}
