import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

import '../../core/club/synthetic_club_config.dart';
import '../../support/fake_asset_bundle.dart';

/// `ClubBadge.activeClub` — variante sem `Team` nenhum (mockado ou real),
/// pensada pra "só o meu escudo" (Home, cabeçalho de "O Clube", carteirinha
/// de sócio). Prova que ela SEMPRE lê `ClubConfig.assets.crestBadge` do
/// clube registrado em `sl<ClubConfig>()`, nunca um valor fixo.
void main() {
  setUp(() async {
    await sl.reset();
  });

  String assetNameOf(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image));
    return (image.image as AssetImage).assetName;
  }

  Widget wrap() => DefaultAssetBundle(
    bundle: FakeAssetBundle(),
    child: const MaterialApp(home: Center(child: ClubBadge.activeClub())),
  );

  testWidgets('Goiás ativo -> renderiza o crestBadge do Goiás', (tester) async {
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
    await tester.pumpWidget(wrap());

    expect(assetNameOf(tester), goiasClubConfig.assets.crestBadge);
  });

  testWidgets(
    'clube sintético (Bragantino-like) ativo -> renderiza o crestBadge dele, nunca o do Goiás',
    (tester) async {
      sl.registerSingleton<ClubConfig>(syntheticClubBConfig);
      await tester.pumpWidget(wrap());

      expect(assetNameOf(tester), syntheticClubBConfig.assets.crestBadge);
      expect(assetNameOf(tester), isNot(goiasClubConfig.assets.crestBadge));
    },
  );
}
