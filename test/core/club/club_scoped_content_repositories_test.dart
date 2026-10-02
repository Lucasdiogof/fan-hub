// M3.1 — prova, contra a URL REAL que o postgrest monta a partir de
// `.select()/.eq()/.order()` (via `CapturingHttpClient`, nunca um mock que
// só verifica "devolveu dados"), que as 5 tabelas de conteúdo editorial
// (career_players, guess_players, squad_members, lineup_matches,
// quiz_questions) SEMPRE filtram por `club_id`, e que o fallback nunca
// vaza pra outro clube (NO_CROSS_CLUB_FALLBACK).
//
// Rodada de revisão: matriz completa de 4 cenários por tabela com
// fallback — as duas semânticas de erro NUNCA são conflatadas:
//   sucesso + 0 linhas + sem fallback  -> ClubDataUnavailableException
//   falha real (rede/parse) + sem fallback -> exceção ORIGINAL intacta
//     (mesma instância, `same()` — prova que o stack trace não foi
//     descartado, `Error.throwWithStackTrace` reanexa o original).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_data_unavailable_exception.dart';
import 'package:goias_app/core/club/club_registry.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:goias_app/features/arena/games/career_path/data/career_player_repository.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_catalog.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_repository.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player_photos.dart';
import 'package:goias_app/features/arena/games/lineup/data/lineup_match_repository.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_questions.dart';
import 'package:goias_app/features/squad/data/supabase_squad_repository.dart';
import 'package:goias_app/features/squad/domain/squad_photos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'capturing_http_client.dart';
import 'synthetic_club_config.dart';

SupabaseClient _clientWith(CapturingHttpClient http) => SupabaseClient(
  'https://example.supabase.co',
  'anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
  httpClient: http,
);

/// Captura o que `load()` de fato lança/retorna, sem `expectLater`
/// engolir a instância — pra poder comparar por identidade (`same()`).
Future<Object?> _captureThrow(Future<Object?> Function() load) async {
  try {
    return await load();
  } catch (e) {
    return e;
  }
}

void main() {
  group('CareerPlayerRepository — matriz completa (Goiás/club-b × empty/failure)', () {
    test(
      'query real inclui club_id=eq.<canonicalClubId> do clube ativo',
      () async {
        final http = CapturingHttpClient();
        final repo = CareerPlayerRepository(_clientWith(http), goiasClubConfig);
        await repo.load();
        expect(
          http.lastRequestUrl.toString(),
          contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
        );
      },
    );

    test(
      'Goiás + Supabase vazio (sucesso, 0 linhas) -> fallback DELE (careerPlayers), sem erro',
      () async {
        final repo = CareerPlayerRepository(
          _clientWith(CapturingHttpClient()),
          goiasClubConfig,
        );
        final result = await repo.load();
        expect(result, same(careerPlayers));
      },
    );

    test(
      'Goiás + falha de rede -> Sentry + fallback DELE (careerPlayers), preserva compatibilidade atual',
      () async {
        final http = CapturingHttpClient()
          ..throwError = Exception('network down');
        final repo = CareerPlayerRepository(_clientWith(http), goiasClubConfig);
        final result = await repo.load();
        expect(result, same(careerPlayers));
      },
    );

    test(
      'club-b + Supabase vazio (sucesso, 0 linhas) + sem fallback -> ClubDataUnavailableException',
      () async {
        final http = CapturingHttpClient();
        final repo = CareerPlayerRepository(
          _clientWith(http),
          syntheticClubBConfig,
        );
        final result = await _captureThrow(repo.load);
        expect(result, isA<ClubDataUnavailableException>());
        // a query mesmo assim filtrou pelo club_id do clube sintético, nunca
        // pelo do Goiás — prova que não existe "default" implícito.
        final url = http.lastRequestUrl!.toString();
        expect(
          url,
          contains(
            'club_id=eq.${syntheticClubBConfig.identity.canonicalClubId}',
          ),
        );
        expect(url, isNot(contains(goiasClubConfig.identity.canonicalClubId)));
      },
    );

    test(
      'club-b + falha de rede REAL + sem fallback -> exceção ORIGINAL intacta (NUNCA ClubDataUnavailableException)',
      () async {
        final originalError = Exception('network down — club-b');
        final http = CapturingHttpClient()..throwError = originalError;
        final repo = CareerPlayerRepository(
          _clientWith(http),
          syntheticClubBConfig,
        );
        final result = await _captureThrow(repo.load);
        expect(
          result,
          same(originalError),
          reason:
              'a exceção original precisa subir intacta, com o mesmo stack trace',
        );
        expect(result, isNot(isA<ClubDataUnavailableException>()));
      },
    );
  });

  group('GuessPlayerRepository — matriz completa (Goiás/club-b × empty/failure)', () {
    test(
      'query real inclui club_id=eq.<canonicalClubId> do clube ativo',
      () async {
        final http = CapturingHttpClient();
        final repo = GuessPlayerRepository(_clientWith(http), goiasClubConfig);
        await repo.load();
        expect(
          http.lastRequestUrl.toString(),
          contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
        );
      },
    );

    test(
      'Goiás + Supabase vazio -> fallback DELE (guessPlayerCatalog)',
      () async {
        final repo = GuessPlayerRepository(
          _clientWith(CapturingHttpClient()),
          goiasClubConfig,
        );
        final result = await repo.load();
        expect(result, same(guessPlayerCatalog));
      },
    );

    test(
      'Goiás + falha de rede -> Sentry + fallback DELE (guessPlayerCatalog)',
      () async {
        final http = CapturingHttpClient()
          ..throwError = Exception('network down');
        final repo = GuessPlayerRepository(_clientWith(http), goiasClubConfig);
        final result = await repo.load();
        expect(result, same(guessPlayerCatalog));
      },
    );

    test(
      'club-b + Supabase vazio + sem fallback -> ClubDataUnavailableException',
      () async {
        final repo = GuessPlayerRepository(
          _clientWith(CapturingHttpClient()),
          syntheticClubBConfig,
        );
        final result = await _captureThrow(repo.load);
        expect(result, isA<ClubDataUnavailableException>());
      },
    );

    test(
      'club-b + falha de rede REAL + sem fallback -> exceção ORIGINAL intacta',
      () async {
        final originalError = Exception('network down — club-b');
        final http = CapturingHttpClient()..throwError = originalError;
        final repo = GuessPlayerRepository(
          _clientWith(http),
          syntheticClubBConfig,
        );
        final result = await _captureThrow(repo.load);
        expect(result, same(originalError));
        expect(result, isNot(isA<ClubDataUnavailableException>()));
      },
    );

    // Auditoria 2026-09-05 (Bloco 4): `photo_key` de um ex-jogador (sem
    // foto de elenco atual) resolvia sempre pra `null`, mesmo com o dado
    // presente no banco — só `squadPhotoAssets` era checado. Os 41
    // jogadores históricos com foto (commit "Add 41 historical player
    // photos") nunca apareciam em produção por causa disso.
    test(
      'photo_key de ex-jogador (só em goiasGuessPlayerPhotos, fora do elenco atual) resolve imageUrl',
      () async {
        final row = {
          'id': 'harlei',
          'name': 'Harlei',
          'display_name': 'Harlei',
          'aliases': <String>[],
          'position': 'gol',
          'shirt_number': 1,
          'academy_club': 'Cruzeiro',
          'nationality_code': 'BR',
          'nationality_name': 'Brasil',
          'club_debut_year': 1999,
          'photo_key': 'harlei',
          'data_status': 'verified',
          'person_id': null,
        };
        final http = CapturingHttpClient(responseBody: '[${jsonEncode(row)}]');
        final repo = GuessPlayerRepository(_clientWith(http), goiasClubConfig);
        final result = await repo.load();
        expect(result.single.imageUrl, goiasGuessPlayerPhotos['harlei']);
        expect(result.single.imageUrl, isNotNull);
        expect(result.single.eligibleAsSecret, isTrue);
      },
    );

    // Até 2026-09-08 o repositório caía num mapa GLOBAL de fotos do Goiás
    // quando a chave não estava no mapa do clube ativo. Nenhum id colidia na
    // época, então nunca chegou a mostrar rosto errado — mas `cleiton` já é
    // card do Bragantino e é nome comum o bastante pra colidir a qualquer
    // momento, e o resultado seria um jogador do Goiás dentro do jogo do
    // outro clube.
    test(
      'clube sem a foto NÃO herda a do Goiás — fica sem foto mesmo',
      () async {
        final row = {
          'id': 'harlei',
          'name': 'Harlei',
          'display_name': 'Harlei',
          'aliases': <String>[],
          'position': 'gol',
          'shirt_number': 1,
          'academy_club': null,
          'nationality_code': 'BR',
          'nationality_name': 'Brasil',
          'club_debut_year': 1999,
          // Chave que EXISTE no mapa do Goiás e não no deste clube.
          'photo_key': 'harlei',
          'data_status': 'verified',
          'person_id': null,
        };
        expect(goiasGuessPlayerPhotos.containsKey('harlei'), isTrue);
        expect(
          syntheticClubBConfig.assets.guessPlayerPhotos.containsKey('harlei'),
          isFalse,
        );

        final http = CapturingHttpClient(responseBody: '[${jsonEncode(row)}]');
        final repo = GuessPlayerRepository(
          _clientWith(http),
          syntheticClubBConfig,
        );
        final result = await repo.load();
        expect(
          result.single.imageUrl,
          isNull,
          reason: 'herdar a foto do Goiás mostraria o rosto errado no card',
        );
      },
    );

    test(
      'photo_key do elenco atual continua resolvendo por squadPhotoAssets (nenhuma regressão)',
      () async {
        final row = {
          'id': 'juninho',
          'name': 'Juninho',
          'display_name': 'Juninho',
          'aliases': <String>[],
          'position': 'vol',
          'shirt_number': 8,
          'academy_club': 'Aparecida-GO',
          'nationality_code': 'BR',
          'nationality_name': 'Brasil',
          'club_debut_year': 2025,
          'photo_key': 'juninho',
          'data_status': 'verified',
          'person_id': null,
        };
        final http = CapturingHttpClient(responseBody: '[${jsonEncode(row)}]');
        final repo = GuessPlayerRepository(_clientWith(http), goiasClubConfig);
        final result = await repo.load();
        expect(result.single.imageUrl, squadPhotoAssets['juninho']);
      },
    );

    test('Bragantino: photo_key do elenco atual resolve pela URL remota do '
        'CDN oficial (ClubConfig.assets.guessPlayerPhotos), nunca null nem a '
        'foto de outro clube (2026-09-08, Quem Vestiu o Manto)', () async {
      final row = {
        'id': 'braga_manto_01',
        'name': 'Tiago Volpi',
        'display_name': 'Tiago Volpi',
        'aliases': <String>[],
        'position': 'gol',
        'shirt_number': 18,
        'academy_club': 'São José-RS / Fluminense (base)',
        'nationality_code': null,
        'nationality_name': null,
        'club_debut_year': 2026,
        'photo_key': 'tiago-volpi',
        'data_status': 'verified',
        'person_id': null,
      };
      final http = CapturingHttpClient(responseBody: '[${jsonEncode(row)}]');
      final repo = GuessPlayerRepository(
        _clientWith(http),
        bragantinoClubConfig,
      );
      final result = await repo.load();
      expect(
        result.single.imageUrl,
        bragantinoClubConfig.assets.guessPlayerPhotos['tiago-volpi'],
      );
      expect(result.single.imageUrl, isNotNull);
      expect(
        result.single.imageUrl,
        startsWith('https://img.redbullbragantino.com/'),
      );
      expect(result.single.eligibleAsSecret, isTrue);
    });
  });

  group(
    'LineupMatchRepository — matriz completa (Goiás/club-b × empty/failure)',
    () {
      test(
        'query real inclui club_id=eq.<canonicalClubId> do clube ativo',
        () async {
          final http = CapturingHttpClient();
          final repo = LineupMatchRepository(
            _clientWith(http),
            goiasClubConfig,
          );
          await repo.load();
          expect(
            http.lastRequestUrl.toString(),
            contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
          );
        },
      );

      test(
        'Goiás + Supabase vazio -> fallback DELE (orderedLineupMatches)',
        () async {
          final repo = LineupMatchRepository(
            _clientWith(CapturingHttpClient()),
            goiasClubConfig,
          );
          final result = await repo.load();
          expect(result, same(orderedLineupMatches));
        },
      );

      test(
        'Goiás + falha de rede -> Sentry + fallback DELE (orderedLineupMatches)',
        () async {
          final http = CapturingHttpClient()
            ..throwError = Exception('network down');
          final repo = LineupMatchRepository(
            _clientWith(http),
            goiasClubConfig,
          );
          final result = await repo.load();
          expect(result, same(orderedLineupMatches));
        },
      );

      test(
        'club-b + Supabase vazio + sem fallback -> ClubDataUnavailableException',
        () async {
          final repo = LineupMatchRepository(
            _clientWith(CapturingHttpClient()),
            syntheticClubBConfig,
          );
          final result = await _captureThrow(repo.load);
          expect(result, isA<ClubDataUnavailableException>());
        },
      );

      test(
        'club-b + falha de rede REAL + sem fallback -> exceção ORIGINAL intacta',
        () async {
          final originalError = Exception('network down — club-b');
          final http = CapturingHttpClient()..throwError = originalError;
          final repo = LineupMatchRepository(
            _clientWith(http),
            syntheticClubBConfig,
          );
          final result = await _captureThrow(repo.load);
          expect(result, same(originalError));
          expect(result, isNot(isA<ClubDataUnavailableException>()));
        },
      );
    },
  );

  group(
    'QuizQuestionRepository — matriz completa (Goiás/club-b × empty/failure)',
    () {
      test(
        'query real inclui club_id=eq.<canonicalClubId> do clube ativo',
        () async {
          final http = CapturingHttpClient();
          final repo = QuizQuestionRepository(
            _clientWith(http),
            goiasClubConfig,
          );
          await repo.load();
          expect(
            http.lastRequestUrl.toString(),
            contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
          );
        },
      );

      test('Goiás + Supabase vazio -> fallback DELE (quizQuestions)', () async {
        final repo = QuizQuestionRepository(
          _clientWith(CapturingHttpClient()),
          goiasClubConfig,
        );
        final result = await repo.load();
        expect(result, same(quizQuestions));
      });

      test(
        'Goiás + falha de rede -> Sentry + fallback DELE (quizQuestions)',
        () async {
          final http = CapturingHttpClient()
            ..throwError = Exception('network down');
          final repo = QuizQuestionRepository(
            _clientWith(http),
            goiasClubConfig,
          );
          final result = await repo.load();
          expect(result, same(quizQuestions));
        },
      );

      test(
        'club-b + Supabase vazio + sem fallback -> ClubDataUnavailableException',
        () async {
          final repo = QuizQuestionRepository(
            _clientWith(CapturingHttpClient()),
            syntheticClubBConfig,
          );
          final result = await _captureThrow(repo.load);
          expect(result, isA<ClubDataUnavailableException>());
        },
      );

      test(
        'club-b + falha de rede REAL + sem fallback -> exceção ORIGINAL intacta',
        () async {
          final originalError = Exception('network down — club-b');
          final http = CapturingHttpClient()..throwError = originalError;
          final repo = QuizQuestionRepository(
            _clientWith(http),
            syntheticClubBConfig,
          );
          final result = await _captureThrow(repo.load);
          expect(result, same(originalError));
          expect(result, isNot(isA<ClubDataUnavailableException>()));
        },
      );
    },
  );

  group(
    'SupabaseSquadRepository — tenant scope (sem fallback, F4 — semântica própria preservada)',
    () {
      test(
        'query real inclui club_id=eq.<canonicalClubId> do clube ativo '
        'e active=eq.true (2026-09-07: atleta que saiu nunca aparece)',
        () async {
          final http = CapturingHttpClient();
          final repo = SupabaseSquadRepository(
            _clientWith(http),
            goiasClubConfig,
          );
          await repo.getSquad();
          final url = http.lastRequestUrl.toString();
          expect(
            url,
            contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
          );
          expect(url, contains('active=eq.true'));
        },
      );

      test(
        'club-b + Supabase vazio: Success([]) — contrato já existente da feature, nunca elenco do Goiás',
        () async {
          final http = CapturingHttpClient();
          final repo = SupabaseSquadRepository(
            _clientWith(http),
            syntheticClubBConfig,
          );
          final result = await repo.getSquad();
          expect(result, isA<Success<List<Object?>>>());
          final members = (result as Success).data as List;
          expect(members, isEmpty);
          expect(
            http.lastRequestUrl.toString(),
            contains(
              'club_id=eq.${syntheticClubBConfig.identity.canonicalClubId}',
            ),
          );
        },
      );

      test(
        'club-b + falha de rede REAL: Error/ServerFailure da arquitetura já existente, nunca elenco do Goiás',
        () async {
          final http = CapturingHttpClient()
            ..throwError = Exception('network down — club-b');
          final repo = SupabaseSquadRepository(
            _clientWith(http),
            syntheticClubBConfig,
          );
          final result = await repo.getSquad();
          expect(result, isA<Error<List<Object?>>>());
        },
      );

      test('Bragantino consulta o club_id DELE, nunca o do Goiás', () async {
        final http = CapturingHttpClient();
        final repo = SupabaseSquadRepository(
          _clientWith(http),
          bragantinoClubConfig,
        );
        await repo.getSquad();

        final url = http.lastRequestUrl.toString();
        expect(
          url,
          contains(
            'club_id=eq.${bragantinoClubConfig.identity.canonicalClubId}',
          ),
        );
        expect(url, isNot(contains(goiasClubConfig.identity.canonicalClubId)));
      });
    },
  );

  group(
    'Sanity — datasets de Goiás inalterados (nenhum conteúdo tocado, só tenancy)',
    () {
      test(
        'contagens dos fallbacks batem com o real do Supabase (auditado ao vivo na M2.2A)',
        () {
          expect(careerPlayers.length, 30);
          // 174 - 4 registros sem identidade desabilitados em 2026-10-02
          // (migration 20261002020000).
          expect(guessPlayerCatalog.length, 170);
          expect(orderedLineupMatches.length, 31);
          expect(quizQuestions.length, 60);
        },
      );
    },
  );

  group(
    'Sanity — a fixture sintética syntheticClubBConfig é só de TESTE (nunca no clubRegistry de produção, que hoje tem goias + bragantino)',
    () {
      test(
        'syntheticClubBConfig é distinta do Goiás e nunca cadastrada no registry — só usada direto em teste de isolamento',
        () {
          expect(goiasClubConfig, isA<ClubConfig>());
          expect(syntheticClubBConfig.identity.code, isNot('goias'));
          expect(
            syntheticClubBConfig.identity.canonicalClubId,
            isNot(goiasClubConfig.identity.canonicalClubId),
          );
          expect(clubRegistry.values.contains(syntheticClubBConfig), isFalse);
        },
      );
    },
  );
}
