import 'package:shared_preferences/shared_preferences.dart';

class ArenaScores {
  static const _prefix = 'arena_best_';

  Future<int> bestScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$gameId') ?? 0;
  }

  Future<int> saveIfBest(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$gameId';
    final current = prefs.getInt(key) ?? 0;
    if (score > current) {
      await prefs.setInt(key, score);
      return score;
    }
    return current;
  }
}
