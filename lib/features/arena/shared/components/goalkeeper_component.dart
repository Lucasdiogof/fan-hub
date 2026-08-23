import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/arena/shared/arena_assets.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

enum KeeperPose { idle, diveLeft, diveRight, center }

/// Goleiro adversário visto de frente.
///
/// **Pose e movimento são coisas separadas.** O sprite (ou o desenho
/// procedural) só decide COMO o goleiro está posado num instante — parado,
/// impulso, mergulhando, caído. ONDE ele está na tela é sempre calculado
/// aqui a partir da geometria real do gol ([updateGoalBounds]) e do
/// progresso do mergulho ([_diveT]), nunca a partir de espaço transparente
/// dentro do PNG nem de números arbitrários de tela. Isso resolve os dois
/// problemas que apareceram nas tentativas anteriores: (1) usar padding do
/// sprite pra simular deslocamento fazia o personagem "flutuar" — agora o
/// PNG de cada pose é recortado rente ao conteúdo; (2) escalar cada frame
/// individualmente por uma medida do rosto quebrava com pose/rotação — a
/// escala agora é uma só, igual pra todos os frames, aplicada uma vez na
/// hora de montar o sheet (ver `_rebuild_keeper_v3.py`, não versionado).
///
/// Duas formas de desenhar, escolhidas automaticamente em [onLoad]:
/// - **Sprite** (`_renderSprite`), se [ArenaAssets.goalkeeperSheet] existir
///   — 5 frames de tamanho PRÓPRIO cada um (recorte justo ao conteúdo, sem
///   preencher um box comum — parado é naturalmente estreito e alto,
///   mergulhando é largo e baixo). `diveRight` espelha os mesmos frames
///   (`canvas.scale(-1,1)`), não existe sheet separado pro lado direito.
/// - **Procedural** (`_renderProcedural`), fallback enquanto o sprite não
///   estiver disponível — mantém o comportamento antigo (tamanho fixo,
///   `Anchor.bottomCenter`, mergulho animado via transform no `render`).
class GoalkeeperComponent extends PositionComponent {
  GoalkeeperComponent({required this.jersey}) : super(size: Vector2(85, 120), anchor: Anchor.bottomCenter);

  final Color jersey;
  KeeperPose pose = KeeperPose.idle;

  bool _diving = false;
  double _diveT = 0;
  static const double _diveDuration = 0.34;

  /// Duração só do "pulinho" central — mais curta e seca que o mergulho de
  /// verdade, pra ler como um salto rápido no lugar, não uma inclinação
  /// lenta (era isso que ficava estranho antes).
  static const double _centerHopDuration = 0.26;

  /// Retângulo real do gol (posição+tamanho), fornecido pelo jogo sempre
  /// que o layout muda — é a ÚNICA fonte de verdade pra onde o goleiro
  /// pode ir. Nunca usamos frações arbitrárias da tela.
  Rect _goalBounds = const Rect.fromLTWH(0, 0, 1, 1);

  void updateGoalBounds(Rect bounds) {
    _goalBounds = bounds;
    if (_diving) return;
    // Defensivo: fora de um mergulho o goleiro tem que estar sempre no
    // frame/tamanho base — reafirma isso toda vez que o layout muda, não
    // só em `resetToIdle`, pra nenhum caminho conseguir deixar `size`
    // "vazar" de um mergulho anterior pro estado parado.
    _currentFrame = _idleFrame;
    if (_hasSprite) size.setFrom(_effectiveSize(_idleFrame));
    _applyPosition(_goalBounds.center.dx, _goalBounds.bottom);
  }

  // --- Sprite sheet (opcional) -------------------------------------------
  static const int _idleFrame = 0;
  static const int _pushFrame = 1;
  static const int _diveStartFrame = 2;
  static const int _diveExtendedFrame = 3;
  static const int _landFrame = 4;

  /// Rects exatos de cada frame dentro do sheet — não são divisões iguais
  /// (os frames têm tamanhos diferentes de propósito), então ficam
  /// hardcoded a partir da montagem determinística do sheet.
  static const List<Rect> _frameRects = [
    Rect.fromLTWH(0, 0, 85, 124),
    Rect.fromLTWH(85, 0, 92, 114),
    Rect.fromLTWH(177, 0, 92, 84),
    Rect.fromLTWH(269, 0, 92, 71),
    Rect.fromLTWH(361, 0, 92, 61),
  ];

  /// Fração (x,y) dentro do próprio recorte de cada frame onde fica o
  /// ponto físico de referência — pés encostando no chão quando em pé,
  /// centro de massa quando no ar/caído (não há "pé no chão" pra ancorar
  /// depois que ele salta). Medido direto no PNG final (bounding box do
  /// alpha, não estimado) — é isso que substitui `Anchor.bottomCenter`
  /// fixo: o pivô muda com a pose, mas a POSIÇÃO física (resultado da
  /// trajetória) continua sendo a mesma referência em todo frame, então a
  /// troca de pose não pula nem flutua.
  static const List<Offset> _pivotFraction = [
    Offset(0.5, 0.952), // idle — pés (medido: bbox alpha vai até 95,2% da altura)
    Offset(0.5, 0.939), // impulso — pés, levemente agachado (medido: 93,9%)
    Offset(0.5, 0.50), // início do mergulho — centro de massa (conteúdo já sai centralizado no recorte)
    Offset(0.5, 0.50), // mergulho estendido — centro de massa
    Offset(0.5, 0.50), // queda — centro de massa
  ];

  /// Multiplicador de tamanho por pose, aplicado só no desenho (o pivô de
  /// todos os frames de mergulho é (0.5,0.5) — ver `_pivotFraction` — então
  /// aumentar esse valor faz o corpo crescer em volta do MESMO ponto
  /// físico, sem mexer em posição/trajetória). Medido direto no sheet
  /// (largura do maior blob de tom de pele = o rosto, isolado por
  /// componente conectado): idle/push saem com ~13px de rosto, os três
  /// frames de mergulho saem consistentemente em ~10px — uma razão de
  /// ~1,30 nos três, não valores diferentes por frame como antes. idle/push
  /// levaram um leve recuo extra (0.88) depois, por pedido explícito — o
  /// parado estava grande demais na tela, e isso também aproxima a
  /// diferença de tamanho aparente para o mergulho deitado no canto.
  static const List<double> _poseDrawScale = [0.88, 0.88, 1.30, 1.30, 1.30];

  Image? _sheet;
  int _currentFrame = _idleFrame;
  bool get _hasSprite => _sheet != null;

  /// Tamanho de desenho/hitbox do frame atual — rect original × correção
  /// de pose (ver `_poseDrawScale`). Único ponto que os dois (`update` e
  /// `_applyPosition`) leem, pra nunca ficarem dessincronizados.
  Vector2 _effectiveSize(int frameIndex) {
    final rect = _frameRects[frameIndex];
    final scale = _poseDrawScale[frameIndex];
    return Vector2(rect.width * scale, rect.height * scale);
  }

  @override
  Future<void> onLoad() async {
    try {
      final data = await rootBundle.load(ArenaAssets.goalkeeperSheet);
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _sheet = frame.image;
      anchor = Anchor.center;
      size.setFrom(_effectiveSize(_idleFrame));
      _applyPosition(_goalBounds.center.dx, _goalBounds.bottom);
    } catch (_) {
      // Sheet ainda não fornecido (ou inválido) — fica no fallback
      // procedural, sem erro nenhum pro resto do jogo.
      _sheet = null;
    }
  }

  /// Início do mergulho (ou do pulinho central) — chamado uma vez por
  /// cobrança, no instante de contato do pé com a bola. `KeeperPose.center`
  /// não se desloca pro lado nem troca de pose (continua na `_idleFrame`
  /// o tempo todo) — só um salto vertical rápido, sem sair do centro.
  void dive(KeeperPose target) {
    pose = target;
    _diving = target != KeeperPose.idle;
    _diveT = 0;
  }

  void resetToIdle() {
    pose = KeeperPose.idle;
    _diving = false;
    _diveT = 0;
    _currentFrame = _idleFrame;
    // Bug real encontrado aqui: só `position` era recalculada — `size`
    // ficava travada no valor do último frame do mergulho (ex.: o frame de
    // queda, escalado por `_poseDrawScale[4]`), porque `update()` só toca
    // `size` dentro do `if (!_diving) return;` — ou seja, nunca de novo
    // depois que a queda termina. `position` batia com o idle inicial,
    // mas `topLeftPosition` (o que realmente aparece na tela) não, porque
    // o cálculo do anchor usa `size`. Por isso "idle" parecia num
    // tamanho/posição diferente do inicial.
    if (_hasSprite) size.setFrom(_effectiveSize(_idleFrame));
    _applyPosition(_goalBounds.center.dx, _goalBounds.bottom);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_diving) return;
    final isCenterHop = pose == KeeperPose.center;
    final duration = isCenterHop ? _centerHopDuration : _diveDuration;
    _diveT = min(1, _diveT + dt / duration);
    // Pulinho central não troca de pose — só sobe e desce na mesma frame
    // parada, sem o "impulso" que antes causava a gingada.
    _currentFrame = isCenterHop ? _idleFrame : _frameForDiveT(_diveT);
    if (_hasSprite) size.setFrom(_effectiveSize(_currentFrame));
    final trajectory = _diveTrajectory();
    _applyPosition(trajectory.$1, trajectory.$2);
  }

  /// Só chamado com `pose` igual a `diveLeft`/`diveRight` — `center` não
  /// troca de frame (ver [update]), então não precisa de um branch aqui.
  int _frameForDiveT(double t) {
    if (t < 0.2) return _pushFrame;
    if (t < 0.45) return _diveStartFrame;
    if (t < 0.85) return _diveExtendedFrame;
    return _landFrame;
  }

  /// Posição física real (x,y) do mergulho nesse instante, derivada só da
  /// geometria do gol e do progresso — não de espaço vazio em nenhum PNG.
  /// `lerp` do centro até perto da trave (não a trave inteira: o corpo
  /// fica dentro da estrutura do gol, é a luva/braço do próprio sprite que
  /// completa a leitura de "quase alcançou o canto"), com um arco raso no
  /// Y que sobe um pouco na saída e volta pro chão perto do fim — sem
  /// exagero de altura.
  (double, double) _diveTrajectory() {
    final eased = Curves.easeOut.transform(_diveT);
    final direction = switch (pose) {
      KeeperPose.diveLeft => -1.0,
      KeeperPose.diveRight => 1.0,
      KeeperPose.idle || KeeperPose.center => 0.0,
    };
    final centerX = _goalBounds.center.dx;
    final groundY = _goalBounds.bottom;
    final targetX = centerX + direction * _goalBounds.width * 0.30;
    final x = centerX + (targetX - centerX) * eased;

    final liftPhase = (min(_diveT, 0.8) / 0.8).clamp(0.0, 1.0);
    // Pulinho central visível mas claramente menor que um mergulho de
    // verdade — 0.07 lê como "deu um salto", não como "quase caiu".
    final maxLift = _goalBounds.height * (direction == 0 ? 0.07 : 0.10);
    final lift = sin(pi * liftPhase) * maxLift;
    final y = groundY - lift;
    return (x, y);
  }

  /// Converte o ponto físico (x,y) pro `position` que o `Anchor.center`
  /// realmente usa, compensando o pivô específico do frame atual — sem
  /// isso, trocar de um frame estreito-e-alto pra um largo-e-baixo com
  /// `Anchor.center` ingênuo faria o corpo pular verticalmente.
  void _applyPosition(double physicalX, double physicalY) {
    if (!_hasSprite) {
      position.setValues(physicalX, physicalY);
      return;
    }
    final effective = _effectiveSize(_currentFrame);
    final pivot = _pivotFraction[_currentFrame];
    final centerX = physicalX + (0.5 - pivot.dx) * effective.x;
    final centerY = physicalY + (0.5 - pivot.dy) * effective.y;
    position.setValues(centerX, centerY);
  }

  late final Paint _body = Paint()..color = jersey;
  late final Paint _bodyShade = Paint()..color = Color.lerp(jersey, const Color(0xFF000000), 0.3)!;
  final Paint _skin = Paint()..color = ArenaColors.skin;
  final Paint _short = Paint()..color = const Color(0xFF0d0f11);
  final Paint _sock = Paint()..color = const Color(0xFF0d0f11);
  final Paint _boot = Paint()..color = const Color(0xFF16191c);
  final Paint _glove = Paint()..color = const Color(0xFFdfe3e6);
  final Paint _gloveShade = Paint()
    ..color = const Color(0xFFb9c0c4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final Paint _hair = Paint()..color = const Color(0xFF20140c);
  final Paint _shadow = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  late final Paint _arm = Paint()
    ..color = jersey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    if (_hasSprite) {
      _renderSprite(canvas);
    } else {
      _renderProcedural(canvas);
    }
  }

  /// Só desenha o frame — toda a posição/deslocamento já foi resolvido em
  /// [update]/[_applyPosition]. Nenhuma translação extra acontece aqui.
  void _renderSprite(Canvas canvas) {
    final rect = _frameRects[_currentFrame];
    final src = rect;
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.x / 2, size.y - 2), width: size.x * 0.7, height: size.y * 0.12),
      _shadow,
    );

    if (pose == KeeperPose.diveRight) {
      canvas.save();
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(_sheet!, src, dst, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(_sheet!, src, dst, paint);
    }
  }

  void _renderProcedural(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    final eased = Curves.easeOut.transform(_diveT);
    final direction = switch (pose) {
      KeeperPose.diveLeft => -1.0,
      KeeperPose.diveRight => 1.0,
      KeeperPose.idle || KeeperPose.center => 0.0,
    };
    // Leve inclinação de pronto-defesa mesmo parado; no mergulho o corpo
    // some pro lado (translação), sobe num arco curto (impulso) e gira.
    final dx = direction * w * 0.92 * eased;
    final dy = -sin(min(_diveT, 0.9) * pi / 0.9) * h * (direction == 0 ? 0.10 : 0.30) * (_diving ? 1 : 0);
    final rotation = 0.10 + direction * eased * 0.85;

    // A sombra acompanha o deslocamento horizontal (fica no "chão", por
    // isso ignora o `dy` do impulso) — sem isso ela ficava presa no meio
    // do gol enquanto o goleiro já tinha saído de cima dela.
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + dx, h - 2), width: w * 0.7, height: h * 0.05), _shadow);

    final headY = h * 0.10;
    final headR = w * 0.145;
    final torsoTop = h * 0.24;
    final torsoBottom = h * 0.58;
    final shortsBottom = h * 0.72;
    final kneeY = h * 0.85;
    final stance = w * (0.08 + 0.02 * eased.abs());

    canvas.save();
    canvas.translate(cx + dx, h + dy);
    canvas.rotate(rotation);
    canvas.translate(-cx, -h);

    final torso = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - w * 0.26, torsoTop, w * 0.52, torsoBottom - torsoTop),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    canvas.drawRRect(torso, _body);
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.26, torsoTop, w * 0.16, torsoBottom - torsoTop), _bodyShade);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.24, torsoBottom - 4, w * 0.48, shortsBottom - torsoBottom + 4),
        const Radius.circular(6),
      ),
      _short,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - stance - w * 0.16, shortsBottom - 4, w * 0.16, kneeY - shortsBottom + 4),
        const Radius.circular(5),
      ),
      _sock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + stance, shortsBottom - 4, w * 0.16, kneeY - shortsBottom + 4),
        const Radius.circular(5),
      ),
      _sock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - stance * 1.6 - w * 0.17, kneeY - 3, w * 0.2, h - kneeY + 3),
        const Radius.circular(5),
      ),
      _boot,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + stance * 0.6, kneeY - 3, w * 0.2, h - kneeY + 3),
        const Radius.circular(5),
      ),
      _boot,
    );

    _renderArms(canvas, w, h, torsoTop, direction, eased);

    canvas.drawCircle(Offset(cx, headY + headR * 0.15), headR, _skin);
    canvas.drawPath(
      Path()
        ..moveTo(cx - headR * 1.05, headY + headR * 0.6)
        ..quadraticBezierTo(cx - headR * 1.15, headY - headR * 0.8, cx, headY - headR * 1.25)
        ..quadraticBezierTo(cx + headR * 1.15, headY - headR * 0.8, cx + headR * 1.05, headY + headR * 0.6)
        ..quadraticBezierTo(cx + headR * 0.9, headY - headR * 0.05, cx, headY - headR * 0.3)
        ..quadraticBezierTo(cx - headR * 0.9, headY - headR * 0.05, cx - headR * 1.05, headY + headR * 0.6)
        ..close(),
      _hair,
    );

    canvas.restore();
  }

  void _renderArms(Canvas canvas, double w, double h, double torsoTop, double direction, double eased) {
    final armPaint = _arm;
    final shoulderY = torsoTop + h * 0.06;
    final left = Offset(w * 0.24, shoulderY);
    final right = Offset(w * 0.76, shoulderY);

    late final Offset leftHand;
    late final Offset rightHand;
    if (direction == 0) {
      // Idle e `center` (que não anima mais — ver `dive`): mãos prontas à
      // frente do corpo, paradas. `eased` fica em 0 pro `center` já que
      // `_diveT` nunca avança, então isso vira um no-op sem precisar de
      // um branch a mais.
      final lift = eased * h * 0.30;
      leftHand = Offset(left.dx - w * 0.05, shoulderY + h * 0.24 - lift);
      rightHand = Offset(right.dx + w * 0.05, shoulderY + h * 0.24 - lift);
    } else {
      // Mergulho: o braço do lado do mergulho estica bem na direção da
      // bola, o outro acompanha o corpo — junto com a rotação em `render`,
      // isso é o que faz parecer salto e não arrasto lateral.
      final reach = w * (0.30 + 0.45 * eased);
      final lift = h * 0.10 * eased;
      leftHand = Offset(left.dx + direction * reach * 0.85, shoulderY - lift - h * 0.06 * eased);
      rightHand = Offset(right.dx + direction * reach, shoulderY - lift - h * 0.10 * eased);
    }

    canvas.drawLine(left, leftHand, armPaint);
    canvas.drawLine(right, rightHand, armPaint);
    canvas.drawCircle(leftHand, w * 0.078, _glove);
    canvas.drawCircle(leftHand, w * 0.078, _gloveShade);
    canvas.drawCircle(rightHand, w * 0.078, _glove);
    canvas.drawCircle(rightHand, w * 0.078, _gloveShade);
  }
}
