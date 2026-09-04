import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_registry.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/resolve_active_club.dart';

void main() {
  group('resolveActiveClub — compatibilidade e fail-fast', () {
    test('APP_CLUB ausente (string vazia) -> Goiás, silenciosamente (comportamento de hoje, todo build real)', () {
      final config = resolveActiveClub('');
      expect(config, same(goiasClubConfig));
      expect(config.identity.code, 'goias');
    });

    test('APP_CLUB="goias" (explícito, válido) -> Goiás', () {
      final config = resolveActiveClub('goias');
      expect(config, same(goiasClubConfig));
    });

    test(
      'teste crítico anti-vazamento: nenhum código de clube desconhecido resolve pro Goiás, '
      'mesmo variações plausíveis de digitação/caixa/espaço (nem o antigo código sintético club-b, já removido)',
      () {
        for (final invalid in ['goia', 'goiass', 'GOIAS', ' goias', 'goias ', 'club-b', 'clubb', 'other-club', '0']) {
          expect(
            () => resolveActiveClub(invalid),
            throwsStateError,
            reason: 'APP_CLUB="$invalid" não pode resolver pro Goiás nem pra nenhum clube por acidente',
          );
        }
      },
    );

    test('mensagem de erro do fail-fast é acionável — cita o valor recebido e os clubes disponíveis', () {
      try {
        resolveActiveClub('xyz');
        fail('deveria ter lançado');
      } on StateError catch (e) {
        expect(e.message, contains('xyz'));
        expect(e.message, contains('goias'));
        expect(e.message, contains('bragantino'));
      }
    });
  });

  group('resolveActiveClub — M4: Bragantino é clube REAL no registry (não mais sintético)', () {
    test('APP_CLUB="bragantino" -> resolve pra bragantinoClubConfig via registry normal', () {
      final config = resolveActiveClub('bragantino');
      expect(config, same(bragantinoClubConfig));
      expect(config.identity.code, 'bragantino');
    });

    test('o antigo gate sintético sumiu: club-b não é especial, é só um código desconhecido -> fail-fast', () {
      expect(() => resolveActiveClub('club-b'), throwsStateError);
    });
  });

  group('clubRegistry — M4: Goiás + Bragantino', () {
    test('registry tem exatamente 2 entradas: goias e bragantino', () {
      expect(clubRegistry.length, 2);
      expect(clubRegistry.keys.toSet(), {'goias', 'bragantino'});
    });

    test('nenhum clube sintético/placeholder cadastrado (club-b/clubb removidos)', () {
      expect(clubRegistry.containsKey('club-b'), isFalse);
      expect(clubRegistry.containsKey('clubb'), isFalse);
      expect(clubRegistry.containsKey('club_b'), isFalse);
    });
  });

  group('goiasClubConfig — valores reais, zero mudança de comportamento', () {
    test('identity bate com o UUID canônico já usado pela fundação multiclub (Etapas B-F7)', () {
      expect(goiasClubConfig.identity.canonicalClubId, '4c16340d-300c-5ab2-903f-17519db9b146');
      expect(goiasClubConfig.identity.code, 'goias');
      expect(goiasClubConfig.identity.slug, 'goias');
    });

    test('integrations bate com o oneFootballTeamId hoje hardcoded em Team.goiasId', () {
      expect(goiasClubConfig.integrations.oneFootballTeamId, 1863);
      expect(goiasClubConfig.integrations.oneFootballSlug, 'goias-1863');
    });

    test('branding embrulha os MESMOS valores estáticos de AppColors, nunca uma cópia divergente', () {
      expect(goiasClubConfig.branding.light.primary, isNotNull);
      expect(goiasClubConfig.branding.dark.primary, isNotNull);
    });

    test('capabilities.enabledArenaGames reflete os 6 jogos reais cadastrados no ArenaCatalog (penalty fica de fora, está oculto no produto)', () {
      expect(goiasClubConfig.capabilities.enabledArenaGames, {
        'quiz', 'lineup', 'career_path', 'guess_player', 'player_identity', 'tactical_identity',
      });
      expect(goiasClubConfig.capabilities.enabledArenaGames.contains('penalty'), isFalse);
    });
  });

  group('bragantinoClubConfig — onboarding mínimo: capabilities OFF, sem dado do Goiás', () {
    test('identity básica correta + canonicalClubId é PLACEHOLDER (nunca o do Goiás)', () {
      expect(bragantinoClubConfig.identity.code, 'bragantino');
      expect(bragantinoClubConfig.identity.displayName, 'Red Bull Bragantino');
      expect(bragantinoClubConfig.identity.canonicalClubId, isNot(goiasClubConfig.identity.canonicalClubId));
    });

    test('TODAS as capabilities começam desligadas e enabledArenaGames vazio (nenhum dado real ainda)', () {
      final c = bragantinoClubConfig.capabilities;
      expect(c.hasMembership, isFalse);
      expect(c.hasStore, isFalse);
      expect(c.hasTickets, isFalse);
      expect(c.hasCrowdLineup, isFalse);
      expect(c.hasPassport, isFalse);
      expect(c.hasNews, isFalse);
      expect(c.hasSocial, isFalse);
      expect(c.hasClubContent, isFalse);
      expect(c.enabledArenaGames, isEmpty);
    });

    test('não reusa asset nem cor do Goiás — assets apontam pra placeholder do bragantino', () {
      expect(bragantinoClubConfig.assets.crest, contains('branding/bragantino/'));
      expect(bragantinoClubConfig.assets.crest, isNot(goiasClubConfig.assets.crest));
      expect(bragantinoClubConfig.branding.light.primary, isNot(goiasClubConfig.branding.light.primary));
    });

    test('splashVideo é null — nunca cai pro goias_splash.mp4', () {
      expect(bragantinoClubConfig.assets.splashVideo, isNull);
    });
  });

  group('goiasClubConfig — feature "Clube" e splash continuam ligados', () {
    test('hasClubContent=true e splashVideo aponta pro vídeo oficial do Goiás', () {
      expect(goiasClubConfig.capabilities.hasClubContent, isTrue);
      expect(
        goiasClubConfig.assets.splashVideo,
        'lib/assets/videos/goias_splash.mp4',
      );
    });
  });

  group(
    'INVARIANTE — hasMatches=true exige workerBaseUrl configurado (auditoria Matches/football)',
    () {
      test(
        'para TODO clube em clubRegistry: hasMatches=true implica workerBaseUrl != null e não vazio '
        '(nunca liga a aba/rota de Jogos sem um Worker de verdade pra falar)',
        () {
          for (final entry in clubRegistry.entries) {
            final config = entry.value;
            if (config.capabilities.hasMatches) {
              expect(
                config.integrations.workerBaseUrl,
                isNotNull,
                reason: '${entry.key}: hasMatches=true mas workerBaseUrl é null',
              );
              expect(
                config.integrations.workerBaseUrl,
                isNotEmpty,
                reason: '${entry.key}: hasMatches=true mas workerBaseUrl é vazio',
              );
            }
          }
        },
      );

      test('Goiás: hasMatches=true + workerBaseUrl real -> combinação válida', () {
        expect(goiasClubConfig.capabilities.hasMatches, isTrue);
        expect(goiasClubConfig.integrations.workerBaseUrl, isNotNull);
        expect(goiasClubConfig.integrations.workerBaseUrl, isNotEmpty);
      });

      test(
        'Bragantino: Worker deployado e validado em 2026-09-04 -> hasMatches=true + '
        'workerBaseUrl real, os dois juntos (nunca um sem o outro)',
        () {
          expect(bragantinoClubConfig.capabilities.hasMatches, isTrue);
          expect(bragantinoClubConfig.integrations.workerBaseUrl, isNotNull);
          expect(bragantinoClubConfig.integrations.workerBaseUrl, isNotEmpty);
          expect(bragantinoClubConfig.integrations.workerBaseUrl, isNot(goiasClubConfig.integrations.workerBaseUrl));
        },
      );
    },
  );
}
