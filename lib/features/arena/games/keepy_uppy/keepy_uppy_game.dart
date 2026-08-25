import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/components/keepy_uppy_ball_shadow.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/components/keepy_uppy_feedback.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/components/keepy_uppy_field.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/components/keepy_uppy_player.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/components/keepy_uppy_tap_target.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/keepy_uppy_models.dart';
import 'package:goias_app/features/arena/shared/components/ball_component.dart';

class KeepyUppyHudData {
  const KeepyUppyHudData({
    this.keepUps = 0,
    this.combo = 0,
    this.score = 0,
    this.perfects = 0,
    this.maxCombo = 0,
    this.sequenceFill = 0,
  });

  final int keepUps;
  final int combo;
  final int score;
  final int perfects;
  final int maxCombo;
  final double sequenceFill;
}

class KeepyUppyEndData {
  const KeepyUppyEndData({
    required this.keepUps,
    required this.score,
    required this.perfects,
    required this.maxCombo,
    required this.best,
    required this.isNewRecord,
  });

  final int keepUps;
  final int score;
  final int perfects;
  final int maxCombo;
  final int best;
  final bool isNewRecord;
}

/// Jogo infinito de embaixadinhas. Uma única ação — tocar na hora certa. A
/// bola sobe e cai por física (velocityY + gravity); ao acertar a janela de
/// timing, recebe um novo impulso pra cima. Erra o timing (ou deixa passar)
/// e a bola cai até o chão: fim de jogo.
class KeepyUppyGame extends FlameGame {
  KeepyUppyGame({required this.loadBest, required this.saveBest});

  final Future<int> Function() loadBest;
  final Future<void> Function(KeepyUppyEndData data) saveBest;

  final ValueNotifier<KeepyUppyHudData> hud = ValueNotifier<KeepyUppyHudData>(
    const KeepyUppyHudData(),
  );
  final ValueNotifier<String?> countdown = ValueNotifier<String?>(null);
  final ValueNotifier<KeepyUppyEndData?> ended =
      ValueNotifier<KeepyUppyEndData?>(null);

  final Random _rng = Random();

  late final KeepyUppyField _field;
  late final KeepyUppyPlayer _player;
  late final KeepyUppyTapTarget _target;
  late final KeepyUppyBallShadow _shadow;
  late final BallComponent _ball;

  KeepyUppyPhase _phase = KeepyUppyPhase.countdown;
  int _best = 0;

  // Estado da partida.
  int _keepUps = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _perfects = 0;
  int _score = 0;

  // Física da bola (unidades relativas ao tamanho da tela, por segundo).
  double _velocityY = 0;
  double _spinSpeed = 0;
  bool _highPose = false;

  // Countdown.
  static const _countdownSteps = ['3', '2', '1', 'VAI!'];
  int _countdownIndex = 0;
  double _countdownTimer = 0;

  double _poseResetTimer = 0;

  // --- Geometria derivada do tamanho (responsivo) ------------------------
  // Jogador de perfil à esquerda, bola descendo na coluna à frente dele
  // (direita) — assim a bola nunca fica "colada" no corpo e o contato com o
  // pé da frente fica explícito.
  double get _playerHeight => size.y * 0.62;
  double get _playerWidth => _playerHeight * KeepyUppyPlayer.aspectRatio;
  double get _playerCenterX => size.x * 0.42;
  // A bola fica logo à frente do pé do jogador — o deslocamento é uma fração
  // da LARGURA do jogador (derivada da altura), então bola e pé continuam
  // juntos em qualquer proporção de tela, sem gap.
  double get _ballColumnX => _playerCenterX + _playerWidth * 0.16;
  double get _playerFeetY => size.y * 0.80;
  double get _contactY => size.y * 0.56;
  // Amarrado à ALTURA (jogo é vertical) pra a bola ficar consistente em
  // qualquer proporção de tela — antes usava a largura e ficava gigante no
  // web e pequena no celular.
  double get _ballRadius => size.y * 0.042;
  double get _groundY => size.y * 1.04;

  double get _difficulty => (min(_keepUps, 60) / 60).clamp(0.0, 1.0);
  double get _gravity => size.y * _lerp(2.0, 4.6, _difficulty);
  double get _apexHeight =>
      size.y *
      _lerp(0.36, 0.32, _difficulty) *
      (0.97 + _rng.nextDouble() * 0.06);
  double get _band => size.y * _lerp(0.12, 0.055, _difficulty);
  double get _perfectBand => _band * _lerp(0.4, 0.26, _difficulty);
  double get _validTop => _contactY - _band * 0.5;
  double get _validBottom => _contactY + _band;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Color backgroundColor() => const Color(0xFF0B3320);

  @override
  Future<void> onLoad() async {
    _field = KeepyUppyField();
    _player = KeepyUppyPlayer();
    _target = KeepyUppyTapTarget();
    _shadow = KeepyUppyBallShadow();
    _ball = BallComponent(radius: 11)..groundShadow = false;
    await addAll([_field, _shadow, _target, _player, _ball]);
    _layout();
    _best = await loadBest();
    _resetForCountdown();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && size.x > 0 && size.y > 0) _layout();
  }

  void _layout() {
    _player
      ..size = Vector2(_playerWidth, _playerHeight)
      ..position = Vector2(_playerCenterX, _playerFeetY);
    _target
      ..position = Vector2(_ballColumnX, _playerFeetY)
      ..radius = _ballRadius * 3.0;
    _shadow
      ..position = Vector2(_ballColumnX, _playerFeetY)
      ..baseWidth = _ballRadius * 3;
    _ball
      ..size = Vector2.all(_ballRadius * 2)
      ..anchor = Anchor.center;
    if (_phase == KeepyUppyPhase.countdown) {
      _ball.position = Vector2(_ballColumnX, _contactY);
    }
  }

  void _resetForCountdown() {
    _phase = KeepyUppyPhase.countdown;
    _keepUps = 0;
    _combo = 0;
    _maxCombo = 0;
    _perfects = 0;
    _score = 0;
    _velocityY = 0;
    _spinSpeed = 0;
    _highPose = false;
    _countdownIndex = 0;
    _countdownTimer = 0;
    _player.pose = KeepyUppyPose.idle;
    _ball
      ..position = Vector2(_ballColumnX, _contactY)
      ..spin = 0;
    _shadow.heightFraction = 0;
    _target.active = false;
    countdown.value = _countdownSteps[0];
    _emitHud();
    ended.value = null;
  }

  void restart() => _resetForCountdown();

  @override
  void update(double dt) {
    super.update(dt);
    switch (_phase) {
      case KeepyUppyPhase.countdown:
        _updateCountdown(dt);
      case KeepyUppyPhase.playing:
        _updateBall(dt);
        _updateReactiveTarget();
      case KeepyUppyPhase.dying:
        _updateBall(dt, dying: true);
      case KeepyUppyPhase.over:
        break;
    }
    _updatePoseTimer(dt);
    _updateShadow();
  }

  void _updateCountdown(double dt) {
    _countdownTimer += dt;
    if (_countdownTimer < 0.7) return;
    _countdownTimer = 0;
    _countdownIndex++;
    if (_countdownIndex < _countdownSteps.length) {
      countdown.value = _countdownSteps[_countdownIndex];
      return;
    }
    // "VAI!" acabou: começa a partida com um toque automático pra cima,
    // dando ao jogador um ciclo inteiro pra reagir antes do primeiro toque.
    countdown.value = null;
    _phase = KeepyUppyPhase.playing;
    _velocityY = -sqrt(2 * _gravity * _apexHeight);
    _spinSpeed = 2.4;
  }

  void _updateBall(double dt, {bool dying = false}) {
    _velocityY += _gravity * dt;
    _ball.position.y += _velocityY * dt;
    _ball.spin += _spinSpeed * dt;

    if (dying) {
      if (_ball.position.y >= _groundY) _finish();
      return;
    }

    // Deixou a bola descer além da janela sem um toque válido: caiu.
    if (_velocityY > 0 && _ball.position.y > _validBottom) {
      _phase = KeepyUppyPhase.dying;
      _player.pose = KeepyUppyPose.idle;
      _target.active = false;
      HapticFeedback.heavyImpact();
    }
  }

  void _updateReactiveTarget() {
    _target.active =
        _velocityY > 0 &&
        _ball.position.y >= _validTop &&
        _ball.position.y <= _validBottom;
  }

  void _updateShadow() {
    _shadow.position.x = _ball.position.x;
    final fraction =
        ((_playerFeetY - _ball.position.y) / (_playerFeetY - size.y * 0.20))
            .clamp(0.0, 1.0);
    _shadow.heightFraction = fraction;
  }

  void _updatePoseTimer(double dt) {
    if (_poseResetTimer <= 0) return;
    _poseResetTimer -= dt;
    if (_poseResetTimer <= 0 && _phase == KeepyUppyPhase.playing) {
      _player.pose = KeepyUppyPose.idle;
    }
  }

  /// Toque do usuário — só conta dentro da janela válida, com a bola
  /// descendo. Cedo demais (subindo/acima) ou tarde demais (abaixo) é
  /// ignorado: o timing precisa importar.
  void onTap() {
    if (_phase != KeepyUppyPhase.playing) return;
    if (_velocityY <= 0) return;
    final y = _ball.position.y;
    if (y < _validTop || y > _validBottom) return;

    final perfect = (y - _contactY).abs() <= _perfectBand;
    _registerHit(perfect: perfect);
  }

  void _registerHit({required bool perfect}) {
    _keepUps++;
    if (perfect) {
      _perfects++;
      _combo++;
      _maxCombo = max(_maxCombo, _combo);
      _score += 2 + _combo;
      HapticFeedback.mediumImpact();
    } else {
      _combo = 0;
      _score += 1;
      HapticFeedback.selectionClick();
    }

    // Novo impulso pra cima, com a dificuldade já atualizada pelo novo
    // placar; alterna a pose (contato baixo/alto) pra dar ritmo natural.
    _velocityY = -sqrt(2 * _gravity * _apexHeight);
    _highPose = !_highPose;
    _spinSpeed = 2.2 + _difficulty * 2.4;
    _ball.position.x = _ballColumnX;
    _player.pose = _highPose
        ? KeepyUppyPose.juggleHigh
        : KeepyUppyPose.juggleLow;
    _poseResetTimer = 0.24;

    _spawnFeedback(perfect: perfect);
    _emitHud();
  }

  void _spawnFeedback({required bool perfect}) {
    final pos = Vector2(_ball.position.x + size.x * 0.12, _ball.position.y);
    add(
      KeepyUppyFeedback(
        position: pos,
        title: perfect ? 'PERFEITO' : 'BOA',
        subtitle: perfect ? '+2' : null,
        color: perfect ? const Color(0xFF3DDC84) : Colors.white,
        big: perfect,
      ),
    );
  }

  void _emitHud() {
    hud.value = KeepyUppyHudData(
      keepUps: _keepUps,
      combo: _combo,
      score: _score,
      perfects: _perfects,
      maxCombo: _maxCombo,
      sequenceFill: (min(_keepUps, 40) / 40).clamp(0.0, 1.0),
    );
  }

  Future<void> _finish() async {
    if (_phase == KeepyUppyPhase.over) return;
    _phase = KeepyUppyPhase.over;
    final isNewRecord = _keepUps > _best;
    final data = KeepyUppyEndData(
      keepUps: _keepUps,
      score: _score,
      perfects: _perfects,
      maxCombo: _maxCombo,
      best: max(_best, _keepUps),
      isNewRecord: isNewRecord,
    );
    if (isNewRecord) _best = _keepUps;
    await saveBest(data);
    ended.value = data;
  }
}
