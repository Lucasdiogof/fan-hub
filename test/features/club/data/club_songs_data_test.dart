import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/club/data/club_songs_data.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';

void main() {
  group('ClubSongsData', () {
    test('keeps exactly the 3 confirmed anthems', () {
      final anthems = ClubSongsData.songs
          .where((s) => s.category == ClubSongCategory.anthem)
          .toList();
      expect(anthems, hasLength(3));
      expect(anthems.map((s) => s.artist), [
        'Versão Oficial',
        'Zezé di Camargo',
        'Mr. Gyn',
      ]);
      for (final anthem in anthems) {
        expect(anthem.title, 'Hino do Goiás');
      }
    });

    test('never contains the removed Dguedz track', () {
      final hasDguedz = ClubSongsData.songs.any(
        (s) =>
            s.artist == 'Dguedz' ||
            s.title.toLowerCase().contains('ser goiás é muito mais'),
      );
      expect(hasDguedz, isFalse);
    });

    test('every song has a unique id', () {
      final ids = ClubSongsData.songs.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
