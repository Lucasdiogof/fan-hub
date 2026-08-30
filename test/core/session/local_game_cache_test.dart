import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/session/local_game_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'remove todas as chaves vinculadas à conta (recorde local + Quem Vestiu o Manto)',
    () async {
      SharedPreferences.setMockInitialValues({
        'arena_best_quiz_torcedor': 8,
        'arena_best_lineup': 20,
        'guess_player_active_round': '{"id":"r1"}',
        'guess_player_stats_played': 12,
        'guess_player_stats_correct': 7,
        'guess_player_seen_ids': ['p1', 'p2'],
        'guess_player_seen_signature': 'abc123',
      });
      final prefs = await SharedPreferences.getInstance();

      await clearAccountScopedLocalCache();

      expect(prefs.getKeys(), isEmpty);
    },
  );

  test(
    'nunca apaga preferências globais do aparelho (tema, idioma, volume)',
    () async {
      SharedPreferences.setMockInitialValues({
        'arena_best_quiz_torcedor': 8,
        'theme_mode': 'dark',
        'app_locale': 'pt',
        'club_song_user_volume': 0.7,
      });
      final prefs = await SharedPreferences.getInstance();

      await clearAccountScopedLocalCache();

      expect(prefs.getKeys(), {
        'theme_mode',
        'app_locale',
        'club_song_user_volume',
      });
    },
  );

  test('idempotente — chamar sem nada pra limpar não quebra', () async {
    SharedPreferences.setMockInitialValues({});
    await clearAccountScopedLocalCache();
  });
}
