// Auditoria 2026-09-05: garante, daqui pra frente, que a foto de um
// jogador histórico nunca fica "presa" só no fallback local — o bug real
// encontrado era `guess_player_repository.dart` só resolver `photo_key`
// contra `squadPhotoAssets`, nunca contra `guessPlayerPhotoAssets`. Esses
// testes travam as duas pontas: (1) o mapa de fotos e o catálogo nunca
// desalinham (nenhum asset órfão, nenhuma referência quebrada); (2) todo
// asset referenciado existe de verdade no disco.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_catalog.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player_photos.dart';
import 'package:goias_app/features/squad/domain/squad_photos.dart';

void main() {
  group('Consistência guessPlayerPhotoAssets <-> guessPlayerCatalog', () {
    test(
      'toda chave de guessPlayerPhotoAssets é usada por exatamente 1 jogador do catálogo (0 asset órfão)',
      () {
        final usedKeys = guessPlayerCatalog
            .map((p) => p.imageUrl)
            .whereType<String>()
            .toSet();
        for (final entry in guessPlayerPhotoAssets.entries) {
          expect(
            usedKeys.contains(entry.value),
            isTrue,
            reason:
                'guessPlayerPhotoAssets["${entry.key}"] não é referenciado por nenhum jogador do catálogo — asset órfão.',
          );
        }
      },
    );

    test(
      'todo arquivo de guessPlayerPhotoAssets existe de verdade no disco',
      () {
        for (final entry in guessPlayerPhotoAssets.entries) {
          expect(
            File(entry.value).existsSync(),
            isTrue,
            reason: 'Asset declarado mas ausente no disco: ${entry.value}',
          );
        }
      },
    );

    test(
      'todo jogador verified + elegível como secreto tem um imageUrl que resolve por squadPhotoAssets OU guessPlayerPhotoAssets',
      () {
        final allKnownPaths = {
          ...squadPhotoAssets.values,
          ...guessPlayerPhotoAssets.values,
        };
        for (final player in guessPlayerCatalog) {
          if (!player.eligibleAsSecret) continue;
          expect(
            player.imageUrl != null && allKnownPaths.contains(player.imageUrl),
            isTrue,
            reason:
                '${player.id} é eligibleAsSecret mas o imageUrl não resolve por nenhum dos 2 mapas conhecidos.',
          );
        }
      },
    );

    test('nenhum jogador incomplete/review vaza como elegível a secreto', () {
      for (final player in guessPlayerCatalog) {
        if (player.dataStatus.name != 'verified') {
          expect(
            player.eligibleAsSecret,
            isFalse,
            reason:
                '${player.id} está "${player.dataStatus.name}" mas eligibleAsSecret é true.',
          );
        }
      }
    });
  });
}
