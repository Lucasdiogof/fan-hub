// REGRESSÃO 2026-09-09 — achado real ao investigar o pedido de reaproveitar
// a marca d'água da Arena pro Bragantino: `StoreEntryCard` usava
// `AppColors.light.brandDeep` e `AppAssets.storeBanner` DIRETO, sempre o
// verde/banner do Goiás, nunca o clube ativo. Corrigido usando
// `context.colors` e `ClubConfig.assets.storeBanner`, nunca a constante
// estática. Achado 2 depois de hasStore=true pro Bragantino (2026-09-09):
// `storeHomeEntryBadge` era um literal "GOIÁS STORE" fixo no .arb (nenhum
// placeholder), sempre mostrado não importa o clube ativo — já é vazamento
// AO VIVO, não mais adormecido. Corrigido com `{storeName}` no .arb +
// `sl<ClubConfig>().productNames.storeName.toUpperCase()` no call site.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/store/presentation/widgets/store_entry_card.dart';
import 'package:goias_app/l10n/app_localizations.dart';

void main() {
  tearDown(() => sl.reset());

  for (final (clubName, config) in [
    ('Goiás', goiasClubConfig),
    ('Bragantino', bragantinoClubConfig),
  ]) {
    testWidgets(
      '$clubName: StoreEntryCard renderiza sem quebrar com o ClubConfig ativo',
      (tester) async {
        await sl.reset();
        sl.registerSingleton<ClubConfig>(config);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StoreEntryCard(onTap: () {}),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        final expectedBadge = config.productNames.storeName.toUpperCase();
        expect(find.text(expectedBadge), findsOneWidget);
        if (config.identity.code != 'goias') {
          expect(find.text('GOIÁS STORE'), findsNothing);
          expect(find.textContaining('Goiás'), findsNothing);
        }
      },
    );
  }
}
