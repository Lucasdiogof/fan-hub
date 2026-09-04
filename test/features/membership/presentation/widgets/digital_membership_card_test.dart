import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/presentation/widgets/digital_membership_card.dart';

import '../../../../core/club/synthetic_club_config.dart';
import '../../../../support/fake_asset_bundle.dart';

/// Preventivo (M4 — isolamento visual): mesmo com `hasMembership=false`
/// bloqueando a rota inteira hoje, o card não deve mais depender de
/// `MockData.goias`/`'SÓCIO ESMERALDA'` — prova que ele lê
/// `ClubConfig.productNames.membershipProgramName` e `assets.crestBadge`
/// do clube ativo, pra não repetir o erro se `hasMembership` virar `true`
/// no futuro.
void main() {
  setUp(() async {
    await sl.reset();
  });

  Widget wrap() => DefaultAssetBundle(
    bundle: FakeAssetBundle(),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: DigitalMembershipCard(
          holderName: 'Torcedor Teste',
          planName: 'Plano Teste',
          status: MembershipStatus.active,
        ),
      ),
    ),
  );

  testWidgets('Goiás -> mostra "SÓCIO ESMERALDA" e o crest do Goiás', (
    tester,
  ) async {
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
    await tester.pumpWidget(wrap());

    expect(find.text('SÓCIO ESMERALDA'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      goiasClubConfig.assets.crestBadge,
    );
  });

  testWidgets(
    'clube sintético (Bragantino-like) -> nunca mostra "SÓCIO ESMERALDA" nem o crest do Goiás',
    (tester) async {
      sl.registerSingleton<ClubConfig>(syntheticClubBConfig);
      await tester.pumpWidget(wrap());

      expect(find.text('SÓCIO ESMERALDA'), findsNothing);
      expect(
        find.text(
          syntheticClubBConfig.productNames.membershipProgramName
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        isNot(goiasClubConfig.assets.crestBadge),
      );
    },
  );
}
