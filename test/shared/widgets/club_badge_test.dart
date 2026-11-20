import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
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
  _badgeTests();
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

/// Escudos de time (Vila): o clube ATUAL usa o asset oficial do flavor (nunca
/// rede/proxy); rival usa a URL materializada no Storage; sem URL ou com erro
/// de imagem cai num placeholder neutro (iniciais), sem derrubar o card.
void _badgeTests() {
  const storageUrl =
      'https://vkybbrfvmexevakknlsi.supabase.co/storage/v1/object/public/football-images/abc.png';
  final flavors = <String, ClubConfig>{
    'goias': goiasClubConfig,
    'vila': vilaNovaClubConfig,
    'bragantino': bragantinoClubConfig,
  };

  Team team(int id, {String? logo, String short = 'RIV'}) => Team(
    id: id,
    name: 'Time $id',
    shortName: short,
    color: Colors.green,
    logoUrl: logo,
  );

  Widget wrapTeam(Team t) => DefaultAssetBundle(
    bundle: FakeAssetBundle(),
    child: MaterialApp(home: Center(child: ClubBadge(team: t))),
  );

  for (final e in flavors.entries) {
    testWidgets('${e.key}: time = próprio clube -> asset do flavor, sem rede', (
      tester,
    ) async {
      await sl.reset();
      sl.registerSingleton<ClubConfig>(e.value);
      // Mesmo com logoUrl remoto (OneFootball) o asset local tem prioridade.
      final own = team(
        e.value.integrations.oneFootballTeamId,
        logo: 'https://images.onefootball.com/icons/teams/164/1.png',
      );
      await tester.pumpWidget(wrapTeam(own));
      final img = tester.widget<Image>(find.byType(Image));
      expect((img.image as AssetImage).assetName, e.value.assets.crestBadge);
      expect(find.byType(CachedNetworkImage), findsNothing);
      // Mandante/visitante não altera a identidade: é por id, não por lado.
      for (final other in flavors.values.where((c) => c != e.value)) {
        expect(
          other.assets.crestBadge,
          isNot(e.value.assets.crestBadge),
          reason: 'flavors têm escudos distintos',
        );
      }
    });
  }

  testWidgets('rival com URL materializada: usa essa URL, sem /api/image-proxy', (
    tester,
  ) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(vilaNovaClubConfig);
    await tester.pumpWidget(wrapTeam(team(1800, logo: storageUrl)));
    final net = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(net.imageUrl, storageUrl);
    expect(net.imageUrl, isNot(contains('image-proxy')));
  });

  testWidgets('rival sem URL: placeholder neutro com iniciais', (tester) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(vilaNovaClubConfig);
    await tester.pumpWidget(wrapTeam(team(1800, short: 'ATL')));
    expect(find.text('ATL'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('erro ao carregar a imagem: cai no placeholder e não quebra', (
    tester,
  ) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(vilaNovaClubConfig);
    await tester.pumpWidget(wrapTeam(team(1800, logo: storageUrl, short: 'ATL')));
    final net = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final ctx = tester.element(find.byType(CachedNetworkImage));
    final fallback = net.errorWidget!(ctx, storageUrl, Exception('404'));
    await tester.pumpWidget(
      MaterialApp(home: Center(child: fallback)),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('ATL'), findsOneWidget);
  });
}
