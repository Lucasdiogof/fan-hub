import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/club/synthetic_club_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuessPlayerStorage — matriz de club scope real (int: loadStats)', () {
    test(
      'Goiás — legacy sem namespace migra: lê o valor A e grava goias:guess_player_stats_played',
      () async {
        SharedPreferences.setMockInitialValues({
          'guess_player_stats_played': 12,
        });
        final prefs = await SharedPreferences.getInstance();
        final storage = GuessPlayerStorage(goiasClubConfig);

        final stats = await storage.loadStats();

        expect(stats.played, 12);
        expect(prefs.getInt('goias:guess_player_stats_played'), 12);
      },
    );

    test(
      'Goiás — namespaced já existente vence, nunca sobrescrito pela legacy',
      () async {
        SharedPreferences.setMockInitialValues({
          'guess_player_stats_played': 12,
          'goias:guess_player_stats_played': 30,
        });
        final prefs = await SharedPreferences.getInstance();
        final storage = GuessPlayerStorage(goiasClubConfig);

        final stats = await storage.loadStats();

        expect(stats.played, 30);
        expect(
          prefs.getInt('guess_player_stats_played'),
          12,
        ); // legacy intocada
      },
    );

    test('club-b — NUNCA lê a chave legacy do Goiás (isolamento)', () async {
      SharedPreferences.setMockInitialValues({'guess_player_stats_played': 12});
      final prefs = await SharedPreferences.getInstance();
      final storage = GuessPlayerStorage(syntheticClubBConfig);

      final stats = await storage.loadStats();

      expect(stats.played, 0); // nunca herda o 12 do Goiás
      expect(
        prefs.getInt('club-b:guess_player_stats_played'),
        isNull,
      ); // nunca migra o dado do Goiás
    });

    test(
      'club-b — lê o próprio valor namespaçado, mesmo com a legacy do Goiás presente',
      () async {
        SharedPreferences.setMockInitialValues({
          'guess_player_stats_played': 12,
          'club-b:guess_player_stats_played': 4,
        });
        final storage = GuessPlayerStorage(syntheticClubBConfig);

        final stats = await storage.loadStats();

        expect(stats.played, 4);
      },
    );
  });

  group(
    'GuessPlayerStorage — matriz de club scope real (String: loadSeenSignature)',
    () {
      test('Goiás migra a assinatura legacy', () async {
        SharedPreferences.setMockInitialValues({
          'guess_player_seen_signature': 'legacy-sig',
        });
        final prefs = await SharedPreferences.getInstance();
        final storage = GuessPlayerStorage(goiasClubConfig);

        expect(await storage.loadSeenSignature(), 'legacy-sig');
        expect(
          prefs.getString('goias:guess_player_seen_signature'),
          'legacy-sig',
        );
      });

      test('club-b nunca lê a assinatura legacy do Goiás', () async {
        SharedPreferences.setMockInitialValues({
          'guess_player_seen_signature': 'legacy-sig',
        });
        final storage = GuessPlayerStorage(syntheticClubBConfig);

        expect(await storage.loadSeenSignature(), isNull);
      });
    },
  );

  group(
    'GuessPlayerStorage — matriz de club scope real (List<String>: loadSeenIds)',
    () {
      test('Goiás migra os ids vistos legacy', () async {
        SharedPreferences.setMockInitialValues({
          'guess_player_seen_ids': ['p1', 'p2'],
        });
        final prefs = await SharedPreferences.getInstance();
        final storage = GuessPlayerStorage(goiasClubConfig);

        expect(await storage.loadSeenIds(), {'p1', 'p2'});
        expect(prefs.getStringList('goias:guess_player_seen_ids'), [
          'p1',
          'p2',
        ]);
      });

      test(
        'club-b nunca lê os ids vistos legacy do Goiás — começa vazio, próprio',
        () async {
          SharedPreferences.setMockInitialValues({
            'guess_player_seen_ids': ['p1', 'p2'],
            'club-b:guess_player_seen_ids': ['x1'],
          });
          final storage = GuessPlayerStorage(syntheticClubBConfig);

          expect(await storage.loadSeenIds(), {'x1'});
        },
      );

      test(
        'addSeenId grava sempre na chave namespaçada, nunca na legacy',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final storage = GuessPlayerStorage(goiasClubConfig);

          await storage.addSeenId('novo');

          expect(prefs.getStringList('goias:guess_player_seen_ids'), ['novo']);
          expect(prefs.getStringList('guess_player_seen_ids'), isNull);
        },
      );
    },
  );
}
