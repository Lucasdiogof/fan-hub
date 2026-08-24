/// Paths dos assets reais da Arena.
///
/// [playerKickSheet] e [goalkeeperSheet] são OPCIONAIS: `PlayerComponent` e
/// `GoalkeeperComponent` tentam carregá-los e, se o arquivo ainda não
/// existir (caso de hoje), caem de volta pro render procedural em
/// `Path`/`RRect` sem erro — ver `_loadSpriteSheet` em cada componente.
/// Quando os PNGs forem colocados nesses paths, o jogo passa a usar sprite
/// automaticamente, sem nenhuma mudança de código adicional.
class ArenaAssets {
  const ArenaAssets._();

  static const String _base = 'lib/assets/games/penalty';

  static const crowdBanner = '$_base/crowd_banner.jpg';

  /// Bola de futebol clássica, PNG quadrado com fundo transparente — a bola
  /// preenche o quadro de borda a borda. `BallComponent` desenha o sprite
  /// dentro do próprio tamanho; a sombra no chão continua sendo feita por
  /// código, separada da imagem.
  static const ball = '$_base/ball.png';

  /// 6 frames horizontais de 384x768px cada (2304x768 total), fundo
  /// transparente: idle, passo esquerdo, passo direito, prepara chute,
  /// contato, follow-through.
  static const playerKickSheet = '$_base/player_kick_sheet.png';

  /// 5 frames horizontais de 300x540px cada (1500x540 total), fundo
  /// transparente: idle, impulso, início do mergulho, mergulho estendido,
  /// queda — sempre pro lado esquerdo (o direito é espelhado em runtime).
  static const goalkeeperSheet = '$_base/goalkeeper_sheet.png';

  static const String _keepy = 'lib/assets/games/keepy_uppy';

  /// Poses do jogador nas embaixadinhas (de costas, uniforme verde nº 10),
  /// todas 1024x1536 no mesmo canvas — desenhadas no mesmo rect pra o corpo
  /// nunca mudar de escala/âncora entre as poses.
  static const keepyPlayerIdle = '$_keepy/player_idle.png';
  static const keepyPlayerJuggleLeft = '$_keepy/player_juggle_left.png';
  static const keepyPlayerJuggleRight = '$_keepy/player_juggle_right.png';
  static const keepyPlayerJuggleKnee = '$_keepy/player_juggle_knee.png';
}
