import 'package:equatable/equatable.dart';

enum ClubSongCategory { anthem, esmeraldina }

/// [artist], [lyrics] e [audioAsset] ficam `null` até existir o conteúdo
/// real — a UI já sabe lidar com cada ausência (sem artista não mostra a
/// segunda linha, sem letra mostra aviso discreto, sem áudio desabilita o
/// Play) sem precisar mudar o model de novo quando o conteúdo chegar.
class ClubSong extends Equatable {
  const ClubSong({
    required this.id,
    required this.title,
    required this.category,
    this.artist,
    this.lyrics,
    this.audioAsset,
    this.volumeFactor = 1.0,
  });

  final String id;
  final String title;
  final String? artist;
  final ClubSongCategory category;
  final String? lyrics;
  final String? audioAsset;

  /// Compensação de loudness específica da gravação — `1.0` é o volume
  /// original, sem ajuste. Existe porque gravações de arquibancada podem
  /// estar masterizadas bem mais altas que as de estúdio; nunca usar acima
  /// de `1.0` (amplificar corre risco de distorcer) — se um áudio estiver
  /// baixo demais, o certo é normalizar o próprio MP3, não compensar aqui.
  final double volumeFactor;

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    category,
    lyrics,
    audioAsset,
    volumeFactor,
  ];
}
