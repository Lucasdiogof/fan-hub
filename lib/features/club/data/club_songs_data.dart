import 'package:goias_app/features/club/domain/entities/club_song.dart';

/// Nenhuma faixa tem `audioUrl`/`lyrics` ainda — sem fonte de áudio
/// autorizada disponível. A UI já mostra a lista e fica pronta pra tocar
/// assim que existir um `audioUrl` real; até lá o botão de play some.
class ClubSongsData {
  const ClubSongsData._();

  static const List<ClubSong> songs = [
    ClubSong(
      title: 'Hino do Goiás',
      artist: 'Versão Oficial',
      type: ClubSongType.anthem,
    ),
    ClubSong(
      title: 'Hino do Goiás',
      artist: 'Zezé di Camargo',
      type: ClubSongType.anthem,
    ),
    ClubSong(
      title: 'Hino do Goiás',
      artist: 'Mr. Gyn',
      type: ClubSongType.anthem,
    ),
    ClubSong(
      title: 'Ser Goiás é muito mais do que amor',
      artist: 'Dguedz',
      type: ClubSongType.song,
    ),
  ];
}
