// Fecha a integração das 4 fotos históricas que faltavam no mapa
// `_bragantinoGuessPlayerPhotos` (cesar_haydar/ligger/edimar/gonzalo_fornari)
// — os 4 já estão is_active=true/verified no Supabase do Bragantino, o
// `photo_key` só precisava de uma entrada aqui pro
// `GuessPlayerRepository` parar de resolver `imageUrl` como null.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  const newKeys = {
    'cesar_haydar': 'lib/assets/games/guess_player/bragantino/cesar_haydar.png',
    'ligger': 'lib/assets/games/guess_player/bragantino/ligger.png',
    'edimar': 'lib/assets/games/guess_player/bragantino/edimar.png',
    'gonzalo_fornari':
        'lib/assets/games/guess_player/bragantino/gonzalo_fornari.png',
  };

  test(
    'as 4 fotos históricas que faltavam agora resolvem pro asset local certo',
    () {
      final photos = bragantinoClubConfig.assets.guessPlayerPhotos;
      newKeys.forEach((key, expectedPath) {
        expect(
          photos[key],
          expectedPath,
          reason: '$key precisa resolver pro asset local, nunca null',
        );
      });
    },
  );

  test(
    'nenhuma das 4 chaves novas existe no mapa do Goiás (isolamento entre clubes)',
    () {
      for (final key in newKeys.keys) {
        expect(
          goiasClubConfig.assets.guessPlayerPhotos.containsKey(key),
          isFalse,
          reason: '$key é exclusivo do Bragantino',
        );
      }
    },
  );

  test('nenhum jogador do Bragantino aponta pra asset do Goiás', () {
    final photos = bragantinoClubConfig.assets.guessPlayerPhotos;
    for (final entry in photos.entries) {
      if (entry.value.startsWith('lib/assets/')) {
        expect(
          entry.value,
          contains('bragantino'),
          reason: '${entry.key}: asset local tem que ser do Bragantino',
        );
      }
    }
  });

  test(
    'as fotos históricas locais anteriores continuam íntegras (nenhuma sobrescrita sem querer)',
    () {
      final photos = bragantinoClubConfig.assets.guessPlayerPhotos;
      // Uma amostra das históricas já existentes antes desta mudança —
      // continuam resolvendo pro mesmo asset de sempre.
      expect(
        photos['aderlan'],
        'lib/assets/games/guess_player/bragantino/aderlan.png',
      );
      expect(
        photos['ytalo'],
        'lib/assets/games/guess_player/bragantino/ytalo.png',
      );
      expect(
        photos['leo_ortiz'],
        'lib/assets/games/guess_player/bragantino/leo_ortiz.png',
      );
      // 35 históricas locais de antes (36 entradas históricas − `cleiton`,
      // que é URL do CDN, não asset local) + as 4 novas = 39.
      final localPhotos = photos.values
          .where((v) => v.startsWith('lib/assets/'))
          .toSet();
      expect(localPhotos, hasLength(39));
    },
  );
}
