// Auditoria 2026-09-05 — materialização do flavor Bragantino. Trava que
// nome/escudo/cores/URLs do Bragantino nunca coincidem com os do Goiás
// (achado real nesta rodada: ícone iOS/Web do Bragantino era literalmente
// o escudo do Goiás, por falta de asset catalog/iconsSourceDir próprios).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  group('Identidade — Goiás x Bragantino nunca coincidem', () {
    test('nome/slug/code/torcedor são todos distintos', () {
      final g = goiasClubConfig.identity;
      final b = bragantinoClubConfig.identity;
      expect(b.code, isNot(g.code));
      expect(b.slug, isNot(g.slug));
      expect(b.displayName, isNot(g.displayName));
      expect(b.shortName, isNot(g.shortName));
      expect(b.fanDemonym, isNot(g.fanDemonym));
      expect(b.canonicalClubId, isNot(g.canonicalClubId));
    });

    test('nome do Bragantino nunca menciona identidade do Goiás', () {
      final b = bragantinoClubConfig.identity;
      for (final text in [b.displayName, b.shortName, b.fanDemonym]) {
        for (final leaked in ['Goiás', 'Esmeraldino', 'Verdão', 'Serrinha']) {
          expect(
            text.toLowerCase(),
            isNot(contains(leaked.toLowerCase())),
            reason: '"$text" contém identidade do Goiás ("$leaked")',
          );
        }
      }
    });

    test(
      'caminhos de asset (crest/splash/etc.) são todos distintos dos do Goiás',
      () {
        final g = goiasClubConfig.assets;
        final b = bragantinoClubConfig.assets;
        expect(b.crest, isNot(g.crest));
        expect(b.crestBadge, isNot(g.crestBadge));
        expect(b.crest3d, isNot(g.crest3d));
        expect(b.loginBackground, isNot(g.loginBackground));
        expect(b.stadium, isNot(g.stadium));
        expect(b.matchHero, isNot(g.matchHero));
      },
    );

    test('nenhum caminho de asset do Bragantino aponta pra pasta do Goiás', () {
      final b = bragantinoClubConfig.assets;
      for (final path in [
        b.crest,
        b.crestBadge,
        b.crest3d,
        b.loginBackground,
        b.stadium,
        b.matchHero,
        b.tacticsBoardIllustration,
        b.arenaStadiumIcon,
        b.arenaStadiumPhoto,
        b.storeBanner,
      ]) {
        expect(
          path,
          isNot(contains('branding/goias')),
          reason: 'asset do Bragantino aponta pra pasta do Goiás: $path',
        );
      }
    });

    test('cores de branding (light/dark) são paletas distintas', () {
      expect(
        bragantinoClubConfig.branding.light.primary,
        isNot(goiasClubConfig.branding.light.primary),
      );
      expect(
        bragantinoClubConfig.branding.dark.primary,
        isNot(goiasClubConfig.branding.dark.primary),
      );
    });

    test(
      'URLs/integrações (Worker, Supabase, redirect) são todas distintas',
      () {
        final g = goiasClubConfig.integrations;
        final b = bragantinoClubConfig.integrations;
        expect(b.workerBaseUrl, isNot(g.workerBaseUrl));
        expect(b.supabaseUrl, isNot(g.supabaseUrl));
        expect(b.supabasePublishableKey, isNot(g.supabasePublishableKey));
        expect(b.supabaseRedirectUrl, isNot(g.supabaseRedirectUrl));
        expect(b.orderPrefix, isNot(g.orderPrefix));
      },
    );

    test(
      'applicationId/bundle Android/iOS do Bragantino são distintos dos do Goiás',
      () {
        final buildGradle = File(
          'android/app/build.gradle.kts',
        ).readAsStringSync();
        expect(buildGradle, contains('applicationId = "br.com.fanhub.goias"'));
        expect(
          buildGradle,
          contains('applicationId = "br.com.fanhub.bragantino"'),
        );
      },
    );
  });

  group('Ícones — Bragantino nunca reaproveita o ícone real do Goiás', () {
    test(
      'ícone Android (mipmap) do Bragantino é diferente do Goiás em todas as densidades',
      () {
        const densities = [
          'mipmap-hdpi',
          'mipmap-mdpi',
          'mipmap-xhdpi',
          'mipmap-xxhdpi',
          'mipmap-xxxhdpi',
        ];
        for (final density in densities) {
          final goiasIcon = File(
            'android/app/src/main/res/$density/ic_launcher.png',
          ).readAsBytesSync();
          final bragantinoIcon = File(
            'android/app/src/bragantino/res/$density/ic_launcher.png',
          ).readAsBytesSync();
          expect(
            bragantinoIcon,
            isNot(equals(goiasIcon)),
            reason:
                'ic_launcher.png ($density) do Bragantino é idêntico ao do Goiás',
          );
        }
      },
    );

    test(
      'iOS: as 3 configs (Debug/Release/Profile) do target Runner ligadas ao xcconfig do Bragantino usam AppIcon próprio, nunca o AppIcon padrão (real, do Goiás)',
      () {
        final pbxproj = File(
          'ios/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync();
        // Âncora pelo `baseConfigurationReference *-bragantino.xcconfig`,
        // não pelo nome do bloco — outros targets (ex.: RunnerTests)
        // também têm configs "*-bragantino" próprias, sem ícone nenhum, e
        // não fazem parte desta checagem.
        final anchorPattern = RegExp(
          r'baseConfigurationReference = \w+ /\* (Debug|Release|Profile)-bragantino\.xcconfig \*/;\s*\n\s*buildSettings = \{\s*\n\s*ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-Bragantino";',
        );
        final matches = anchorPattern.allMatches(pbxproj).toList();
        expect(
          matches.length,
          3,
          reason:
              'esperado exatamente 3 (Debug/Release/Profile do target Runner) apontando pro AppIcon-Bragantino logo após o xcconfig do Bragantino',
        );
      },
    );

    test('o appiconset AppIcon-Bragantino existe de verdade no disco', () {
      final dir = Directory(
        'ios/Runner/Assets.xcassets/AppIcon-Bragantino.appiconset',
      );
      expect(dir.existsSync(), isTrue);
      expect(
        File('${dir.path}/Icon-App-1024x1024@1x.png').existsSync(),
        isTrue,
      );
    });

    test(
      'web: iconsSourceDir do Bragantino aponta pra assets próprios, existentes e diferentes dos do Goiás',
      () {
        final config = File(
          'tool/web_flavors/bragantino.json',
        ).readAsStringSync();
        expect(config, isNot(contains('"iconsSourceDir": null')));

        const files = [
          'Icon-192.png',
          'Icon-512.png',
          'Icon-maskable-192.png',
          'Icon-maskable-512.png',
          'favicon.png',
        ];
        for (final f in files) {
          final own = File(
            'lib/assets/branding/bragantino/web_icons/$f',
          ).readAsBytesSync();
          final goias = File('web/icons/$f').existsSync()
              ? File('web/icons/$f').readAsBytesSync()
              : File('web/favicon.png').readAsBytesSync();
          expect(
            own,
            isNot(equals(goias)),
            reason: '$f do Bragantino é idêntico ao do Goiás',
          );
        }
      },
    );
  });
}
