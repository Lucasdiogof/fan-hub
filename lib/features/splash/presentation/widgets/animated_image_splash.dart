import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_assets.dart';

const _totalDuration = Duration(milliseconds: 5300);

// Linha do tempo normalizada (0..1 do total) — as 3 cenas com crossfade
// real: a cena seguinte já começa a subir enquanto a anterior desce, no
// mesmo intervalo, em vez de uma sumir pra depois a outra aparecer.
const _scene1FadeInEnd = 0.06;
const _scene1HoldEnd = 0.28;
const _crossfade12End = 0.34;
const _scene2HoldEnd = 0.60;
const _crossfade23End = 0.66;
// Cena 3 fica visível até o fim (1.0) — de propósito, pro texto/brasão
// terem tempo de leitura e a splash nunca "cortar" no final.

/// Splash animada com as 3 cenas estáticas (`AppAssets.splashScene1/2/3`) —
/// substitui o vídeo só em iOS Web/PWA (ver `SplashVideoPage`), onde o
/// Safari bloqueia autoplay de vídeo silenciosamente e o `goias_splash.mp4`
/// nunca chega a tocar de verdade. Um único `AnimationController` conduz
/// opacidade (crossfade) + escala (zoom lento tipo Ken Burns) das 3
/// imagens — nunca um `Timer` trocando imagem de repente.
class AnimatedImageSplash extends StatefulWidget {
  const AnimatedImageSplash({
    required this.onReady,
    required this.onCompleted,
    super.key,
  });

  /// As 3 imagens já foram pré-carregadas e a timeline está prestes a
  /// começar — o pai usa isso pra disparar a revelação em círculo.
  final VoidCallback onReady;

  /// A sequência das 3 cenas chegou ao fim.
  final VoidCallback onCompleted;

  @override
  State<AnimatedImageSplash> createState() => _AnimatedImageSplashState();
}

class _AnimatedImageSplashState extends State<AnimatedImageSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _precached = false;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _report(widget.onCompleted);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAndStart());
  }

  Future<void> _precacheAndStart() async {
    try {
      await Future.wait([
        precacheImage(const AssetImage(AppAssets.splashScene1), context),
        precacheImage(const AssetImage(AppAssets.splashScene2), context),
        precacheImage(const AssetImage(AppAssets.splashScene3), context),
      ]);
    } catch (_) {
      // Asset local, praticamente nunca falha — mas se falhar, segue com o
      // que já carregou em vez de travar a splash esperando pra sempre.
    }
    if (!mounted) return;
    setState(() => _precached = true);
    widget.onReady();
    unawaited(_controller.forward());
  }

  void _report(VoidCallback callback) {
    if (_reported || !mounted) return;
    _reported = true;
    callback();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_precached) return const SizedBox.expand();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              _Scene(
                asset: AppAssets.splashScene1,
                opacity: _fadeOpacity(
                  t,
                  0,
                  _scene1FadeInEnd,
                  _scene1HoldEnd,
                  _crossfade12End,
                ),
                scale: _zoomScale(t, 0, _crossfade12End),
              ),
              _Scene(
                asset: AppAssets.splashScene2,
                opacity: _fadeOpacity(
                  t,
                  _scene1HoldEnd,
                  _crossfade12End,
                  _scene2HoldEnd,
                  _crossfade23End,
                ),
                scale: _zoomScale(t, _scene1HoldEnd, _crossfade23End),
              ),
              _Scene(
                asset: AppAssets.splashScene3,
                opacity: _fadeOpacity(t, _scene2HoldEnd, _crossfade23End, 1, 1),
                scale: _zoomScale(t, _scene2HoldEnd, 1),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Opacidade de uma cena ao longo do tempo normalizado [t]: 0 antes de
/// [holdStart], sobe até [fadeInEnd], fica em 1 até [fadeOutStart], desce
/// até [fadeOutEnd]. Duas cenas vizinhas compartilham o mesmo intervalo de
/// fade-in/fade-out — é isso que produz o crossfade real, não duas
/// transições independentes.
double _fadeOpacity(
  double t,
  double holdStart,
  double fadeInEnd,
  double fadeOutStart,
  double fadeOutEnd,
) {
  if (t <= holdStart) return 0;
  if (t < fadeInEnd) return (t - holdStart) / (fadeInEnd - holdStart);
  if (t <= fadeOutStart) return 1;
  if (t < fadeOutEnd) {
    return 1 - (t - fadeOutStart) / (fadeOutEnd - fadeOutStart);
  }
  return 0;
}

/// Zoom lento e contínuo (efeito Ken Burns) enquanto a cena está relevante
/// — de 1.0 a 1.06 ao longo da janela entre [start] e [end]. Fora da
/// janela a cena está com opacidade 0 mesmo, então o valor exato não
/// importa visualmente.
double _zoomScale(double t, double start, double end) {
  final clamped = t.clamp(start, end);
  final progress = end > start ? (clamped - start) / (end - start) : 0.0;
  return 1.0 + 0.06 * progress;
}

class _Scene extends StatelessWidget {
  const _Scene({
    required this.asset,
    required this.opacity,
    required this.scale,
  });

  final String asset;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
