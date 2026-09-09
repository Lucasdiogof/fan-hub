// Goiás continua com 1 banner só (StoreBannerCarousel nunca monta carousel
// pra ele); Bragantino usa os 3 banners reais configurados — nenhum dos
// dois compartilha arquivo com o outro.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  test('Goiás tem exatamente 1 banner configurado', () {
    expect(goiasClubConfig.assets.storeHomeBanners, [
      'lib/assets/goias_store.png',
    ]);
  });

  test('Bragantino tem exatamente 3 banners configurados', () {
    expect(bragantinoClubConfig.assets.storeHomeBanners, [
      'lib/assets/store/banners/bragantino/banner_1.png',
      'lib/assets/store/banners/bragantino/banner_2.png',
      'lib/assets/store/banners/bragantino/banner_3.png',
    ]);
  });

  test('nenhum banner do Bragantino é o arquivo do Goiás, e vice-versa', () {
    final goiasBanners = goiasClubConfig.assets.storeHomeBanners.toSet();
    final bragantinoBanners = bragantinoClubConfig.assets.storeHomeBanners
        .toSet();
    expect(goiasBanners.intersection(bragantinoBanners), isEmpty);
  });
}
