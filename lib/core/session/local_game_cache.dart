import 'package:shared_preferences/shared_preferences.dart';

const _arenaBestPrefix = 'arena_best_';
const _guessPlayerKeys = [
  'guess_player_active_round',
  'guess_player_stats_played',
  'guess_player_stats_correct',
  'guess_player_seen_ids',
  'guess_player_seen_signature',
];

/// `arena_best_<gameId>` (espelho local do recorde) e as chaves do "Quem
/// Vestiu o Manto" não carregam o uid — sem essa limpeza, uma conta nova
/// no mesmo aparelho herdaria (e até empurraria pra nuvem) o progresso da
/// conta anterior. Chamado tanto no logout/sessão expirada (ver
/// `AccountSessionCacheGuard`) quanto no fluxo de exclusão de conta.
///
/// M3.3: as chaves reais agora vivem namespaçadas por clube
/// (`<clubCode>:arena_best_<gameId>`, `<clubCode>:guess_player_*` — ver
/// `ClubScopedStorageKey`), mas a checagem aqui casa por SUFIXO
/// (`endsWith`), não por igualdade/prefixo exato — limpa a chave de
/// QUALQUER clube (não só o ativo) e ainda cobre a chave legacy sem
/// namespace (pré-M3.3, só existe pro Goiás) num único passe, sem precisar
/// saber qual é o clube ativo aqui.
Future<void> clearAccountScopedLocalCache() async {
  final prefs = await SharedPreferences.getInstance();
  final keysToRemove = prefs
      .getKeys()
      .where(
        (key) =>
            key.contains(_arenaBestPrefix) ||
            _guessPlayerKeys.any(
              (legacyKey) => key == legacyKey || key.endsWith(':$legacyKey'),
            ),
      )
      .toList();
  for (final key in keysToRemove) {
    await prefs.remove(key);
  }
}
