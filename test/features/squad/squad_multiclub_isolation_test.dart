// Isolamento multiclube do Elenco. O risco real coberto aqui não é a
// query (essa já é provada em club_scoped_content_repositories_test), é o
// MAPA DE FOTOS: era global e consultado por `SquadMember.id`, um slug
// curto e repetível ("juninho", "pedrinho", "danilo") — bastava um clube
// novo ter um homônimo pra o rosto de um jogador do Goiás aparecer no card
// de outro clube. Agora o mapa vive em `ClubAssets.squadPhotos`, por clube.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/squad/domain/position_groups.dart';
import 'package:goias_app/features/squad/domain/squad_photos.dart';
import 'package:goias_app/features/squad/presentation/widgets/squad_avatar.dart';

import '../../core/club/synthetic_club_config.dart';

void main() {
  Future<void> useClub(ClubConfig config) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(config);
  }

  tearDown(sl.reset);

  group('fotos do elenco são por clube, nunca um mapa global', () {
    test('Goiás mantém exatamente as fotos que já tinha', () {
      expect(goiasClubConfig.assets.squadPhotos, same(squadPhotoAssets));
      expect(goiasClubConfig.assets.squadPhotos, isNotEmpty);
    });

    test('Bragantino: sem asset local pro Elenco — depende só da photo_url '
        'do banco, exatamente como antes (o pool de 46 fotos do Quem '
        'Vestiu o Manto vive em `guessPlayerPhotos`, campo separado)', () {
      expect(bragantinoClubConfig.assets.squadPhotos, isEmpty);
      expect(syntheticClubBConfig.assets.squadPhotos, isEmpty);
    });

    test('Bragantino: 46 fotos reais pro Quem Vestiu o Manto (2026-09-08), '
        'em `guessPlayerPhotos` — nunca em `squadPhotos` (isso quebraria o '
        'Elenco, que só sabe tratar asset local)', () {
      expect(bragantinoClubConfig.assets.guessPlayerPhotos, hasLength(46));
      final remote = bragantinoClubConfig.assets.guessPlayerPhotos.values
          .where((v) => v.startsWith('https://img.redbullbragantino.com/'));
      final local = bragantinoClubConfig.assets.guessPlayerPhotos.values
          .where(
            (v) => v.startsWith('lib/assets/games/guess_player/bragantino/'),
          );
      // 11 = 10 do elenco atual + Cleiton (também aparece no pool
      // histórico do Quem Vestiu o Manto, mas usa a MESMA URL do banco —
      // nunca um asset local separado que divergiria da foto certa dele
      // na aba Elenco).
      expect(remote, hasLength(11));
      expect(local, hasLength(35));
      expect(syntheticClubBConfig.assets.guessPlayerPhotos, isEmpty);
    });

    test('nenhum id do Goiás resolve foto num clube que não é o Goiás', () {
      for (final id in squadPhotoAssets.keys) {
        expect(
          bragantinoClubConfig.assets.squadPhotos[id],
          isNull,
          reason: '$id não pode resolver foto fora do Goiás',
        );
        expect(syntheticClubBConfig.assets.squadPhotos[id], isNull);
      }
    });
  });

  group('SquadAvatar resolve a foto do clube ativo', () {
    Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

    testWidgets('Goiás: id conhecido usa o asset local do Goiás', (
      tester,
    ) async {
      await useClub(goiasClubConfig);
      await tester.pumpWidget(
        wrap(
          const SquadAvatar(
            memberId: 'tadeu',
            photoUrl: null,
            shirtNumber: 1,
            size: 48,
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, squadPhotoAssets['tadeu']);
    });

    testWidgets(
      'Bragantino: MESMO id não pega a foto do Goiás, cai no número',
      (tester) async {
        await useClub(bragantinoClubConfig);
        await tester.pumpWidget(
          wrap(
            const SquadAvatar(
              memberId: 'tadeu',
              photoUrl: null,
              shirtNumber: 7,
              size: 48,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsNothing);
        expect(find.text('7'), findsOneWidget);
      },
    );

    testWidgets('sem foto e sem camisa não quebra o card', (tester) async {
      await useClub(bragantinoClubConfig);
      await tester.pumpWidget(
        wrap(
          const SquadAvatar(
            memberId: 'nao-existe',
            photoUrl: null,
            shirtNumber: null,
            size: 48,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('–'), findsOneWidget);
    });

    testWidgets('sem asset local, usa a photo_url do próprio banco', (
      tester,
    ) async {
      await useClub(bragantinoClubConfig);
      await tester.pumpWidget(
        wrap(
          const SquadAvatar(
            memberId: 'cleiton',
            photoUrl: 'https://img.redbullbragantino.com/foto.jpg',
            shirtNumber: 1,
            size: 48,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://img.redbullbragantino.com/foto.jpg',
      );
    });
  });

  group('config do clube ativo', () {
    test('Bragantino e Goiás têm club_id distintos e não vazios', () {
      final goias = goiasClubConfig.identity.canonicalClubId;
      final bragantino = bragantinoClubConfig.identity.canonicalClubId;
      expect(goias, isNotEmpty);
      expect(bragantino, isNotEmpty);
      expect(bragantino, isNot(goias));
    });

    test('grupos de posição do catálogo canônico são os mesmos pros dois', () {
      // O catálogo é único no projeto — nenhum clube pode ter nomenclatura
      // paralela. Se alguém criar um grupo só pro Bragantino, este teste
      // não pega sozinho, mas o seed SQL é validado contra esta lista.
      expect(positionGroupOrder, [
        'Goleiros',
        'Zagueiros',
        'Laterais-direitos',
        'Laterais-esquerdos',
        'Volantes',
        'Meios-campistas',
        'Atacantes',
      ]);
    });
  });
}
