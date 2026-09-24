import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/splash/presentation/pages/splash_video_page.dart';

import '../../../../core/club/synthetic_club_config.dart';

/// `shouldPlaySplashVideo` é a decisão PURA (sem widget/plugin de vídeo)
/// entre `VideoSplashView` e `StaticLogoSplash` — testável sozinha, mesmo
/// padrão do `capabilityGateRedirect`. Cobre a regra absoluta: um clube sem
/// `splashVideo` (Bragantino) NUNCA cai pro vídeo de outro clube.
///
/// O rebrand Esmeraldino App (Guideline 4.1(a)) zerou `splashVideo` do
/// Goiás e ligou `splashLogo` (mascote) de 2026-09-14 a 2026-09-24; religado
/// quando o projeto deixou de mirar App Store — o Goiás volta a ter o vídeo
/// oficial preenchido. Os testes do ramo "toca vídeo" abaixo usam uma
/// string literal só pra exercitar a lógica pura de `shouldPlaySplashVideo`
/// (que não olha QUAL vídeo, só se é `null`).
const _fakeVideoAsset = 'test/fixtures/fake_splash.mp4';

void main() {
  group('configuração dos clubes', () {
    test(
      'Goiás tem splashVideo oficial religado (2026-09-24) e splashLogo do rebrand desativado',
      () {
        expect(
          goiasClubConfig.assets.splashVideo,
          'lib/assets/videos/goias_splash.mp4',
        );
        expect(goiasClubConfig.assets.splashLogo, isNull);
      },
    );

    test('Bragantino tem splashVideo = null (sem vídeo oficial ainda)', () {
      expect(bragantinoClubConfig.assets.splashVideo, isNull);
    });

    test('clube sintético (fixture de teste) também não tem splashVideo', () {
      expect(syntheticClubBConfig.assets.splashVideo, isNull);
    });
  });

  group('shouldPlaySplashVideo', () {
    test('splashVideoAsset != null e não é iOS Web -> true (vídeo)', () {
      expect(
        shouldPlaySplashVideo(
          isIosWeb: false,
          splashVideoAsset: _fakeVideoAsset,
        ),
        isTrue,
      );
    });

    test(
      'splashVideoAsset == null -> false (StaticLogoSplash), mesmo fora do iOS Web',
      () {
        expect(
          shouldPlaySplashVideo(
            isIosWeb: false,
            splashVideoAsset: bragantinoClubConfig.assets.splashVideo,
          ),
          isFalse,
        );
      },
    );

    test(
      'iOS Web -> false (StaticLogoSplash) mesmo com splashVideo != null',
      () {
        expect(
          shouldPlaySplashVideo(
            isIosWeb: true,
            splashVideoAsset: _fakeVideoAsset,
          ),
          isFalse,
        );
      },
    );

    test(
      'iOS Web + splashVideoAsset == null -> false (as duas razões concordam)',
      () {
        expect(
          shouldPlaySplashVideo(isIosWeb: true, splashVideoAsset: null),
          isFalse,
        );
      },
    );
  });

  group('FABRICADO — regra absoluta: nunca vídeo de outro clube', () {
    test(
      'com o ClubConfig do Bragantino, shouldPlaySplashVideo nunca autoriza tocar o mp4 do Goiás',
      () {
        // Não existe parâmetro "qual vídeo tocar" nesta função por design —
        // o único vídeo possível de ser escolhido é o do próprio
        // `ClubConfig.assets.splashVideo` do clube ativo. Bragantino tem
        // `null`, então o resultado só pode liberar `StaticLogoSplash`.
        final playsVideo = shouldPlaySplashVideo(
          isIosWeb: false,
          splashVideoAsset: bragantinoClubConfig.assets.splashVideo,
        );
        expect(playsVideo, isFalse);
        expect(bragantinoClubConfig.assets.splashVideo, isNull);
      },
    );
  });
}
