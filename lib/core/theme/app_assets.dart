/// Ponto único de referência para assets visuais do app. Fotografias reais
/// que ainda não existem ficam `null`, e os componentes que os consomem já
/// sabem cair para um fundo procedural elegante (ver [StadiumBackdrop])
/// enquanto isso. Quando a foto existir, é só apontar o caminho aqui.
class AppAssets {
  const AppAssets._();

  static const String goiasCrest = 'lib/assets/branding/logo.svg';

  static const String stadium = 'lib/assets/branding/banner.png';
  static const String matchHero = 'lib/assets/branding/banner_match.png';
  static const String? fans = null;
  static const String? featuredNewsCover = null;
  static const String? membershipBackground = null;

  /// Ilustração de prancheta tática pro card "Escalação da Torcida" da Home.
  static const String tacticsBoardIllustration =
      'lib/assets/branding/tactics_board.png';
}
