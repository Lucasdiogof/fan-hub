/// Caminhos de asset do clube — pro Goiás embrulha os valores de
/// `AppAssets` (que ficam em `lib/assets/branding/goias/`), pro Bragantino
/// aponta pros próprios arquivos em `lib/assets/branding/bragantino/`.
/// Consumido de verdade hoje (crest no login/PDF do ingresso, escudo em
/// `PageTitle`, marca d'água da Arena, fotos de elenco/Quem Vestiu o
/// Manto, banner da Loja) — não é mais só um wrapper sem uso real.
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
    this.storeHomeBanners = const [],
    this.storeCatalogAssetPath,
    this.membershipFaqAssetPath,
    this.splashVideo,
    this.splashLogo,
    this.authCrest,
    this.squadPhotos = const {},
    this.guessPlayerPhotos = const {},
  });

  /// Traço vetorial (SVG) do escudo, tingível — hoje só o PDF do ingresso
  /// (`ticket_pdf.dart`) lê isto de verdade. Selo de login usa [authCrest]
  /// desde o rebrand Esmeraldino App (ver abaixo); deliberadamente um
  /// campo SEPARADO, pra nunca acoplar "o que aparece no login" a "o que
  /// vai no PDF do ingresso" de novo.
  final String crest;
  final String crestBadge;
  final String crest3d;
  final String loginBackground;

  /// `null` quando o clube ainda não tem foto oficial de estádio — mesmo
  /// padrão do [splashVideo]. `StadiumBackdrop` já sabe desenhar um fundo
  /// procedural (gradiente + holofotes + grão) nesse caso, então `null`
  /// nunca deixa a tela sem fundo.
  final String? stadium;

  /// `null` quando o clube ainda não tem foto oficial de estádio/torcida
  /// pro Hero do próximo jogo (Home) — mesmo padrão de [stadium]:
  /// `StadiumBackdrop` já desenha um fundo procedural (gradiente +
  /// holofotes + grão) nesse caso, nunca um placeholder genérico
  /// esticado na tela.
  final String? matchHero;
  final String tacticsBoardIllustration;
  final String arenaStadiumIcon;
  final String arenaStadiumPhoto;
  final String storeBanner;

  /// Banners de topo da Home da Loja (`StoreBannerCarousel`) — **por
  /// clube**, decide sozinho pela quantidade: 0 = seção não aparece; 1 =
  /// imagem fixa, sem carousel/autoplay/dots (preserva o comportamento
  /// único de sempre); >1 = carousel com autoplay. Nunca um `if (club ==
  /// ...)` na UI — o widget só olha `.length`. Vazio por padrão: um clube
  /// sem banner configurado simplesmente não mostra a seção, nunca herda
  /// o de outro clube.
  final List<String> storeHomeBanners;

  /// Path do JSON bundled com o catálogo da Loja (`rootBundle.loadString`,
  /// ver `MockStoreRepository`) — **por clube**, nunca um path fixo lido
  /// direto pelo repositório. `null` quando o clube ainda não tem catálogo
  /// próprio coletado: a Loja fica com 0 produtos (nunca lança, nunca cai
  /// pro JSON de outro clube) — combinado com `hasStore=false`, a tela nem
  /// chega a ser aberta enquanto isso for verdade.
  final String? storeCatalogAssetPath;

  /// Path do JSON bundled com o FAQ do Sócio (`MembershipFaqDataSource`,
  /// fallback offline quando o Supabase não devolve linha nenhuma) — **por
  /// clube**, nunca um path fixo lido direto pelo datasource. `null` quando
  /// o clube não tem FAQ local próprio coletado: o fallback offline vira 0
  /// categorias (nunca lança, nunca cai pro FAQ de outro clube) — hoje é o
  /// caso do Bragantino (Massa Bruta, `hasMembership=true` desde
  /// 2026-09-11): sem conteúdo de FAQ próprio ainda, o path fica `null` e
  /// a seção de Dúvidas Frequentes só mostra o que o Supabase do
  /// Bragantino tiver (hoje: nada) — nunca cai pro JSON do Goiás.
  final String? membershipFaqAssetPath;

  /// Vídeo da splash (`VideoSplashView`) — `null` quando o clube ainda não
  /// tem vídeo oficial próprio. NUNCA cai pro vídeo de outro clube: `null`
  /// aqui faz `SplashVideoPage` usar `StaticLogoSplash` (o mesmo fallback
  /// já usado pro iOS Web/PWA) em vez de qualquer vídeo.
  final String? splashVideo;

  /// Imagem da splash ESTÁTICA (`StaticLogoSplash` — usada quando
  /// [splashVideo] é `null`, e sempre no iOS Web/PWA mesmo com vídeo
  /// configurado). `null` cai pro comportamento de sempre ([crestBadge]
  /// sobre o fundo neutro da splash nativa). Quando definido, também troca
  /// o fundo pra `branding.light.primary` — pensado pra uma marca própria
  /// (não o escudo) que já vem com o próprio fundo colorido, tipo um app
  /// icon: as duas coisas mudam juntas, nunca logo nova sobre fundo velho
  /// ou vice-versa.
  final String? splashLogo;

  /// Selo mostrado no topo das telas de login/cadastro/recuperação de
  /// senha (`AuthScaffold._CrestSeal`). `null` cai pro comportamento de
  /// sempre: [crest] (SVG vetorial) tingido de branco sólido — só funciona
  /// pra um traço monocromático. Quando definido (ex.: Goiás, desde o
  /// rebrand Esmeraldino App), mostra a imagem CRUA, sem tingir — pra uma
  /// marca colorida (mascote, não escudo) que já vem com as próprias cores
  /// e fundo, tingir de branco destruiria a arte.
  final String? authCrest;

  /// Fotos do elenco embutidas no app, por `SquadMember.id` — **por
  /// clube**, nunca um mapa global. Antes era uma constante única
  /// (`squadPhotoAssets`) consultada por id solto: como os ids são slugs
  /// curtos e repetíveis ("juninho", "pedrinho", "danilo"), bastava um
  /// clube novo ter um atleta homônimo pra o rosto de um jogador do Goiás
  /// aparecer no card de outro clube. Vazio = clube ainda sem foto local;
  /// a tela cai pra `photo_url` do banco e, se não houver, pro número da
  /// camisa — nunca pra foto de outro atleta.
  final Map<String, String> squadPhotos;

  /// Fotos pro Quem Vestiu o Manto, por `GuessPlayer.id`/`photo_key` — **por
  /// clube**, e SEPARADO de [squadPhotos] de propósito: `SquadAvatar` sempre
  /// trata uma entrada de [squadPhotos] como asset LOCAL (`Image.asset`,
  /// nunca detecta URL); este mapa aqui pode misturar asset local (foto
  /// histórica) e URL remota (foto do elenco atual reaproveitada, ver
  /// `GuessBlurredPhoto`, que detecta os dois). Reusar [squadPhotos] pras
  /// duas coisas quebra a aba Elenco silenciosamente pra qualquer atleta
  /// que também tenha carta histórica — achado ao vivo com o Cleiton
  /// (2026-09-08). Vazio = clube ainda sem foto pro jogo.
  final Map<String, String> guessPlayerPhotos;
}
