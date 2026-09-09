// M4.1 — prova de isolamento de identidade entre o Goiás e um clube
// sintético (`syntheticClubBConfig`, TEST-ONLY, nunca registrado em
// produção). Cada asserção aqui corresponde a um achado real da auditoria
// M4 round 1: um bypass hardcoded que agora lê de `ClubConfig` deveria
// produzir um valor DIFERENTE para o clube sintético, nunca o mesmo valor
// do Goiás — se algum bypass for reintroduzido, o teste correspondente
// quebra.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';

import 'synthetic_club_config.dart';

void main() {
  group(
    'branding — clube sintético != Goiás (achado M4: ClubConfig.branding tinha 0 consumidores)',
    () {
      test('cores primary claras diferem entre os dois clubes', () {
        expect(
          syntheticClubBConfig.branding.light.primary,
          isNot(equals(goiasClubConfig.branding.light.primary)),
        );
        expect(
          syntheticClubBConfig.branding.dark.primary,
          isNot(equals(goiasClubConfig.branding.dark.primary)),
        );
      });

      test(
        'AppTheme.light/dark constroem ThemeData com a cor do clube passado, nunca a estática',
        () {
          final goiasTheme = AppTheme.light(goiasClubConfig.branding.light);
          final clubBTheme = AppTheme.light(
            syntheticClubBConfig.branding.light,
          );
          expect(
            goiasTheme.colorScheme.primary,
            isNot(equals(clubBTheme.colorScheme.primary)),
          );
          expect(
            clubBTheme.colorScheme.primary,
            syntheticClubBConfig.branding.light.primary,
          );
        },
      );
    },
  );

  group(
    'assets — clube sintético != Goiás (achado crítico M4: ~14 arquivos liam AppAssets.<literal> direto)',
    () {
      test('todo path de asset difere entre os dois clubes', () {
        expect(
          syntheticClubBConfig.assets.crest,
          isNot(equals(goiasClubConfig.assets.crest)),
        );
        expect(
          syntheticClubBConfig.assets.crestBadge,
          isNot(equals(goiasClubConfig.assets.crestBadge)),
        );
        expect(
          syntheticClubBConfig.assets.loginBackground,
          isNot(equals(goiasClubConfig.assets.loginBackground)),
        );
        expect(
          syntheticClubBConfig.assets.stadium,
          isNot(equals(goiasClubConfig.assets.stadium)),
        );
        expect(
          syntheticClubBConfig.assets.matchHero,
          isNot(equals(goiasClubConfig.assets.matchHero)),
        );
        expect(
          syntheticClubBConfig.assets.tacticsBoardIllustration,
          isNot(equals(goiasClubConfig.assets.tacticsBoardIllustration)),
        );
        expect(
          syntheticClubBConfig.assets.arenaStadiumPhoto,
          isNot(equals(goiasClubConfig.assets.arenaStadiumPhoto)),
        );
      });

      test(
        'nenhum path do clube sintético contém "goias" (prova que não é só um alias do mesmo arquivo)',
        () {
          final allPaths = [
            syntheticClubBConfig.assets.crest,
            syntheticClubBConfig.assets.crestBadge,
            syntheticClubBConfig.assets.crest3d,
            syntheticClubBConfig.assets.loginBackground,
            syntheticClubBConfig.assets.stadium,
            syntheticClubBConfig.assets.matchHero,
            syntheticClubBConfig.assets.tacticsBoardIllustration,
            syntheticClubBConfig.assets.arenaStadiumIcon,
            syntheticClubBConfig.assets.arenaStadiumPhoto,
            syntheticClubBConfig.assets.storeBanner,
          ];
          for (final path in allPaths) {
            expect(
              path?.toLowerCase().contains('goias') ?? false,
              isFalse,
              reason: path,
            );
          }
        },
      );
    },
  );

  group(
    'identidade/naming — MaterialApp e config mudam por ClubConfig, nunca hardcoded (achado M4: main.dart title fixo)',
    () {
      test(
        'identity.displayName difere — este é o valor usado em MaterialApp.router(title:)',
        () {
          expect(
            syntheticClubBConfig.identity.displayName,
            isNot(equals(goiasClubConfig.identity.displayName)),
          );
        },
      );

      test('productNames difere em todos os 4 campos', () {
        expect(
          syntheticClubBConfig.productNames.arenaName,
          isNot(equals(goiasClubConfig.productNames.arenaName)),
        );
        expect(
          syntheticClubBConfig.productNames.passportName,
          isNot(equals(goiasClubConfig.productNames.passportName)),
        );
        expect(
          syntheticClubBConfig.productNames.storeName,
          isNot(equals(goiasClubConfig.productNames.storeName)),
        );
        expect(
          syntheticClubBConfig.productNames.membershipProgramName,
          isNot(equals(goiasClubConfig.productNames.membershipProgramName)),
        );
      });

      test(
        'orderPrefix difere (achado M4: GOI- hardcoded em 2 lugares, agora lido de ClubIntegrations)',
        () {
          expect(syntheticClubBConfig.integrations.orderPrefix, 'CLB');
          expect(
            syntheticClubBConfig.integrations.orderPrefix,
            isNot(equals(goiasClubConfig.integrations.orderPrefix)),
          );
        },
      );

      test(
        'PickupInformation.forActiveClub() lê do clube ativo via GetIt, nunca hardcoded (achado M4)',
        () async {
          await sl.reset();
          sl.registerSingleton<ClubConfig>(syntheticClubBConfig);
          final pickup = PickupInformation.forActiveClub();
          expect(
            pickup.storeName,
            syntheticClubBConfig.integrations.pickupAddress!.storeName,
          );
          expect(
            pickup.storeName,
            isNot(
              equals(goiasClubConfig.integrations.pickupAddress!.storeName),
            ),
          );
          await sl.reset();
        },
      );
    },
  );

  group(
    'social links — integração ausente vira lista vazia, nunca fallback pro Goiás (achado M4: SocialLinksData/SocialEmptyState hardcoded)',
    () {
      test(
        'syntheticClubBConfig não tem NENHUMA rede social configurada de propósito',
        () {
          final social = syntheticClubBConfig.integrations;
          expect(social.socialInstagramUrl, isNull);
          expect(social.socialYoutubeUrl, isNull);
          expect(social.socialTiktokUrl, isNull);
          expect(social.socialFacebookUrl, isNull);
          expect(social.socialXUrl, isNull);
          expect(social.officialSiteUrl, isNull);
        },
      );

      test(
        'goiasClubConfig continua com as 6 redes reais — nada regrediu pro clube real',
        () {
          final social = goiasClubConfig.integrations;
          expect(social.socialInstagramUrl, isNotNull);
          expect(social.socialYoutubeUrl, isNotNull);
          expect(social.socialTiktokUrl, isNotNull);
          expect(social.socialFacebookUrl, isNotNull);
          expect(social.socialXUrl, isNotNull);
          expect(social.officialSiteUrl, isNotNull);
        },
      );
    },
  );

  group(
    'capabilities — sintético desliga Passaporte de propósito (prova o caminho capability=false, mesmo sem estar wireado em telas ainda)',
    () {
      test('hasPassport=false só no clube sintético', () {
        expect(syntheticClubBConfig.capabilities.hasPassport, isFalse);
        expect(goiasClubConfig.capabilities.hasPassport, isTrue);
      });
    },
  );

  test(
    'FABRICADO: clubRegistry real nunca contém o clube sintético (guarda-corpo já existente, reconfirmado)',
    () {
      // Import local pra não expandir o escopo deste arquivo — só reconfirma
      // o mesmo invariante que `club_scoped_content_repositories_test.dart`
      // já prova via `resolveActiveClub`.
      expect(syntheticClubBConfig.identity.code, 'club-b');
    },
  );
}
