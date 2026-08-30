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
Future<void> clearAccountScopedLocalCache() async {
  final prefs = await SharedPreferences.getInstance();
  final keysToRemove = prefs
      .getKeys()
      .where(
        (key) =>
            key.startsWith(_arenaBestPrefix) || _guessPlayerKeys.contains(key),
      )
      .toList();
  for (final key in keysToRemove) {
    await prefs.remove(key);
  }
}
