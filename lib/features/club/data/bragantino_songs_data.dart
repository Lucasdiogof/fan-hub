import 'package:goias_app/features/club/domain/entities/club_song.dart';

/// Existência do hino confirmada em múltiplas fontes (Federação Paulista
/// de Futebol, Cifra Club, Letras.mus.br, futebolinterior.com.br) —
/// título "Massa Bruta Campeão" (citado explicitamente por uma fonte;
/// outras só dizem "Hino do Massa Bruta"/"Hino Oficial do Clube Atlético
/// Bragantino" sem título formal). Letra de Renato Silva, música de Sapo.
///
/// CONFLITO NÃO RESOLVIDO — ano de criação: uma fonte diz 1988 (logo após
/// o acesso via Paulista A2 daquele ano), outra diz 1990 ("10 dias antes
/// da final do Paulista" — que o clube de fato venceu em 1990). As duas
/// fontes concordam nos autores, divergem no ano/contexto exato. Não
/// escolhido um dos dois sem confirmação melhor.
///
/// `lyrics`/`audioAsset` ficam `null` de propósito:
///   - `lyrics`: NUNCA reproduzimos letra de música de fonte de terceiro
///     (direito autoral) — precisa vir de uma fonte com uso autorizado
///     (ex.: o próprio usuário, ou uma licença confirmada), igual foi
///     feito pro hino do Goiás. Nenhum link de áudio oficial (canal do
///     clube/Spotify) foi encontrado — só um embed de Facebook de
///     terceiro, que não é uma fonte licenciada confiável.
///   - `audioAsset`: nenhum MP3 real cedido ainda (ASSET_GAP).
/// A UI já trata os dois casos (Play desabilitado, aviso "letra ainda não
/// disponível") sem precisar de nenhuma mudança de model.
class BragantinoSongsData {
  const BragantinoSongsData._();

  static const List<ClubSong> songs = [
    ClubSong(
      id: 'hino_oficial',
      title: 'Massa Bruta Campeão',
      category: ClubSongCategory.anthem,
    ),
  ];
}
