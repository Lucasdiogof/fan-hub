import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/presentation/widgets/club_entry_card.dart';
import 'package:goias_app/l10n/app_localizations.dart';

import '../../../../core/club/synthetic_club_config.dart';
import '../../../../support/fake_asset_bundle.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  Widget wrap() => DefaultAssetBundle(
    bundle: FakeAssetBundle(),
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: ClubEntryCard(onTap: () {})),
    ),
  );

  testWidgets('Goiás -> crest do card é o crestBadge do Goiás', (tester) async {
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
    await tester.pumpWidget(wrap());

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      goiasClubConfig.assets.crestBadge,
    );
  });

  testWidgets(
    'clube sintético (Bragantino-like) -> crest do card nunca é o do Goiás',
    (tester) async {
      sl.registerSingleton<ClubConfig>(syntheticClubBConfig);
      await tester.pumpWidget(wrap());

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        syntheticClubBConfig.assets.crestBadge,
      );
      expect(
        (image.image as AssetImage).assetName,
        isNot(goiasClubConfig.assets.crestBadge),
      );
    },
  );

  testWidgets(
    'Bragantino (clube real) -> CTA/subtítulo mostram "Bragantino", nunca '
    '"Goiás" (regressão do vazamento achado em 2026-09-07)',
    (tester) async {
      sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
      await tester.pumpWidget(wrap());

      expect(find.textContaining('Bragantino'), findsWidgets);
      expect(find.textContaining('Goiás', skipOffstage: false), findsNothing);
      expect(find.textContaining('GOIÁS', skipOffstage: false), findsNothing);
    },
  );
}
