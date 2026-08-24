import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_logic.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/arena/shared/components/ball_component.dart';
import 'package:goias_app/features/arena/shared/components/field_component.dart';
import 'package:goias_app/features/arena/shared/components/goal_component.dart';
import 'package:goias_app/features/arena/shared/components/goalkeeper_component.dart';
import 'package:goias_app/features/arena/shared/components/player_component.dart';

class PenaltyHudData {
  const PenaltyHudData({required this.attempts, required this.goals, this.lastResult});

  final List<PenaltyResult> attempts;
  final int goals;
  final PenaltyResult? lastResult;
}

class PenaltyEndData {
  const PenaltyEndData({
    required this.shotResults,
    required this.goals,
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
  });

  /// Resultado real de cada uma das 5 cobranças, na ordem em que aconteceram
  /// — fonte de verdade do card final, nunca recalculado na UI.
  final List<PenaltyResult> shotResults;
  final int goals;
  final int score;
  final int bestScore;
  final bool isNewRecord;
}

class PenaltyGame extends FlameGame {
  PenaltyGame({required this.loadBest, required this.saveBest});

  final Future<int> Function() loadBest;
  final Future<void> Function(int score) saveBest;

  final ValueNotifier<PenaltyHudData> hud =
      ValueNotifier<PenaltyHudData>(const PenaltyHudData(attempts: [], goals: 0));
  final ValueNotifier<PenaltyEndData?> ended = ValueNotifier<PenaltyEndData?>(null);

  final Random _rng = Random();
  final List<PenaltyResult> _attempts = [];

  late final FieldComponent _field;
  late final GoalComponent _goal;
  late final GoalkeeperComponent _keeper;
  late final PlayerComponent _player;
  late final BallComponent _ball;

  PenaltyPhase _phase = PenaltyPhase.ready;
  int _best = 0;

  double _t = 0;
  double _duration = 0.6;
  double _startX = 0;
  double _startY = 0;
  double _targetX = 0;
  double _targetY = 0;
  double _curve = 0;
  ShotZone _keeperZone = ShotZone.center;
  PenaltyResult _pendingResult = PenaltyResult.goal;

  int get _goals => _attempts.where((result) => result.isGoal).length;
  // Centralizada exatamente sobre a marca do pênalti — a mesma fonte de
  // verdade que `FieldComponent` usa pra desenhar a marca, então bola e
  // marca nunca podem ficar fora de sincronia por acaso.
  double get _ballHomeX => size.x / 2;
  double get _ballHomeY => FieldComponent.penaltySpotY(size.y);
  double get _goalPlaneY => _goal.position.y + _goal.size.y;

  // Y cresce em direção à câmera (o gol fica nos y menores, perto do topo —
  // ver `_layout`/`FieldComponent`), então "atrás da bola" é y MAIOR que o
  // da bola, não menor.
  //
  /// De onde o jogador começa parado, bem atrás da bola — espaço suficiente
  /// pra uma corrida de 2-3 passadas até o contato, sem chegar perto da
  /// borda inferior da tela (gesto do sistema).
  double get _playerStartY => _ballHomeY + size.y * 0.045;

  /// Onde ele para depois da corrida, já com o pé de apoio ao lado da bola.
  double get _playerContactY => _ballHomeY + size.y * 0.012;

  @override
  Color backgroundColor() => ArenaColors.arenaBottom;

  @override
  Future<void> onLoad() async {
    _field = FieldComponent();
    _goal = GoalComponent();
    _keeper = GoalkeeperComponent(jersey: ArenaColors.opponentKeeper);
    _player = PlayerComponent(jersey: ArenaColors.goiasOutfield)..onContactFrame = _strikeBall;
    // ~11% da altura do sprite do jogador (192px) — bola pequena e
    // proporcional, não um "botão" de UI grande no meio da cena.
    _ball = BallComponent(radius: 11);
    await addAll([_field, _goal, _keeper, _player, _ball]);
    _layout();
    _best = await loadBest();
    overlays.add('hud');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Nunca reposiciona em cima de uma resolução degenerada — sem essa
    // guarda, um resize acidental com w/h zerado (ex.: um frame no meio de
    // uma troca de layout) jogaria gol/goleiro/jogador pra (0,0), no canto
    // superior esquerdo, até o próximo resize de verdade corrigir.
    if (isLoaded && size.x > 0 && size.y > 0) _layout();
  }

  void _layout() {
    final w = size.x;
    final h = size.y;
    final goalW = w * 0.62;
    final goalH = h * 0.16;
    _goal.position = Vector2(w * 0.19, h * 0.10);
    _goal.size = Vector2(goalW, goalH);
    // Única fonte de verdade pra onde o goleiro pode ir — o componente
    // deriva toda a trajetória do mergulho a partir desse retângulo, nunca
    // de números soltos daqui.
    _keeper.updateGoalBounds(Rect.fromLTWH(_goal.position.x, _goal.position.y, goalW, goalH));
    // Só força a posição de "parado, prestes a começar" fora de uma
    // cobrança em andamento — senão um resize no meio da corrida/chute
    // teleportaria o jogador de volta pro início, cortando a animação.
    if (_phase == PenaltyPhase.ready) {
      _player.position.setValues(w / 2, _playerStartY);
      _ball.position.setValues(_ballHomeX, _ballHomeY);
      _ball.scale.setValues(1, 1);
      _ball.spin = 0;
    }
  }

  void shoot(Offset swipe) {
    if (_phase != PenaltyPhase.ready) return;
    final swipeUp = -swipe.dy;
    if (swipeUp < 12) return;

    final aimX = (swipe.dx / (size.x * 0.42)).clamp(-1.0, 1.0);
    final power = (swipeUp / (size.y * 0.32)).clamp(0.35, 1.2);

    // Decidido agora, de forma independente da mira do usuário — mas só
    // animado lá na frente, no momento do contato (ver `_beginShot`), pra
    // não parecer que o goleiro "leu" o chute antes de ele acontecer.
    _keeperZone = ShotZone.values[_rng.nextInt(3)];

    final goalW = _goal.size.x;
    final center = size.x / 2;
    final error = (_rng.nextDouble() * 2 - 1) * power * goalW * 0.12;
    _targetX = center + aimX * goalW * 0.62 + error;
    _targetY = _goalPlaneY;
    _startX = _ballHomeX;
    _startY = _ballHomeY;
    _curve = aimX * goalW * 0.10;
    _duration = 0.72 - power * 0.18;
    _pendingResult = _resolveResult();

    // Trava novo input (nenhuma fase depois de `ready` aceita outro swipe) e
    // inicia a corridinha de aproximação — a bola só sai do lugar no frame
    // visual de contato do pé, em `_strikeBall` (ver `_prepareKick`).
    _phase = PenaltyPhase.approaching;
    _player.startRunning();
    _player.add(
      MoveToEffect(
        Vector2(size.x / 2, _playerContactY),
        EffectController(duration: 0.28, curve: Curves.easeInOut),
        onComplete: _prepareKick,
      ),
    );
  }

  /// Pé de apoio já plantado ao lado da bola — dispara a animação de chute
  /// (recuo da perna) mas ainda NÃO move a bola nem o goleiro: isso só
  /// acontece em [_strikeBall], chamado pelo próprio `PlayerComponent`
  /// (`onContactFrame`) no instante visual em que o pé alcança a bola —
  /// sincronizado pelo progresso real da animação (sprite ou procedural),
  /// nunca por um delay arbitrário desacoplado dela.
  void _prepareKick() {
    if (_phase != PenaltyPhase.approaching) return;
    _player.playKick();
  }

  /// Frame de contato do pé com a bola — só agora a trajetória começa e o
  /// goleiro reage, sincronizado com o chute visual do jogador.
  void _strikeBall() {
    if (_phase != PenaltyPhase.approaching) return;
    _phase = PenaltyPhase.shooting;
    _t = 0;
    _animateKeeper();
  }

  /// Só escolhe a pose — [GoalkeeperComponent] deriva sozinho o
  /// deslocamento real (posição/trajetória) a partir do retângulo do gol
  /// já entregue em [_layout] via `updateGoalBounds`.
  void _animateKeeper() {
    final target = switch (_keeperZone) {
      ShotZone.left => KeeperPose.diveLeft,
      ShotZone.right => KeeperPose.diveRight,
      ShotZone.center => KeeperPose.center,
    };
    _keeper.dive(target);
  }

  PenaltyResult _resolveResult() {
    return resolvePenalty(
      targetX: _targetX,
      goalLeft: _goal.position.x,
      goalWidth: _goal.size.x,
      keeperZone: _keeperZone,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_phase != PenaltyPhase.shooting) return;
    _t += dt / _duration;
    if (_t >= 1) {
      _t = 1;
      _applyTrajectory();
      _resolveShot();
      return;
    }
    _applyTrajectory();
  }

  void _applyTrajectory() {
    final eased = _t * _t;
    final bx = _startX + (_targetX - _startX) * eased + _curve * sin(pi * _t);
    final by = _startY + (_targetY - _startY) * eased;
    _ball.position.setValues(bx, by);
    final s = 1 - 0.52 * _t;
    _ball.scale.setValues(s, s);
    final direction = (_targetX - _startX) >= 0 ? 1 : -1;
    _ball.spin = direction * _t * pi * 6;
  }

  void _resolveShot() {
    _phase = PenaltyPhase.resolving;
    _attempts.add(_pendingResult);
    hud.value = PenaltyHudData(attempts: List.of(_attempts), goals: _goals, lastResult: _pendingResult);
    add(TimerComponent(period: 1.05, removeOnFinish: true, onTick: _afterResult));
  }

  void _afterResult() {
    if (_attempts.length >= penaltyTotalAttempts) {
      _finish();
      return;
    }
    _keeper.resetToIdle();
    _ball.position.setValues(_ballHomeX, _ballHomeY);
    _ball.scale.setValues(1, 1);
    _ball.spin = 0;
    _player.stopRunning();
    _player.position.setValues(size.x / 2, _playerStartY);
    _phase = PenaltyPhase.ready;
    hud.value = PenaltyHudData(attempts: List.of(_attempts), goals: _goals);
  }

  Future<void> _finish() async {
    _phase = PenaltyPhase.finished;
    final goals = _goals;
    final score = penaltyScore(goals);
    final isNewRecord = score > _best;
    if (isNewRecord) {
      _best = score;
      await saveBest(score);
    }
    // A tela de resultado agora é uma página própria (`PenaltyResultPage`),
    // não um overlay sobre este jogo — quem escuta `ended` fecha esta
    // página e abre a outra. "Jogar novamente" abre uma `PenaltyGame` nova
    // do zero em vez de reaproveitar esta instância já finalizada.
    ended.value = PenaltyEndData(
      shotResults: List.unmodifiable(_attempts),
      goals: goals,
      score: score,
      bestScore: _best,
      isNewRecord: isNewRecord,
    );
  }
}
