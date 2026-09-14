import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/club/data/club_song_volume_store.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/presentation/cubit/club_song_player_cubit.dart';
import 'package:goias_app/features/club/presentation/cubit/club_song_player_state.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _songSemAudio = ClubSong(
  id: 's1',
  title: 'Hino do Goiás',
  category: ClubSongCategory.anthem,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'togglePlayback sem audioAsset não faz nada — sem player pra tocar',
    () async {
      final cubit = ClubSongPlayerCubit(
        _songSemAudio,
        ClubSongVolumeStore(),
        AudioPlayer(),
      );
      addTearDown(cubit.close);

      await cubit.togglePlayback();

      expect(cubit.state.status, ClubSongPlayerStatus.idle);
    },
  );

  test('init sem volume salvo usa o volume padrão', () async {
    final cubit = ClubSongPlayerCubit(
      _songSemAudio,
      ClubSongVolumeStore(),
      AudioPlayer(),
    );
    addTearDown(cubit.close);

    await cubit.init();

    expect(cubit.state.userVolume, kDefaultPlayerVolume);
  });

  test('init com volume salvo carrega esse valor, não o padrão', () async {
    SharedPreferences.setMockInitialValues({'club_song_user_volume': 0.3});
    final cubit = ClubSongPlayerCubit(
      _songSemAudio,
      ClubSongVolumeStore(),
      AudioPlayer(),
    );
    addTearDown(cubit.close);

    await cubit.init();

    expect(cubit.state.userVolume, 0.3);
  });

  group('setUserVolume', () {
    test('atualiza o volume, desmuta e persiste o valor escolhido', () async {
      final cubit = ClubSongPlayerCubit(
        _songSemAudio,
        ClubSongVolumeStore(),
        AudioPlayer(),
      );
      addTearDown(cubit.close);
      await cubit.toggleMute();
      expect(cubit.state.isMuted, isTrue);

      await cubit.setUserVolume(0.5);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.userVolume, 0.5);
      expect(cubit.state.isMuted, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('club_song_user_volume'), 0.5);
    });

    test('sempre trava o valor entre 0.0 e 1.0', () async {
      final cubit = ClubSongPlayerCubit(
        _songSemAudio,
        ClubSongVolumeStore(),
        AudioPlayer(),
      );
      addTearDown(cubit.close);

      await cubit.setUserVolume(1.5);
      expect(cubit.state.userVolume, 1.0);

      await cubit.setUserVolume(-0.2);
      expect(cubit.state.userVolume, 0.0);
    });
  });

  test(
    'toggleMute alterna isMuted e zera o displayVolume sem mexer no userVolume',
    () async {
      final cubit = ClubSongPlayerCubit(
        _songSemAudio,
        ClubSongVolumeStore(),
        AudioPlayer(),
      );
      addTearDown(cubit.close);
      await cubit.setUserVolume(0.8);

      await cubit.toggleMute();
      expect(cubit.state.isMuted, isTrue);
      expect(cubit.state.displayVolume, 0.0);
      expect(cubit.state.userVolume, 0.8);

      await cubit.toggleMute();
      expect(cubit.state.isMuted, isFalse);
      expect(cubit.state.displayVolume, 0.8);
    },
  );

  test('close nunca lança, mesmo sem player real disponível', () async {
    final cubit = ClubSongPlayerCubit(
      _songSemAudio,
      ClubSongVolumeStore(),
      AudioPlayer(),
    );
    await expectLater(cubit.close(), completes);
  });
}
