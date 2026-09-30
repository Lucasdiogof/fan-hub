// F1/F2 do flavor Vila Nova. Trava que nome/escudo/cores/ícones/integrações
// do Vila nunca coincidem com os do Goiás (rival local) nem com os do
// Bragantino, e que o Vila entra com TODAS as capabilities desligadas até
// cada fase validar o próprio dado.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';

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

  group('F1 — Vila Nova entra com tudo desligado', () {
    test('todas as capabilities false e nenhum jogo da Arena', () {
      final c = v.capabilities;
      expect([
        c.hasMembership,
        c.hasStore,
        c.hasTickets,
        c.hasCrowdLineup,
        c.hasPassport,
        c.hasNews,
        c.hasSocial,
        c.hasClubContent,
        c.hasPartners,
        c.hasMatches,
      ], everyElement(isFalse));
      expect(c.enabledArenaGames, isEmpty);
    });

    test(
      'Worker/Supabase ainda null — nunca apontam pro projeto de outro clube',
      () {
        expect(v.integrations.workerBaseUrl, isNull);
        expect(v.integrations.supabaseUrl, isNull);
        expect(v.integrations.supabasePublishableKey, isNull);
      },
    );
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
}
