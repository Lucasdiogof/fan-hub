import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/club/presentation/cubit/club_song_player_state.dart';

void main() {
  group('ClubSongPlayerState', () {
    test('starts idle with the default volume', () {
      const state = ClubSongPlayerState();
      expect(state.status, ClubSongPlayerStatus.idle);
      expect(state.userVolume, kDefaultPlayerVolume);
      expect(state.isMuted, isFalse);
    });

    test('displayVolume is 0 while muted, regardless of userVolume', () {
      const state = ClubSongPlayerState(userVolume: 0.65, isMuted: true);
      expect(state.displayVolume, 0.0);
    });

    test('unmuting restores the exact userVolume, never resets to default', () {
      const muted = ClubSongPlayerState(userVolume: 0.45, isMuted: true);
      final unmuted = muted.copyWith(isMuted: false);
      expect(unmuted.displayVolume, 0.45);
      expect(unmuted.userVolume, 0.45);
    });

    test('copyWith keeps fields not passed', () {
      const state = ClubSongPlayerState(
        status: ClubSongPlayerStatus.paused,
        duration: Duration(minutes: 3),
      );
      final updated = state.copyWith(status: ClubSongPlayerStatus.playing);
      expect(updated.status, ClubSongPlayerStatus.playing);
      expect(updated.duration, const Duration(minutes: 3));
    });

    test('equal props compare equal', () {
      const a = ClubSongPlayerState(
        status: ClubSongPlayerStatus.playing,
        userVolume: 0.5,
      );
      const b = ClubSongPlayerState(
        status: ClubSongPlayerStatus.playing,
        userVolume: 0.5,
      );
      expect(a, b);
    });
  });
}
