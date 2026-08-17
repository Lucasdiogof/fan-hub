/// Ponto único de referência para assets visuais do app. Fotografias reais
/// (Serrinha, torcida, jogadores) ainda não existem no projeto — os campos
/// ficam `null` até serem adicionadas, e os componentes que os consomem já
/// sabem cair para um fundo procedural elegante (ver [StadiumBackdrop])
/// enquanto isso. Quando a foto existir, é só apontar o caminho aqui.
class AppAssets {
  const AppAssets._();

  static const String goiasCrest = 'lib/assets/logo.svg';

  static const String? stadium = null;
  static const String? fans = null;
  static const String? featuredNewsCover = null;
  static const String? membershipBackground = null;
}
