import 'package:goias_app/features/club/domain/entities/club_song.dart';

/// Fonte local e estática do Hino & Músicas — sem backend, sem API, sem
/// scraping. Pra adicionar uma faixa nova: coloque o MP3 em
/// `lib/assets/audio/club/hinos/` ou `lib/assets/audio/club/musicas/`
/// (conforme a categoria) e acrescente uma entrada aqui com
/// id/title/artist/category/lyrics/audioAsset. O resto da tela (lista,
/// player, página da letra) funciona sozinho, sem precisar de nenhum
/// widget novo.
///
/// As faixas sem `audioAsset`/`lyrics` ainda esperam o arquivo/texto real.
/// `audioAsset: null` é proposital: nunca aponte pra um caminho de arquivo
/// que ainda não existe no projeto, ou o player tenta carregar um asset
/// inexistente. Enquanto isso o Play some/fica desabilitado nos cards, e a
/// letra mostra o aviso "ainda não disponível".
/// Letra oficial do Hino do Goiás — a mesma em todas as versões/regravações
/// (Versão Oficial, Mr. Gyn etc.), só a interpretação muda.
const _hinoLyrics = '''
Eu sou Goiás Esporte Clube
Eu sou Goiás, eu sou Goiás e vou gritar

Até o peito me doer
Até perder a voz eu sou Goiás
Eu sou Goiás até morrer, eu sou Goiás,
Eu sou Goiás de coração

Cada vez nossa torcida cresce mais
Eternamente serei Goiás
Nosso Clube é a nossa glória
A nossa garra, nossa gente, nossa história

O amor pela nossa bandeira
É para nós a maior vitória

Nosso Clube é a nossa glória
Nossa garra, nossa gente, nossa história
A vida toda eu vou torcer
Eu sou Goiás, Goiás, até morrer

Eu sou Goiás Esporte Clube
Eu sou Goiás, eu sou Goiás e vou gritar

Até o peito me doer
Até perder a voz eu sou Goiás
Eu sou Goiás até morrer
Eu sou Goiás, eu sou Goiás de coração

Cada vez nossa torcida cresce mais
Eternamente serei Goiás.''';

class ClubSongsData {
  const ClubSongsData._();

  static const List<ClubSong> songs = [
    // Hino oficial — letra de Paulo Sérgio Valle, Tavito e Regininha,
    // melodia de Gilberto Gouveia. Gravação original de 1977, pelo Coro
    // Zurana.
    ClubSong(
      id: 'hino_oficial',
      title: 'Hino do Goiás',
      artist: 'Versão Oficial',
      category: ClubSongCategory.anthem,
      audioAsset: 'lib/assets/audio/club/hinos/hino_oficial.mp3',
      lyrics: _hinoLyrics,
    ),
    ClubSong(
      id: 'hino_zeze_di_camargo',
      title: 'Hino do Goiás',
      artist: 'Zezé di Camargo',
      category: ClubSongCategory.anthem,
      audioAsset: 'lib/assets/audio/club/hinos/hino_zeze_di_camargo.mp3',
      lyrics: _hinoLyrics,
    ),
    ClubSong(
      id: 'hino_mr_gyn',
      title: 'Hino do Goiás',
      artist: 'Mr. Gyn',
      category: ClubSongCategory.anthem,
      audioAsset: 'lib/assets/audio/club/hinos/hino_mr_gyn.mp3',
      lyrics: _hinoLyrics,
    ),
    ClubSong(
      id: 'sou_goias_e_dai',
      title: 'Sou Goiás, e daí?',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/sou_goias_e_dai.mp3',
      lyrics: '''
Vamos, vamos, vamos, FORÇA JOVEM
Vamos para cantar e vibrar
Sou GOIÁS, e daí?
Louco por ti! Louco por ti!

Há muito tempo que vou
Aqui no Serra ou em qualquer lugar
Muitas vezes chorei, também festejei
Disposto a cantar

Nada pode abalar
Tudo o que eu sinto por você
Sou GOIÁS, e daí?
Louco por ti! Louco por ti!''',
    ),
    ClubSong(
      id: 'sou_goias_com_muito_amor',
      title: 'Sou Goiás com muito amor',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/sou_goias_com_muito_amor.mp3',
      lyrics: '''
A nossa torcida está sempre ao seu lado,
Não importa onde você jogar,
Pra vencer, tem que ser guerreiro,
Pra te ver, sou sempre o primeiro,
E dá-lhe, dá-lhe, ôôô!
Sou Goiás com muito amor.''',
    ),
    ClubSong(
      id: 'sou_esmeraldino',
      title: 'Sou esmeraldino',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/sou_esmeraldino.mp3',
      lyrics: '''
Olê, olê, olê,
Olê, olê, olê, Goiás!
Olê, olê, olê,
A cada dia te amo mais...
Sou esmeraldino,
E o amor que eu sinto
Hoje vou cantar!

Olê, olê, olê,
Olê, olê, olê, Goiás!
Olê, olê, olê,
A cada dia te amo mais...
Sou esmeraldino,
E o amor que eu sinto
Hoje vou cantar!''',
    ),
    ClubSong(
      id: 'sou_verdao_de_coracao',
      title: 'Sou Verdão de coração',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/sou_verdao_de_coracao.mp3',
      lyrics: '''
Onde você jogar,
Eu vou de coração,
Com meu manto sagrado,
Camisa do Verdão.

Maior do Centro-Oeste,
Nossa torcida é show,
Cantando e vibrando,
Pedindo mais um gol.

Sou Verdão, sou Verdão,
Sou Verdão de coração.''',
    ),
    ClubSong(
      id: 'alegria',
      title: 'Alegria',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/alegria.mp3',
      lyrics: '''
Dá-lhe alegria, alegria no coração,
Daria a vida inteira pra ser campeão.
A Taça Libertadores é obsessão,
Mas tem que jogar com a alma e o coração.

Olê, olê, olê, olê!
Canta aí!
Eu canto, eu sou Goiás até morrer.''',
    ),
    ClubSong(
      id: 'ta_ligado',
      title: 'Tá ligado',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/ta_ligado.mp3',
      lyrics: '''
Eu vou cantar um funk pra ninguém ficar parado,
Carrego no meu peito o meu time apaixonado.
Eu sou da Força Jovem, a maior do meu estado,
E quem ficar parado vai tomar um “tá ligado”!

Uh, tá ligado!
Uh, tá ligado!
Uh, tá ligado!
Uh, tá ligado!

Sai, sai da frente!
Sai que a Força Jovem é chapa quente!''',
    ),
    ClubSong(
      id: 'sempre_serei_goias',
      title: 'Sempre serei Goiás',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/sempre_serei_goias.mp3',
      lyrics: '''
Sempre serei Goiás,
Te apoiando até o final.
Eu sou da Força Jovem,
A maior da capital!

(O quê? O quê?)

Ôoooooooooo,
Ôoooooooooo,
Ôooooooo,
Ôoooo!''',
    ),
    ClubSong(
      id: 'coracao_verde_e_branco',
      title: 'Coração verde e branco',
      category: ClubSongCategory.fanChant,
      audioAsset: 'lib/assets/audio/club/musicas/coracao_verde_e_branco.mp3',
      lyrics: '''
Alegria, alegria
Olê, olê, olá
Sou da Força, estou em festa
Eu faço carnaval

Quando meu Goiás joga
Eu vou para incentivar
Ganhando ou perdendo
Não paro de cantar

Meu Deus, quando eu morrer
Eu quero o meu caixão
Pintado de verde e branco
Como o meu coração''',
    ),
    // Mais músicas esmeraldinas — adicionar aqui quando as faixas forem
    // enviadas.
  ];
}
