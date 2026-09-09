import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';

void main() {
  group('goiasSquad.personId', () {
    test(
      '31 jogadores, todos com personId não-vazio (mapping F5 100% RESOLVED)',
      () {
        expect(goiasSquad.length, 31);
        for (final player in goiasSquad) {
          expect(
            player.personId,
            isNotEmpty,
            reason: '${player.id} sem personId',
          );
        }
      },
    );

    test('0 personId duplicado — 1:1 entre SquadPlayer e person', () {
      final ids = goiasSquad.map((p) => p.personId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('id (slug) continua único e nunca igual ao personId', () {
      final ids = goiasSquad.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final player in goiasSquad) {
        expect(player.id, isNot(equals(player.personId)));
      }
    });

    // Casos sensíveis — mesmos UUIDs já validados na F4
    // (squad_members_person_mapping.json) e re-confirmados ao vivo no
    // Supabase. Se algum destes falhar, o mapping F5 divergiu da F4.
    test('casos sensíveis batem exatamente com a F4', () {
      final byId = {for (final p in goiasSquad) p.id: p};

      expect(
        byId['nicolas']!.personId,
        'a597dae2-6ca9-5588-b1e3-a3532dd36f0e', // Nicolas Vichiatto da Silva
      );
      expect(
        byId['danilo']!.personId,
        '34d6fed1-6282-564a-bcb0-5be7d705760a', // Danilo Cunha da Silva
      );
      expect(
        byId['murilo_camara']!.personId,
        'a2ef1bbc-c0a2-572c-9954-4c5513b07eae', // Murilo Camara Saquetti Chimelo Pereira
      );
      expect(
        byId['murillo_victorio']!.personId,
        'e590ad99-16d4-52a1-88fd-2fbb064444b6', // Murillo Carvalho Victorio
      );
      // Distintos entre si — a diferença de grafia nunca funde as pessoas.
      expect(
        byId['murilo_camara']!.personId,
        isNot(equals(byId['murillo_victorio']!.personId)),
      );

      expect(byId['tadeu']!.personId, 'e2507d62-8cb5-5152-af56-f67464196ac6');
      expect(
        byId['luiz_felipe']!.personId,
        '83765e63-a9f9-584e-aef1-bf11c3324b5e',
      );
      expect(
        byId['rodrigo_soares']!.personId,
        '2bd4e578-4739-5f93-b5db-8ecf6ba44393',
      );
      expect(byId['djalma']!.personId, '54e8cc38-7ac7-5927-b7a5-ca11a372a545');
      expect(
        byId['lourenco']!.personId,
        'be72ef65-0fdc-5f2a-b09a-ff8da6a279fb',
      );
      expect(
        byId['lucas_rodrigues']!.personId,
        'af92cda1-aeba-5f69-a354-2928d8677c6f',
      );
    });

    test(
      'Dieguinho não existe no goiasSquad atual (mesma ausência já confirmada em squad_members na F4)',
      () {
        expect(squadById.containsKey('dieguinho'), isFalse);
        expect(
          goiasSquad.any((p) => p.name.toLowerCase().contains('dieguinho')),
          isFalse,
        );
      },
    );
  });

  group('lookup canônico (benefício da F5)', () {
    test('dá pra ir de um SquadPlayer conhecido até seu personId canônico', () {
      final tadeu = goiasSquad.firstWhere((p) => p.id == 'tadeu');
      expect(tadeu.personId, 'e2507d62-8cb5-5152-af56-f67464196ac6');
    });
  });
}
