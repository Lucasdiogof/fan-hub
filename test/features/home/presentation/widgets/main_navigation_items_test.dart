import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_items.dart';

import '../../../../core/club/synthetic_club_config.dart';

void main() {
  test('Goiás: aba Jogos habilitada (hasMatches=true)', () {
    expect(isTabEnabled(jogosTabIndex, goiasClubConfig.capabilities), isTrue);
  });

  test(
    'clube sintético (Bragantino-like): aba Jogos desabilitada (hasMatches=false, Worker ainda não existe)',
    () {
      expect(
        isTabEnabled(jogosTabIndex, syntheticClubBConfig.capabilities),
        isFalse,
      );
    },
  );

  test('Home nunca é gateada, mesmo pro clube sintético', () {
    expect(
      isTabEnabled(homeTabIndex, syntheticClubBConfig.capabilities),
      isTrue,
    );
  });
}
