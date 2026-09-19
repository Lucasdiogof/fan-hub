import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/splash/presentation/pages/splash_video_page.dart';

import '../../../../core/club/synthetic_club_config.dart';

/// `shouldPlaySplashVideo` é a decisão PURA (sem widget/plugin de vídeo)
/// entre `VideoSplashView` e `StaticLogoSplash` — testável sozinha, mesmo
/// padrão do `capabilityGateRedirect`. Cobre a regra absoluta: um clube sem
/// `splashVideo` (Bragantino e, desde o rebrand Esmeraldino App, também o
/// Goiás) NUNCA cai pro vídeo de outro clube.
///
/// Nenhum `ClubConfig` real tem `splashVideo` preenchido hoje — os testes
/// do ramo "toca vídeo" abaixo usam uma string literal só pra exercitar a
/// lógica pura de `shouldPlaySplashVideo` (que não olha QUAL vídeo, só se
/// é `null`), não pra afirmar que algum clube real tem vídeo.
const _fakeVideoAsset = 'test/fixtures/fake_splash.mp4';

void main() {
  group('configuração dos clubes', () {
    test(
      'Goiás tem splashVideo = null (removido no rebrand Esmeraldino App) e splashLogo definido',
      () {
        expect(goiasClubConfig.assets.splashVideo, isNull);
        expect(
          goiasClubConfig.assets.splashLogo,
          'lib/assets/branding/goias/new_logo_splash.png',
        );
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
