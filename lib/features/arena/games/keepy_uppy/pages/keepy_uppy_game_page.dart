import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_scores.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/keepy_uppy_game.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/widgets/keepy_uppy_hud.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';

class KeepyUppyGamePage extends StatefulWidget {
  const KeepyUppyGamePage({super.key});

  @override
  State<KeepyUppyGamePage> createState() => _KeepyUppyGamePageState();
}

class _KeepyUppyGamePageState extends State<KeepyUppyGamePage>
    with WidgetsBindingObserver, RouteAware {
  static const _gameId = 'keepy_uppy';

  final ValueNotifier<int> _best = ValueNotifier<int>(0);

  late final KeepyUppyGame _game = KeepyUppyGame(
    loadBest: () => sl<ArenaScores>().bestScore(_gameId),
    saveBest: (data) async {
      final scores = sl<ArenaScores>();
      await scores.saveIfBest(_gameId, data.keepUps);
      await scores.saveIfBest('${_gameId}_score', data.score);
      await scores.saveIfBest('${_gameId}_combo', data.maxCombo);
      await scores.saveIfBest('${_gameId}_perfects', data.perfects);
    },
  );

  ModalRoute<void>? _route;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game.ended.addListener(_onEnded);
    sl<ArenaScores>().bestScore(_gameId).then((value) => _best.value = value);
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
    _game.ended.removeListener(_onEnded);
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _best.dispose();
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

  Future<void> _onEnded() async {
    final data = _game.ended.value;
    if (data == null || _resultShown || !mounted) return;
    _resultShown = true;
    if (data.best > _best.value) _best.value = data.best;

    await AppBottomSheet.show(
      context,
      icon: data.isNewRecord
          ? Icons.emoji_events_rounded
          : Icons.sports_soccer_rounded,
      title: data.isNewRecord ? 'NOVO RECORDE!' : 'Fim de jogo',
      description: data.isNewRecord
          ? 'Sua melhor marca de embaixadinhas.'
          : 'A bola caiu. Bora de novo?',
      content: _ResultStats(data: data),
      confirmLabel: 'TENTAR NOVAMENTE',
      cancelLabel: 'Sair',
      onConfirm: () {
        _resultShown = false;
        _game.restart();
      },
      onCancel: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(bestListenable: _best),
            Expanded(
              // Enquadra o jogo numa proporção vertical (de celular) e
              // centraliza — em telas largas (web/tablet) sobra margem em
              // vez de esticar a cena e agigantar a bola/jogador. No celular
              // ocupa praticamente tudo.
              child: ColoredBox(
                color: const Color(0xFF0B3320),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.5,
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) => _game.onTap(),
                              child: GameWidget<KeepyUppyGame>(game: _game),
                            ),
                          ),
                          Positioned.fill(child: KeepyUppyHud(game: _game)),
                          Positioned.fill(
                            child: _CountdownOverlay(game: _game),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.bestListenable});

  final ValueListenable<int> bestListenable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: colors.primary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Embaixadinhas',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Toque na hora certa para manter a bola no ar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text(
                  'RECORDE',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: bestListenable,
                  builder: (context, best, _) => Text(
                    '$best',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.game});

  final KeepyUppyGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<String?>(
        valueListenable: game.countdown,
        builder: (context, value, _) {
          if (value == null) return const SizedBox.shrink();
          return Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                value,
                key: ValueKey(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 92,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 16)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.data});

  final KeepyUppyEndData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          '${data.keepUps}',
          style: TextStyle(
            color: colors.primary,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Text(
          'EMBAIXADINHAS',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _Cell(label: 'PONTUAÇÃO', value: '${data.score}'),
            _Cell(label: 'PERFEITOS', value: '${data.perfects}'),
            _Cell(label: 'COMBO MÁX.', value: '${data.maxCombo}x'),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
