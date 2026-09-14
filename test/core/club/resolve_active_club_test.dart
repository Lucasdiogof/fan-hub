import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_registry.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/resolve_active_club.dart';

void main() {
  group('resolveActiveClub — compatibilidade e fail-fast', () {
    test(
      'APP_CLUB ausente (string vazia) -> Goiás, silenciosamente (comportamento de hoje, todo build real)',
      () {
        final config = resolveActiveClub('');
        expect(config, same(goiasClubConfig));
        expect(config.identity.code, 'goias');
      },
    );

    test('APP_CLUB="goias" (explícito, válido) -> Goiás', () {
      final config = resolveActiveClub('goias');
      expect(config, same(goiasClubConfig));
    });

    test(
      'teste crítico anti-vazamento: nenhum código de clube desconhecido resolve pro Goiás, '
      'mesmo variações plausíveis de digitação/caixa/espaço (nem o antigo código sintético club-b, já removido)',
      () {
        for (final invalid in [
          'goia',
          'goiass',
          'GOIAS',
          ' goias',
          'goias ',
          'club-b',
          'clubb',
          'other-club',
          '0',
        ]) {
          expect(
            () => resolveActiveClub(invalid),
            throwsStateError,
            reason:
                'APP_CLUB="$invalid" não pode resolver pro Goiás nem pra nenhum clube por acidente',
          );
        }
      },
    );

    test(
      'mensagem de erro do fail-fast é acionável — cita o valor recebido e os clubes disponíveis',
      () {
        try {
          resolveActiveClub('xyz');
          fail('deveria ter lançado');
        } on StateError catch (e) {
          expect(e.message, contains('xyz'));
          expect(e.message, contains('goias'));
          expect(e.message, contains('bragantino'));
        }
      },
    );
  });

  group(
    'resolveActiveClub — M4: Bragantino é clube REAL no registry (não mais sintético)',
    () {
      test(
        'APP_CLUB="bragantino" -> resolve pra bragantinoClubConfig via registry normal',
        () {
          final config = resolveActiveClub('bragantino');
          expect(config, same(bragantinoClubConfig));
          expect(config.identity.code, 'bragantino');
        },
      );

      test(
        'o antigo gate sintético sumiu: club-b não é especial, é só um código desconhecido -> fail-fast',
        () {
          expect(() => resolveActiveClub('club-b'), throwsStateError);
        },
      );
    },
  );

  group('clubRegistry — M4: Goiás + Bragantino', () {
    test('registry tem exatamente 2 entradas: goias e bragantino', () {
      expect(clubRegistry.length, 2);
      expect(clubRegistry.keys.toSet(), {'goias', 'bragantino'});
    });

    test(
      'nenhum clube sintético/placeholder cadastrado (club-b/clubb removidos)',
      () {
        expect(clubRegistry.containsKey('club-b'), isFalse);
        expect(clubRegistry.containsKey('clubb'), isFalse);
        expect(clubRegistry.containsKey('club_b'), isFalse);
      },
    );
  });

  group('goiasClubConfig — valores reais, zero mudança de comportamento', () {
    test(
      'identity bate com o UUID canônico já usado pela fundação multiclub (Etapas B-F7)',
      () {
        expect(
          goiasClubConfig.identity.canonicalClubId,
          '4c16340d-300c-5ab2-903f-17519db9b146',
        );
        expect(goiasClubConfig.identity.code, 'goias');
        expect(goiasClubConfig.identity.slug, 'goias');
      },
    );

    test(
      'integrations bate com o oneFootballTeamId hoje hardcoded em Team.goiasId',
      () {
        expect(goiasClubConfig.integrations.oneFootballTeamId, 1863);
        expect(goiasClubConfig.integrations.oneFootballSlug, 'goias-1863');
      },
    );

    test(
      'branding embrulha os MESMOS valores estáticos de AppColors, nunca uma cópia divergente',
      () {
        expect(goiasClubConfig.branding.light.primary, isNotNull);
        expect(goiasClubConfig.branding.dark.primary, isNotNull);
      },
    );

    test(
      'capabilities.enabledArenaGames reflete os 6 jogos reais cadastrados no ArenaCatalog (penalty fica de fora, está oculto no produto)',
      () {
        expect(goiasClubConfig.capabilities.enabledArenaGames, {
          'quiz',
          'lineup',
          'career_path',
          'guess_player',
          'player_identity',
          'tactical_identity',
        });
        expect(
          goiasClubConfig.capabilities.enabledArenaGames.contains('penalty'),
          isFalse,
        );
      },
    );
  });

  group('bragantinoClubConfig — onboarding real, sem dado/asset do Goiás', () {
    test(
      'identity básica correta + canonicalClubId é PLACEHOLDER (nunca o do Goiás)',
      () {
        expect(bragantinoClubConfig.identity.code, 'bragantino');
        expect(
          bragantinoClubConfig.identity.displayName,
          'Red Bull Bragantino',
        );
        expect(
          bragantinoClubConfig.identity.canonicalClubId,
          isNot(goiasClubConfig.identity.canonicalClubId),
        );
      },
    );

    test(
      'capabilities sem dado real nenhum continuam desligadas (exceto News/Social e os 2 jogos de identidade desde 2026-09-08; Loja e Sócio Massa Bruta escondidos desde 2026-09-14 pro envio às lojas)',
      () {
        final c = bragantinoClubConfig.capabilities;
        // Sócio Massa Bruta (planos reais Bronze/Prata/Ouro/Platina, ver
        // MembershipProgramConfig) e Loja (catálogo real da Red Bull Shop)
        // já existem prontos no backend, mas ficam escondidos temporariamente
        // pro envio às lojas — checkout continua mockado, ver comentário em
        // bragantino_club_config.dart.
        expect(c.hasMembership, isFalse);
        expect(c.hasStore, isFalse);
        expect(c.hasTickets, isFalse);
        expect(c.hasCrowdLineup, isFalse);
        // News tem fonte oficial real no Worker (API JSON própria). Social
        // (YouTube @MassaBrutaTV) confirmado ao vivo contra a Data API v3
        // real — 15 vídeos reais devolvidos pelo Worker, isolamento
        // cross-club intacto (`?club=goias` no deploy do Bragantino segue
        // 404). Instagram/X seguem sem config própria, mas isso nunca
        // derruba o feed inteiro (`Promise.allSettled` por provider).
        expect(c.hasNews, isTrue);
        expect(c.hasSocial, isTrue);
        // player_identity e tactical_identity: datasets próprios do
        // Bragantino auditados, simulados e corrigidos (ver
        // `bragantino_player_identity_references.dart` e
        // `bragantino_tactical_coach_references.dart`) — ligados em
        // 2026-09-08. quiz (44 perguntas READY) e career_path (27
        // carreiras publicáveis) ligados no mesmo dia, depois de auditoria
        // real. guess_player e lineup ligados em 2026-09-11 após
        // reauditoria: 50/50 guess_players `verified`+elegíveis, 31/31
        // lineup_matches com 11 jogadores completos cada.
        expect(
          c.enabledArenaGames,
          equals({
            'player_identity',
            'tactical_identity',
            'quiz',
            'career_path',
            'guess_player',
            'lineup',
          }),
        );
      },
    );

    // 2026-09-05/06 (M4.3): história/títulos/hino têm conteúdo real e
    // pesquisado (ver `BragantinoHistoryData`/`BragantinoTitlesData`/
    // `BragantinoSongsData`), e 12 parceiros confirmados com URL oficial
    // (ver `BragantinoPartnersData`, +2 em 2026-09-07) — as duas
    // capabilities ligam de verdade, não mais "tudo desligado até ter
    // QUALQUER dado".
    test(
      'hasClubContent/hasPartners ligam quando o conteúdo passa a existir',
      () {
        final c = bragantinoClubConfig.capabilities;
        expect(c.hasClubContent, isTrue);
        expect(c.hasPartners, isTrue);
      },
    );

    // 2026-09-07: as 186 partidas e os 49 estádios do Bragantino estão no
    // Supabase dele, a auditoria pós-importação passou, E a identidade da tela
    // agora é própria (`bragantinoPassportContent`) — nenhuma string do Goiás
    // vaza mais. Por isso a capability sobe pra true de verdade, não mais
    // provisória; fica separado do "tudo desligado" acima porque é a única
    // capability ligada do Bragantino hoje.
    test('hasPassport ligado — dado real importado e identidade própria', () {
      expect(bragantinoClubConfig.capabilities.hasPassport, isTrue);
    });

    test(
      'não reusa asset nem cor do Goiás — assets apontam pra placeholder do bragantino',
      () {
        expect(
          bragantinoClubConfig.assets.crest,
          contains('branding/bragantino/'),
        );
        expect(
          bragantinoClubConfig.assets.crest,
          isNot(goiasClubConfig.assets.crest),
        );
        expect(
          bragantinoClubConfig.branding.light.primary,
          isNot(goiasClubConfig.branding.light.primary),
        );
      },
    );

    test('splashVideo é null — nunca cai pro goias_splash.mp4', () {
      expect(bragantinoClubConfig.assets.splashVideo, isNull);
    });
  });

  group('goiasClubConfig — feature "Clube" e splash continuam ligados', () {
    test(
      'hasClubContent=true e splashVideo aponta pro vídeo oficial do Goiás',
      () {
        expect(goiasClubConfig.capabilities.hasClubContent, isTrue);
        expect(
          goiasClubConfig.assets.splashVideo,
          'lib/assets/videos/goias_splash.mp4',
        );
      },
    );
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
                reason:
                    '${entry.key}: hasMatches=true mas workerBaseUrl é null',
              );
              expect(
                config.integrations.workerBaseUrl,
                isNotEmpty,
                reason:
                    '${entry.key}: hasMatches=true mas workerBaseUrl é vazio',
              );
            }
          }
        },
      );

      test(
        'Goiás: hasMatches=true + workerBaseUrl real -> combinação válida',
        () {
          expect(goiasClubConfig.capabilities.hasMatches, isTrue);
          expect(goiasClubConfig.integrations.workerBaseUrl, isNotNull);
          expect(goiasClubConfig.integrations.workerBaseUrl, isNotEmpty);
        },
      );

      test(
        'Bragantino: Worker deployado e validado em 2026-09-04 -> hasMatches=true + '
        'workerBaseUrl real, os dois juntos (nunca um sem o outro)',
        () {
          expect(bragantinoClubConfig.capabilities.hasMatches, isTrue);
          expect(bragantinoClubConfig.integrations.workerBaseUrl, isNotNull);
          expect(bragantinoClubConfig.integrations.workerBaseUrl, isNotEmpty);
          expect(
            bragantinoClubConfig.integrations.workerBaseUrl,
            isNot(goiasClubConfig.integrations.workerBaseUrl),
          );
        },
      );
    },
  );
}
