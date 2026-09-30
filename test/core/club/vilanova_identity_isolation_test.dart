// Flavor Vila Nova (F1–F3). Trava que nome/escudo/cores/ícones/integrações e
// o conteúdo institucional do Vila nunca coincidem com os do Goiás (rival
// local) nem com os do Bragantino, e que só as capabilities já validadas
// estão ligadas.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/club/data/vilanova_history_data.dart';
import 'package:goias_app/features/club/data/vilanova_idols_data.dart';
import 'package:goias_app/features/club/data/vilanova_timeline_data.dart';
import 'package:goias_app/features/club/data/vilanova_titles_data.dart';

void main() {
  final others = <String, ClubConfig>{
    'goias': goiasClubConfig,
    'bragantino': bragantinoClubConfig,
  };
  final v = vilaNovaClubConfig;

  group('Identidade — Vila Nova nunca coincide com outro clube', () {
    for (final entry in others.entries) {
      test('code/slug/nomes/torcida/clubId distintos de ${entry.key}', () {
        final o = entry.value.identity;
        expect(v.identity.code, isNot(o.code));
        expect(v.identity.slug, isNot(o.slug));
        expect(v.identity.displayName, isNot(o.displayName));
        expect(v.identity.shortName, isNot(o.shortName));
        expect(v.identity.fanDemonym, isNot(o.fanDemonym));
        expect(v.identity.canonicalClubId, isNot(o.canonicalClubId));
      });

      test('paleta (light/dark) distinta de ${entry.key}', () {
        expect(
          v.branding.light.primary,
          isNot(entry.value.branding.light.primary),
        );
        expect(
          v.branding.dark.primary,
          isNot(entry.value.branding.dark.primary),
        );
      });

      test(
        'integrações (OneFootball/prefixo de pedido) distintas de ${entry.key}',
        () {
          final o = entry.value.integrations;
          expect(v.integrations.oneFootballTeamId, isNot(o.oneFootballTeamId));
          expect(v.integrations.oneFootballSlug, isNot(o.oneFootballSlug));
          expect(v.integrations.orderPrefix, isNot(o.orderPrefix));
        },
      );
    }

    test('textos do Vila nunca carregam identidade do Goiás/Bragantino', () {
      final texts = [
        v.identity.displayName,
        v.identity.shortName,
        v.identity.fanDemonym,
        v.productNames.arenaName,
        v.productNames.passportName,
        v.productNames.storeName,
        v.productNames.membershipProgramName,
        v.passportContent.pt.title,
        v.passportContent.pt.shareText,
        v.passportContent.pt.levels.legend,
      ];
      for (final text in texts) {
        for (final leaked in [
          'Goiás',
          'Esmeraldin',
          'Verdão',
          'Serrinha',
          'Bragantino',
          'Massa Bruta',
          'Red Bull',
        ]) {
          expect(
            text.toLowerCase(),
            isNot(contains(leaked.toLowerCase())),
            reason: '"$text" contém identidade de outro clube ("$leaked")',
          );
        }
      }
    });

    test('todo asset do Vila mora na pasta do Vila e existe no disco', () {
      final a = v.assets;
      for (final path in [
        a.crest,
        a.crestBadge,
        a.crest3d,
        a.loginBackground,
        a.tacticsBoardIllustration,
        a.arenaStadiumIcon,
        a.arenaStadiumPhoto,
        a.storeBanner,
      ]) {
        expect(path, startsWith('lib/assets/branding/vilanova/'));
        expect(File(path).existsSync(), isTrue, reason: 'asset ausente: $path');
      }
    });
  });

  group('Capabilities — só o que já foi validado está ligado', () {
    test(
      'F3/F4 ligaram hasClubContent; o resto sem Supabase ainda segue desligado',
      () {
        final c = v.capabilities;
        expect(c.hasClubContent, isTrue);
        expect([
          c.hasMembership,
          c.hasStore,
          c.hasTickets,
          c.hasCrowdLineup,
          c.hasPassport,
          c.hasNews,
          c.hasSocial,
          c.hasPartners,
          c.hasMatches,
        ], everyElement(isFalse));
      },
    );

    test(
      'F5: 5 dos 6 jogos da Arena ligados, guess_player fica de fora (0 elegível como segredo)',
      () {
        expect(v.capabilities.enabledArenaGames, {
          'quiz',
          'lineup',
          'player_identity',
          'tactical_identity',
          'career_path',
        });
        expect(
          v.capabilities.enabledArenaGames,
          isNot(contains('guess_player')),
        );
      },
    );

    test(
      'Supabase do próprio Vila (projeto vkybbrfvmexevakknlsi) — nunca aponta pro de outro clube',
      () {
        expect(
          v.integrations.supabaseUrl,
          'https://vkybbrfvmexevakknlsi.supabase.co',
        );
        expect(v.integrations.supabasePublishableKey, isNotNull);
        expect(
          v.integrations.supabaseUrl,
          isNot(goiasClubConfig.integrations.supabaseUrl),
        );
        expect(
          v.integrations.supabaseUrl,
          isNot(bragantinoClubConfig.integrations.supabaseUrl),
        );
      },
    );

    test('Worker/redirect ainda null — F8 não chegou', () {
      expect(v.integrations.workerBaseUrl, isNull);
      expect(v.integrations.supabaseRedirectUrl, isNull);
    });
  });

  group(
    'Ícones e Firebase — Vila Nova nunca reaproveita os de outro clube',
    () {
      const densities = [
        'mipmap-hdpi',
        'mipmap-mdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];
      for (final density in densities) {
        test('ic_launcher ($density) distinto do Goiás e do Bragantino', () {
          final vila = File(
            'android/app/src/vilanova/res/$density/ic_launcher.png',
          ).readAsBytesSync();
          for (final other in ['main', 'bragantino']) {
            final otherIcon = File(
              'android/app/src/$other/res/$density/ic_launcher.png',
            ).readAsBytesSync();
            expect(vila, isNot(equals(otherIcon)), reason: '$other/$density');
          }
        });
      }

      test(
        'google-services.json do flavor tem o client br.com.fanhub.vilanova',
        () {
          final json = File(
            'android/app/src/vilanova/google-services.json',
          ).readAsStringSync();
          expect(json, contains('"package_name": "br.com.fanhub.vilanova"'));
          expect(json, contains('"project_id": "fan-hub-29e9b"'));
        },
      );

      test('plist iOS do flavor é do bundle br.com.fanhub.vilanova', () {
        final plist = File(
          'ios/Runner/Firebase/vilanova/GoogleService-Info.plist',
        ).readAsStringSync();
        expect(plist, contains('<string>br.com.fanhub.vilanova</string>'));
      });
    },
  );

  group('F3 — conteúdo institucional do Vila', () {
    final content = v.institutionalContent;

    test('aponta pras classes estáticas do próprio Vila', () {
      expect(content.history, same(VilaNovaHistoryData.sections));
      expect(content.timeline, same(VilaNovaTimelineData.events));
      expect(content.titles, same(VilaNovaTitlesData.groups));
      expect(
        content.historicalCampaigns,
        same(VilaNovaTitlesData.historicalCampaigns),
      );
      expect(content.idols, same(VilaNovaIdolsData.idols));
    });

    test('parceiros e músicas vazios (lista incompleta / só metadados)', () {
      expect(content.partners, isEmpty);
      expect(content.songs, isEmpty);
    });

    test('16 Goianos e 3 Séries C, como no site oficial', () {
      int count(String name) =>
          content.titles.firstWhere((g) => g.competitionName == name).count;
      expect(count('Campeonato Goiano'), 16);
      expect(count('Campeonato Brasileiro Série C'), 3);
    });

    test('vice nunca é título: Copa Verde só em historicalCampaigns', () {
      expect(
        content.titles.map((g) => g.competitionName),
        isNot(contains(contains('Copa Verde'))),
      );
      expect(content.historicalCampaigns.map((c) => c.year), [
        2021,
        2022,
        2024,
      ]);
    });

    test('Túlio (números em conflito) nunca é publicado', () {
      expect(
        content.publishedIdols.map((i) => i.name),
        isNot(contains('Túlio Maravilha')),
      );
      expect(content.publishedIdols, hasLength(9));
    });

    test('nenhum texto institucional carrega identidade de outro clube nem '
        'nota interna de pesquisa', () {
      final texts = [
        for (final s in content.history) ...[s.title, ...s.paragraphs],
        for (final e in content.timeline) ...[e.title, e.description ?? ''],
        for (final i in content.publishedIdols) i.description,
      ];
      for (final text in texts) {
        for (final leaked in [
          'Esmeraldin',
          'Verdão',
          'Serrinha',
          'Bragantino',
          'Massa Bruta',
          'acervo',
          'snapshot',
          'lote',
          'REVIEW',
          'listad',
        ]) {
          expect(
            text.toLowerCase(),
            isNot(contains(leaked.toLowerCase())),
            reason: '"$text" contém "$leaked"',
          );
        }
      }
    });

    test('linha do tempo em ordem cronológica e sempre com fonte', () {
      final years = content.timeline.map((e) => e.year).toList();
      expect(years, [...years]..sort());
      for (final e in content.timeline) {
        expect(e.sourceUrl, startsWith('https://'), reason: e.title);
      }
    });
  });
}
