/// Ponto único de referência para assets visuais do app. Fotografias reais
/// que ainda não existem ficam `null`, e os componentes que os consomem já
/// sabem cair para um fundo procedural elegante (ver [StadiumBackdrop])
/// enquanto isso. Quando a foto existir, é só apontar o caminho aqui.
class AppAssets {
  const AppAssets._();

  static const String goiasCrest = 'lib/assets/branding/goias/logo.svg';

  /// Escudo oficial do Goiás em PNG, com as cores reais (não é um traço
  /// monocromático pra tingir) — usado sempre que o app precisa MOSTRAR o
  /// escudo do Goiás como identificação de time (confrontos, jogos,
  /// loadings), nunca precisando da rede pra isso. Ver [goiasCrest] pro
  /// traço vetorial tingível usado nos poucos lugares que ainda precisam de
  /// uma cor sólida (selo do login, PDF do ingresso).
  static const String goiasCrestBadge =
      'lib/assets/branding/goias/goias_crest.png';

  /// Render 3D do selo do Goiás (relevo, não achatado) — usado só como
  /// marca d'água decorativa em superfícies grandes (ex.: banner da Minha
  /// Trajetória), nunca como identificação de time (isso é
  /// [goiasCrestBadge]).
  static const String goiasCrest3d =
      'lib/assets/branding/goias/goias_crest_3d.jpg';

  static const String loginBackground =
      'lib/assets/branding/goias/background_login.png';

  static const String stadium = 'lib/assets/branding/goias/banner.png';
  static const String matchHero = 'lib/assets/branding/goias/banner_match.png';
  static const String? fans = null;
  static const String? featuredNewsCover = null;
  static const String? membershipBackground = null;

  /// Ilustração de prancheta tática pro card "Escalação da Torcida" da Home.
  static const String tacticsBoardIllustration =
      'lib/assets/branding/goias/tactics_board.png';

  /// Traço isométrico de estádio, sem fundo — versão anterior (linha) da
  /// marca d'água do card da Arena Esmeraldina, mantida pra rollback rápido.
  /// Ver [arenaStadiumPhoto] pra versão em uso.
  static const String arenaStadiumIcon =
      'lib/assets/branding/goias/arena_stadium.svg';

  /// Render colorido de estádio, sem fundo — marca d'água do card da Arena
  /// Esmeraldina na Home (ver [ArenaSpotlightCard]).
  static const String arenaStadiumPhoto =
      'lib/assets/branding/goias/arena_stadium.png';

  /// Foto da caixa/uniformes da Goiás Store, sem fundo e já tingida de
  /// verde escuro (duotone gravado no arquivo, igual [arenaStadiumPhoto])
  /// — usada no banner de entrada da loja na Home (ver [StoreEntryCard]).
  /// Nunca tingir em tempo de execução: toda tentativa via `ColorFiltered`
  /// externo ou `Image.color`/`colorBlendMode` quebrou a transparência do
  /// PNG (retângulo sólido) — bug de composição do Skia/Flutter.
  static const String storeBanner =
      'lib/assets/store/banners/goias/store_banner_green.png';
}
