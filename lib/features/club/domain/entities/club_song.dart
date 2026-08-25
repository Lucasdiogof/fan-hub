enum ClubSongType { anthem, song }

/// [audioUrl]/[lyrics] ficam `null` até existir uma fonte de áudio
/// autorizada — a UI já está pronta pra tocar/mostrar letra assim que
/// algum dos dois chegar, sem precisar mexer no modelo de novo.
class ClubSong {
  const ClubSong({
    required this.title,
    required this.artist,
    required this.type,
    this.audioUrl,
    this.lyrics,
  });

  final String title;
  final String artist;
  final ClubSongType type;
  final String? audioUrl;
  final String? lyrics;
}
