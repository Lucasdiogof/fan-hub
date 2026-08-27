import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/shared/local_best_score_store.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game.dart';
import 'package:goias_app/features/arena/games/penalty/widgets/penalty_hud.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class PenaltyGamePage extends StatefulWidget {
  const PenaltyGamePage({super.key});

  @override
  State<PenaltyGamePage> createState() => _PenaltyGamePageState();
}

class _PenaltyGamePageState extends State<PenaltyGamePage>
    with WidgetsBindingObserver, RouteAware {
  static const _gameId = 'penalty';

  late final PenaltyGame _game = PenaltyGame(
    loadBest: () => sl<LocalBestScoreStore>().bestScore(_gameId),
    saveBest: (score) async {
      await sl<LocalBestScoreStore>().saveIfBest(_gameId, score);
    },
  );

  ModalRoute<void>? _route;
  Offset _panStart = Offset.zero;
  Offset _panLast = Offset.zero;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game.ended.addListener(_onMatchEnded);
  }

  /// Ao terminar as 5 cobranças, fecha esta tela de jogo (o `GameWidget` é
  /// desmontado normalmente — nada de Flame fica rodando escondido) e abre
  /// a tela de resultado no lugar dela, já com o dado real da partida.
  /// `pushReplacement` em vez de `push`: assim "Jogar novamente" não fica
  /// empilhando uma página de jogo nova a cada partida.
  void _onMatchEnded() {
    final data = _game.ended.value;
    if (data == null || _navigatedToResult || !mounted) return;
    _navigatedToResult = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement('/arena/penalty/result', extra: data);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _game.ended.removeListener(_onMatchEnded);
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _game.resumeEngine();
    } else {
      _game.pauseEngine();
    }
  }

  @override
  void didPushNext() => _game.pauseEngine();

  @override
  void didPopNext() => _game.resumeEngine();

  void _onPanEnd(DragEndDetails details) {
    final delta = _panLast - _panStart;
    final velocity = details.velocity.pixelsPerSecond;
    _game.shoot(
      Offset(delta.dx + velocity.dx * 0.05, delta.dy + velocity.dy * 0.05),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.arenaBottom,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ContentWidth.interactive.maxWidth,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (details) =>
                      _panStart = _panLast = details.localPosition,
                  onPanUpdate: (details) => _panLast = details.localPosition,
                  onPanEnd: _onPanEnd,
                  child: GameWidget<PenaltyGame>(
                    game: _game,
                    overlayBuilderMap: {
                      'hud': (context, game) => PenaltyHud(game: game),
                    },
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                ),
              ),
              _SwipeHint(game: _game),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.game});

  final PenaltyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PenaltyEndData?>(
      valueListenable: game.ended,
      builder: (context, ended, _) {
        if (ended != null) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                context.l10n.penaltyDragToShoot,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
