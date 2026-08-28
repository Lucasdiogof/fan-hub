/// Ponto único de referência para assets visuais do app. Fotografias reais
/// que ainda não existem ficam `null`, e os componentes que os consomem já
/// sabem cair para um fundo procedural elegante (ver [StadiumBackdrop])
/// enquanto isso. Quando a foto existir, é só apontar o caminho aqui.
class AppAssets {
  const AppAssets._();

  static const String goiasCrest = 'lib/assets/branding/logo.svg';

  /// Escudo oficial do Goiás em PNG, com as cores reais (não é um traço
  /// monocromático pra tingir) — usado sempre que o app precisa MOSTRAR o
  /// escudo do Goiás como identificação de time (confrontos, jogos,
  /// loadings), nunca precisando da rede pra isso. Ver [goiasCrest] pro
  /// traço vetorial tingível usado nos poucos lugares que ainda precisam de
  /// uma cor sólida (selo do login, PDF do ingresso).
  static const String goiasCrestBadge = 'lib/assets/branding/goias_crest.png';

  static const String loginBackground =
      'lib/assets/branding/background_login.png';

  static const String stadium = 'lib/assets/branding/banner.png';
  static const String matchHero = 'lib/assets/branding/banner_match.png';
  static const String? fans = null;
  static const String? featuredNewsCover = null;
  static const String? membershipBackground = null;

  /// Ilustração de prancheta tática pro card "Escalação da Torcida" da Home.
  static const String tacticsBoardIllustration =
      'lib/assets/branding/tactics_board.png';

  /// As 3 cenas da splash animada (ver `AnimatedImageSplash`) — usada no
  /// lugar do vídeo só em iOS Web/PWA, onde o Safari bloqueia autoplay de
  /// vídeo silenciosamente. Mesma arte-final do vídeo, em 3 quadros fixos.
  /// splash2/3 chegaram como PNG de ~1.3-1.7MB cada (conteúdo fotográfico,
  /// formato errado pra isso) — recodificados pra JPEG qualidade 85 sem
  /// perda visível (mesmo pixel, só entrega mais rápida): ~96KB/222KB. Em
  /// rede móvel, 3.2MB de PNG podia sozinho estourar os 7s do timer de
  /// segurança da splash antes da 1ª cena sequer aparecer.
  static const String splashScene1 = 'lib/assets/splash1.jpeg';
  static const String splashScene2 = 'lib/assets/splash2.jpg';
  static const String splashScene3 = 'lib/assets/splash3.jpg';
}
