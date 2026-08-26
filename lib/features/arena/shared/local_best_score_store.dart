import 'package:shared_preferences/shared_preferences.dart';

/// Recorde pessoal por jogo, só neste aparelho — usado pelo Quiz (recorde
/// por nível) e pelo Pênaltis. Não tem relação com a pontuação cross-game
/// do Ranking da Torcida (`ArenaRankingRepository`), que é outra economia
/// de pontos, cumulativa e sincronizada no servidor.
class LocalBestScoreStore {
  static const _prefix = 'arena_best_';

  Future<int> bestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$gameId') ?? 0;
  }

  Future<int> saveIfBest(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$gameId';
    final current = prefs.getInt(key) ?? 0;
    final best = score > current ? score : current;
    if (best != current) await prefs.setInt(key, best);
    return best;
  }
}
