import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/splash/presentation/widgets/circle_reveal_clipper.dart';
import 'package:goias_app/features/splash/presentation/widgets/reveal_glow_painter.dart';
import 'package:video_player/video_player.dart';

const _videoAsset = 'lib/assets/videos/goias_splash.mp4';

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — não é branco puro
/// de propósito, é a continuação exata da splash nativa, que não tem uma
/// variante dark configurada.
const _splashBackground = Color(0xFFF6F8F7);

const _startRadius = 14.0;
const _revealDuration = Duration(milliseconds: 550);
const _videoEndTolerance = Duration(milliseconds: 60);

/// O vídeo dura ~5.3s — isto é só a rede de segurança. Cobre autoplay
/// bloqueado (Safari/iOS), vídeo que inicializa mas nunca avança, erro de
/// rede/decodificação e qualquer outro jeito do vídeo não terminar sozinho.
/// Começa a contar no `initState()`, antes de qualquer tentativa de tocar o
/// vídeo — se `initialize()`/`play()` travar, essa é a única coisa que
/// garante que o usuário nunca fica preso na splash.
const _fallbackTimeout = Duration(seconds: 7);

class SplashVideoPage extends StatefulWidget {
  const SplashVideoPage({super.key});

  @override
  State<SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;
  late final Future<void> _homePreload;
  bool _finished = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _revealController = AnimationController(
      vsync: this,
      duration: _revealDuration,
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _homePreload = _preloadDestination();
    // Antes de tentar tocar o vídeo, de propósito — se `_initVideo()` nunca
    // resolver (autoplay bloqueado, `initialize()` pendurado), a splash
    // ainda sai sozinha.
    _fallbackTimer = Timer(_fallbackTimeout, _finishSplash);
    _initVideo();
  }

  /// Se o usuário vai cair na Home (autenticado), pré-carrega o `HomeCubit`
  /// (singleton — ver `injection_container.dart`) por trás do próprio
  /// vídeo, em paralelo com ele tocando. Quando o vídeo termina, a Home já
  /// está pronta e a transição não passa por um segundo loading do outro
  /// lado. Indo pro Login não tem nada assíncrono pra esperar.
  Future<void> _preloadDestination() async {
    final authState = sl<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final homeCubit = sl<HomeCubit>();
    if (homeCubit.state.loading) {
      await homeCubit.stream.firstWhere((state) => !state.loading);
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    try {
      await controller.initialize();
      // Mudo + sem loop ANTES de `play()` — Safari/iOS só libera autoplay
      // pra vídeo que já nasce mudo, não pra um que silencia depois.
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.play();
    } catch (_) {
      // Falha ao carregar/tocar o vídeo (arquivo corrompido, codec não
      // suportado, autoplay recusado com erro etc.): não trava o app
      // esperando um vídeo que não vai tocar.
      await controller.dispose();
      _finishSplash();
      return;
    }
    if (!mounted || _finished) {
      await controller.dispose();
      return;
    }
    controller.addListener(_onVideoTick);
    setState(() => _controller = controller);
    // Um frame depois de `play()`, garantindo que a textura já tem o
    // primeiro frame decodificado antes do círculo começar a crescer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealController.forward();
    });
  }

  void _onVideoTick() {
    final value = _controller?.value;
    if (_finished || value == null || !value.isInitialized) return;
    if (value.duration > Duration.zero &&
        value.position >= value.duration - _videoEndTolerance) {
      _finishSplash();
    }
  }

  /// Ponto único de conclusão da splash — idempotente por causa do guard
  /// `_finished`, então não importa se quem chamou foi o fim normal do
  /// vídeo, um erro de inicialização/reprodução ou o timer de segurança
  /// disparando perto de um desses: só a primeira chamada vale, e o usuário
  /// nunca fica preso esperando o vídeo.
  void _finishSplash() {
    if (_finished || !mounted) return;
    _finished = true;
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    // Sem fade interno aqui: o vídeo fica congelado no último frame (ou na
    // cor de fundo, se nem chegou a inicializar) e a transição de saída
    // (fade de verdade) é a da própria rota '/splash' no router — evita
    // mostrar a cor de fundo "pelada" entre o vídeo e a Home/Login.
    unawaited(_completeGateAfterPreload());
  }

  /// Só libera o gate (e portanto a navegação) depois que o pré-carregamento
  /// da Home também tiver terminado — na prática quase sempre já terminou
  /// nesse ponto (rodou em paralelo com os ~3s do vídeo), então isso raras
  /// vezes segura a splash por mais tempo do que o vídeo já levaria sozinho.
  Future<void> _completeGateAfterPreload() async {
    await _homePreload;
    sl<SplashGate>().complete();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed && !_finished) {
      controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final size = MediaQuery.sizeOf(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: _splashBackground,
      body: controller == null || !controller.value.isInitialized
          ? const SizedBox.expand()
          : AnimatedBuilder(
              animation: _revealAnimation,
              child: RepaintBoundary(
                child: _FullscreenVideo(controller: controller),
              ),
              builder: (context, child) {
                if (reducedMotion) {
                  return Opacity(opacity: _revealAnimation.value, child: child);
                }

                final t = _revealAnimation.value;
                if (t >= 1) return child!;

                final center = Offset(size.width / 2, size.height / 2);
                final maxRadius = sqrt(
                  pow(size.width / 2, 2) + pow(size.height / 2, 2),
                );
                final radius = Tween<double>(
                  begin: _startRadius,
                  end: maxRadius,
                ).transform(t);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipPath(
                      clipper: CircleRevealClipper(
                        center: center,
                        radius: radius,
                      ),
                      child: child,
                    ),
                    CustomPaint(
                      painter: RevealGlowPainter(
                        center: center,
                        radius: radius,
                        opacity: 1 - t,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// A versão atual do vídeo já foi reeditada com uma margem de segurança
/// generosa ao redor do texto/brasão (vinheta escura nas bordas) — cover
/// puro preenche a tela de ponta a ponta sem tarja, e a margem do próprio
/// vídeo evita cortar o conteúdo importante nos aspectos de tela comuns.
///
/// Isso vale pra proporções de celular. Numa janela larga (tablet/web),
/// `cover` estica um vídeo em pé até a largura da tela e cropa boa parte da
/// altura pra compensar — o brasão/texto saem enormes e cortados. Ali em vez
/// de tela cheia o vídeo aparece centralizado, do tamanho de um celular, sem
/// cortar nada (ver [_CenteredVideo]).
class _FullscreenVideo extends StatelessWidget {
  const _FullscreenVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    if (context.isAtLeastMedium) {
      return ColoredBox(
        color: _splashBackground,
        child: _CenteredVideo(controller: controller),
      );
    }

    final videoSize = controller.value.size;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoSize.width,
            height: videoSize.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

class _CenteredVideo extends StatelessWidget {
  const _CenteredVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    final screenSize = MediaQuery.sizeOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenSize.height * 0.88,
        ),
        child: AspectRatio(
          aspectRatio: videoSize.width / videoSize.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
