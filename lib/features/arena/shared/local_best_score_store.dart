import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_scoped_storage_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recorde pessoal por jogo, só neste aparelho — usado pelo Quiz (recorde
/// por nível) e pelo Pênaltis. Não tem relação com a pontuação cross-game
/// do Ranking da Torcida (`ArenaRankingRepository`), que é outra economia
/// de pontos, cumulativa e sincronizada no servidor. Chave namespaçada por
/// clube desde a M3.3 (jogos da Arena são conteúdo do clube ativo, ver
/// M3.1/M3.2) — com migração transparente da chave legacy só pro Goiás.
class LocalBestScoreStore {
  LocalBestScoreStore(this._clubConfig);

  static const _prefix = 'arena_best_';

  final ClubConfig _clubConfig;

  Future<int> bestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = ClubScopedStorageKey(_clubConfig);
    final scopedKey = keys.scoped('$_prefix$gameId');
    final scopedValue = prefs.getInt(scopedKey);
    if (scopedValue != null) return scopedValue;
    if (_clubConfig.identity.code == 'goias') {
      // LEGACY_LOCAL_STATE_IS_GOIAS_ONLY.
      final legacyValue = prefs.getInt('$_prefix$gameId');
      if (legacyValue != null) {
        await prefs.setInt(scopedKey, legacyValue);
        return legacyValue;
      }
    }
    return 0;
  }

  Future<int> saveIfBest(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = ClubScopedStorageKey(_clubConfig).scoped('$_prefix$gameId');
    final current = await bestScore(gameId);
    final best = score > current ? score : current;
    if (best != current) await prefs.setInt(key, best);
    return best;
  }
}
