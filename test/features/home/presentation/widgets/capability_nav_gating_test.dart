import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/home/presentation/widgets/goias_bottom_navigation_bar.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_rail.dart';
import 'package:goias_app/l10n/app_localizations.dart';

import '../../../../core/club/synthetic_club_config.dart';

/// `syntheticClubBConfig.assets.*` aponta pra caminhos que só existem pra
/// provar (por STRING) que o clube sintético nunca reaproveita asset do
/// Goiás — nunca foram pensados pra ser carregados de verdade num
/// `Image.asset` (não estão em `pubspec.yaml`, de propósito: são só do
/// clube sintético de teste, nunca deveriam inchar o binário real). Esse
/// bundle devolve um PNG 1x1 válido pra QUALQUER asset desconhecido,
/// delegando o resto (l10n/fontes/tema) pro bundle real — assim o
/// `_HomeCrestButton` consegue montar sem tocar `pubspec.yaml`.
final _transparentPng1x1 = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } on FlutterError {
      return ByteData.view(_transparentPng1x1.buffer);
    }
  }
}

/// M4.2A (+ auditoria Matches/football) — prova de VERDADE (widget real
/// montado, não só a lógica pura de `capabilityGateRedirect`) que
/// "capability=false não aparece em menus" é real: Jogos/Sócio/Loja/Mídia
/// (rótulos reais) somem da bottom nav E do rail pro clube sintético (todas
/// as capabilities correspondentes false), mas o Goiás continua vendo as 5
/// abas de sempre — nenhuma regressão.
Future<void> _pumpBottomNav(WidgetTester tester) async {
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _FakeAssetBundle(),
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: GoiasBottomNavigationBar(
            selectedIndex: 2,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRail(WidgetTester tester) async {
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _FakeAssetBundle(),
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: MainNavigationRail(selectedIndex: 2, onSelected: (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await sl.reset();
  });

  group('Goiás — as 5 abas de sempre, nenhuma regressão', () {
    // hasMembership/hasStore do Goiás real estão escondidos temporariamente
    // pro envio às lojas (ver comentário em goias_club_config.dart) — este
    // teste prova a navegação em si (nunca esconde uma aba com a capability
    // ligada), então religa as duas só aqui, sem depender do estado atual
    // de produção.
    final goiasAllCapabilities = ClubConfig(
      identity: goiasClubConfig.identity,
      branding: goiasClubConfig.branding,
      assets: goiasClubConfig.assets,
      integrations: goiasClubConfig.integrations,
      productNames: goiasClubConfig.productNames,
      passportContent: goiasClubConfig.passportContent,
      membershipProgram: goiasClubConfig.membershipProgram,
      institutionalContent: goiasClubConfig.institutionalContent,
      capabilities: ClubCapabilities(
        hasMembership: true,
        hasStore: true,
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
        membershipCommerceMode:
            goiasClubConfig.capabilities.membershipCommerceMode,
      ),
    );

    setUp(() => sl.registerSingleton<ClubConfig>(goiasAllCapabilities));

    testWidgets('bottom nav mostra Jogos/Sócio/Loja/Mídia', (tester) async {
      await _pumpBottomNav(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      expect(find.text(l10n.navMatches), findsOneWidget);
      expect(find.text(l10n.navMembership), findsOneWidget);
      expect(find.text(l10n.navStore), findsOneWidget);
      expect(find.text(l10n.navMedia), findsOneWidget);
    });

    testWidgets('rail mostra as 5 abas', (tester) async {
      await _pumpRail(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      expect(find.text(l10n.navMatches), findsOneWidget);
      expect(find.text(l10n.navMembership), findsOneWidget);
      expect(find.text(l10n.navHome), findsOneWidget);
      expect(find.text(l10n.navStore), findsOneWidget);
      expect(find.text(l10n.navMedia), findsOneWidget);
    });
  });

  // SUPERSEDIDO (auditoria Matches/football multiclub): Jogos passou a ter
  // capability própria (`hasMatches`, hoje `false` no fixture sintético —
  // Worker de futebol ainda não existe pro clube). Antes desta rodada,
  // Jogos nunca era gateado (era "núcleo do produto"); os testes abaixo
  // refletem o novo comportamento correto — só Home continua nunca gateada.
  group(
    'club-b sintético — Jogos/Sócio/Loja/Mídia somem (capability=false)',
    () {
      setUp(() => sl.registerSingleton<ClubConfig>(syntheticClubBConfig));

      testWidgets('bottom nav esconde Jogos/Sócio/Loja/Mídia', (tester) async {
        await _pumpBottomNav(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
        expect(find.text(l10n.navMatches), findsNothing);
        expect(find.text(l10n.navMembership), findsNothing);
        expect(find.text(l10n.navStore), findsNothing);
        expect(find.text(l10n.navMedia), findsNothing);
      });

      testWidgets('rail esconde Jogos/Sócio/Loja/Mídia, mantém Home', (
        tester,
      ) async {
        await _pumpRail(tester);
        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
        expect(find.text(l10n.navMatches), findsNothing);
        expect(find.text(l10n.navHome), findsOneWidget);
        expect(find.text(l10n.navMembership), findsNothing);
        expect(find.text(l10n.navStore), findsNothing);
        expect(find.text(l10n.navMedia), findsNothing);
      });
    },
  );
}
