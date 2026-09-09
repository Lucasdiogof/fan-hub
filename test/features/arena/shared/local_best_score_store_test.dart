import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/arena/shared/local_best_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/club/synthetic_club_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalBestScoreStore — matriz de club scope real', () {
    test(
      'Goiás — legacy sem namespace migra: lê o recorde A e grava goias:arena_best_quiz',
      () async {
        SharedPreferences.setMockInitialValues({'arena_best_quiz': 8});
        final prefs = await SharedPreferences.getInstance();
        final store = LocalBestScoreStore(goiasClubConfig);

        final best = await store.bestScore('quiz');

        expect(best, 8);
        expect(prefs.getInt('goias:arena_best_quiz'), 8);
      },
    );

    test(
      'Goiás — namespaced já existente vence, nunca sobrescrito pela legacy',
      () async {
        SharedPreferences.setMockInitialValues({
          'arena_best_quiz': 8,
          'goias:arena_best_quiz': 25,
        });
        final prefs = await SharedPreferences.getInstance();
        final store = LocalBestScoreStore(goiasClubConfig);

        final best = await store.bestScore('quiz');

        expect(best, 25);
        expect(prefs.getInt('arena_best_quiz'), 8); // legacy intocada
      },
    );

    test('club-b — NUNCA lê o recorde legacy do Goiás (isolamento)', () async {
      SharedPreferences.setMockInitialValues({'arena_best_quiz': 8});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalBestScoreStore(syntheticClubBConfig);

      final best = await store.bestScore('quiz');

      expect(best, 0); // nunca herda o 8 do Goiás
      expect(prefs.getInt('club-b:arena_best_quiz'), isNull);
    });

    test(
      'club-b — lê o próprio recorde namespaçado, mesmo com a legacy do Goiás presente',
      () async {
        SharedPreferences.setMockInitialValues({
          'arena_best_quiz': 8,
          'club-b:arena_best_quiz': 3,
        });
        final store = LocalBestScoreStore(syntheticClubBConfig);

        final best = await store.bestScore('quiz');

        expect(best, 3);
      },
    );

    test(
      'saveIfBest só sobrescreve quando o novo score é maior, sempre na chave namespaçada',
      () async {
        SharedPreferences.setMockInitialValues({'goias:arena_best_quiz': 10});
        final prefs = await SharedPreferences.getInstance();
        final store = LocalBestScoreStore(goiasClubConfig);

        final resultLower = await store.saveIfBest('quiz', 5);
        expect(resultLower, 10);
        expect(prefs.getInt('goias:arena_best_quiz'), 10);

        final resultHigher = await store.saveIfBest('quiz', 15);
        expect(resultHigher, 15);
        expect(prefs.getInt('goias:arena_best_quiz'), 15);
        expect(
          prefs.getInt('arena_best_quiz'),
          isNull,
        ); // legacy nunca criada por um write novo
      },
    );

    test(
      'club-b e Goiás mantêm recordes totalmente independentes pro MESMO jogo',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final goiasStore = LocalBestScoreStore(goiasClubConfig);
        final clubBStore = LocalBestScoreStore(syntheticClubBConfig);

        await goiasStore.saveIfBest('quiz', 50);
        await clubBStore.saveIfBest('quiz', 7);

        expect(prefs.getInt('goias:arena_best_quiz'), 50);
        expect(prefs.getInt('club-b:arena_best_quiz'), 7);
        expect(await goiasStore.bestScore('quiz'), 50);
        expect(await clubBStore.bestScore('quiz'), 7);
      },
    );
  });
}
