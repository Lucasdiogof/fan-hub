import 'package:goias_app/features/club/domain/entities/club_song.dart';

/// Existência do hino confirmada em múltiplas fontes (Federação Paulista
/// de Futebol, Cifra Club, Letras.mus.br) — composição de Sapo e Renato
/// Silva, conhecido como "Hino do Massa Bruta". `lyrics`/`audioAsset`
/// ficam `null` de propósito:
///   - `lyrics`: NUNCA reproduzimos letra de música de fontes de terceiros
///     (direito autoral) — precisa vir de uma fonte com uso autorizado
///     (ex.: o próprio usuário, ou uma licença confirmada), igual foi
///     feito pro hino do Goiás.
///   - `audioAsset`: nenhum MP3 real cedido ainda (ASSET_GAP).
/// A UI já trata os dois casos (Play desabilitado, aviso "letra ainda não
/// disponível") sem precisar de nenhuma mudança de model.
class BragantinoSongsData {
  const BragantinoSongsData._();

  static const List<ClubSong> songs = [
    ClubSong(
      id: 'hino_oficial',
      title: 'Hino do Massa Bruta',
      category: ClubSongCategory.anthem,
    ),
  ];
}
