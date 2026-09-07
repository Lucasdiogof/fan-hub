// Auditoria 2026-09-05 — a carteirinha de sócio é o único widget mostrado
// em várias telas (Home/Perfil/check-in), então é o ponto mais importante
// pra travar: com o clube em `CommerceMode.demo`, o selo "DEMONSTRAÇÃO"
// aparece; se um clube um dia virar `real`, ele some sozinho — nenhuma
// tela precisa ser reescrita.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/presentation/widgets/digital_membership_card.dart';
import 'package:goias_app/l10n/app_localizations.dart';

ClubConfig _configWith(CommerceMode membershipMode) => ClubConfig(
  identity: goiasClubConfig.identity,
  branding: goiasClubConfig.branding,
  assets: goiasClubConfig.assets,
  integrations: goiasClubConfig.integrations,
  productNames: goiasClubConfig.productNames,
  passportContent: goiasClubConfig.passportContent,
  capabilities: ClubCapabilities(
    hasMembership: goiasClubConfig.capabilities.hasMembership,
    hasStore: goiasClubConfig.capabilities.hasStore,
    hasTickets: goiasClubConfig.capabilities.hasTickets,
    hasCrowdLineup: goiasClubConfig.capabilities.hasCrowdLineup,
    hasPassport: goiasClubConfig.capabilities.hasPassport,
    hasNews: goiasClubConfig.capabilities.hasNews,
    hasSocial: goiasClubConfig.capabilities.hasSocial,
    hasClubContent: goiasClubConfig.capabilities.hasClubContent,
    hasPartners: goiasClubConfig.capabilities.hasPartners,
    hasMatches: goiasClubConfig.capabilities.hasMatches,
    enabledArenaGames: goiasClubConfig.capabilities.enabledArenaGames,
    storeCommerceMode: goiasClubConfig.capabilities.storeCommerceMode,
    ticketCommerceMode: goiasClubConfig.capabilities.ticketCommerceMode,
    membershipCommerceMode: membershipMode,
  ),
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  setUp(() async {
    await sl.reset();
  });

  testWidgets('membershipCommerceMode.demo -> mostra o selo de demonstração', (
    tester,
  ) async {
    sl.registerSingleton<ClubConfig>(_configWith(CommerceMode.demo));
    await tester.pumpWidget(
      _wrap(
        const DigitalMembershipCard(
          holderName: 'Torcedor Teste',
          planName: 'Plano Padrão',
          status: MembershipStatus.active,
        ),
      ),
    );

    expect(find.text('DEMONSTRAÇÃO'), findsOneWidget);
  });

  testWidgets(
    'membershipCommerceMode.real -> nunca mostra o selo de demonstração',
    (tester) async {
      sl.registerSingleton<ClubConfig>(_configWith(CommerceMode.real));
      await tester.pumpWidget(
        _wrap(
          const DigitalMembershipCard(
            holderName: 'Torcedor Teste',
            planName: 'Plano Padrão',
            status: MembershipStatus.active,
          ),
        ),
      );

      expect(find.text('DEMONSTRAÇÃO'), findsNothing);
    },
  );
}
