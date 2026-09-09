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

  // ==========================================================================
  // M3.3 (rodada de hardening) — as chaves reais agora vivem namespaçadas
  // por clube (`<clubCode>:arena_best_<gameId>`, `<clubCode>:guess_player_*`
  // — ver ClubScopedStorageKey). O cleanup precisa continuar limpando TANTO
  // a variante namespaçada de QUALQUER clube QUANTO a legacy sem namespace
  // (pré-M3.3, ainda pode existir num aparelho que nunca abriu o app desde
  // a migração) — num único passe, sem depender de saber qual é o clube
  // ativo. Comportamento real de storage, não só checagem de string.
  // ==========================================================================
  test(
    'remove as variantes namespaçadas por clube (goias: e club-b:) das chaves de jogo',
    () async {
      SharedPreferences.setMockInitialValues({
        'goias:arena_best_quiz_torcedor': 8,
        'goias:guess_player_active_round': '{"id":"r1"}',
        'goias:guess_player_stats_played': 12,
        'club-b:arena_best_lineup': 15,
        'club-b:guess_player_seen_ids': ['x1'],
      });
      final prefs = await SharedPreferences.getInstance();

      await clearAccountScopedLocalCache();

      expect(prefs.getKeys(), isEmpty);
    },
  );

  test(
    'remove a mistura real de legacy + namespaçado goias + namespaçado club-b ao mesmo tempo, sem depender do clube ativo',
    () async {
      SharedPreferences.setMockInitialValues({
        'arena_best_quiz_torcedor': 5, // legacy, pré-M3.3
        'goias:arena_best_quiz_torcedor': 8, // já migrada
        'club-b:arena_best_quiz_torcedor': 3, // clube sintético, mesma etapa
        'guess_player_seen_signature': 'legacy-sig',
        'goias:guess_player_seen_signature': 'goias-sig',
      });
      final prefs = await SharedPreferences.getInstance();

      await clearAccountScopedLocalCache();

      expect(prefs.getKeys(), isEmpty);
    },
  );

  test(
    'preferências globais (tema/idioma/volume do hino) continuam preservadas mesmo com chaves namespaçadas de jogo presentes',
    () async {
      SharedPreferences.setMockInitialValues({
        'goias:arena_best_quiz_torcedor': 8,
        'club-b:guess_player_stats_played': 4,
        'theme_mode': 'dark',
        'app_locale': 'pt',
        'club_song_user_volume':
            0.7, // nunca namespaçado — ver M3.3 §"LOCAL_STORAGE_SCOPE_NOT_REQUIRED"
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

  test(
    'nunca remove uma chave de OUTRA feature que só por coincidência contém a substring "arena_best_" no meio do nome',
    () async {
      // Prova que a checagem é robusta o bastante pra não virar um match
      // acidental largo demais — mesmo com `contains` (não `startsWith`), só
      // remove o que realmente é uma chave de jogo (própria ou namespaçada).
      SharedPreferences.setMockInitialValues({
        'goias:arena_best_quiz_torcedor': 8,
        'some_unrelated_config_key': 'nunca deveria ser removida',
      });
      final prefs = await SharedPreferences.getInstance();

      await clearAccountScopedLocalCache();

      expect(prefs.getKeys(), {'some_unrelated_config_key'});
    },
  );
}
