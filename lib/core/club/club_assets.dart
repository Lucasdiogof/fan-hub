/// Caminhos de asset do clube — hoje só EMBRULHA os mesmos valores de
/// `AppAssets` (nenhum arquivo movido, nenhum path mudado). `AppAssets`
/// continua existindo e sendo a fonte real; isto é só a forma de expor os
/// mesmos paths como instância em vez de `static const`, pra quando um 2º
/// clube justificar `lib/assets/branding/<clubCode>/...` (ver
/// `docs/multiclub/10_club_config.md#3`). Nenhum consumidor real lê
/// `ClubConfig.assets` ainda.
class ClubAssets {
  const ClubAssets({
    required this.crest,
    required this.crestBadge,
    required this.crest3d,
    required this.loginBackground,
    required this.stadium,
    required this.matchHero,
    required this.tacticsBoardIllustration,
    required this.arenaStadiumIcon,
    required this.arenaStadiumPhoto,
    required this.storeBanner,
    this.splashVideo,
  });

  final String crest;
  final String crestBadge;
  final String crest3d;
  final String loginBackground;
  final String stadium;
  final String matchHero;
  final String tacticsBoardIllustration;
  final String arenaStadiumIcon;
  final String arenaStadiumPhoto;
  final String storeBanner;

  /// Vídeo da splash (`VideoSplashView`) — `null` quando o clube ainda não
  /// tem vídeo oficial próprio. NUNCA cai pro vídeo de outro clube: `null`
  /// aqui faz `SplashVideoPage` usar `StaticLogoSplash` (o mesmo fallback
  /// já usado pro iOS Web/PWA) em vez de qualquer vídeo.
  final String? splashVideo;
}
