import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:video_player/video_player.dart';

const _videoEndTolerance = Duration(milliseconds: 60);

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — não é branco puro
/// de propósito, é a continuação exata da splash nativa, que não tem uma
/// variante dark configurada.
const _splashBackground = Color(0xFFF6F8F7);

/// Splash em vídeo — usada em toda plataforma que não seja iOS Web/PWA nem
/// clube sem vídeo próprio (ver `SplashVideoPage`, que decide entre esta e
/// `StaticLogoSplash` e passa o asset via `videoAsset`). Dono do ciclo de
/// vida do `VideoPlayerController` e de tudo que é específico de vídeo
/// (pausar ao ir pra segundo plano, detectar o fim); o pai só recebe os
/// callbacks já resolvidos.
class VideoSplashView extends StatefulWidget {
  const VideoSplashView({
    required this.videoAsset,
    required this.onReady,
    required this.onCompleted,
    required this.onFailure,
    super.key,
  });

  /// Path do vídeo a tocar — vem de `ClubConfig.assets.splashVideo`. Quem
  /// chama (`SplashVideoPage`) só monta este widget quando o valor não é
  /// `null`; nunca há um vídeo default embutido aqui dentro.
  final String videoAsset;

  /// O primeiro frame já foi decodificado — pai usa isso pra disparar a
  /// revelação em círculo.
  final VoidCallback onReady;

  /// O vídeo chegou ao fim naturalmente.
  final VoidCallback onCompleted;

  /// Falha ao inicializar ou tocar o vídeo (arquivo corrompido, codec não
  /// suportado etc.) — nunca deixa a splash travada esperando por isso.
  final VoidCallback onFailure;

  @override
  State<VideoSplashView> createState() => _VideoSplashViewState();
}

class _VideoSplashViewState extends State<VideoSplashView>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.videoAsset);
    try {
      await controller.initialize();
      // Mudo + sem loop ANTES de `play()` — Safari/iOS só libera autoplay
      // pra vídeo que já nasce mudo, não pra um que silencia depois.
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      _report(widget.onFailure);
      return;
    }
    if (!mounted || _reported) {
      await controller.dispose();
      return;
    }
    controller.addListener(_onVideoTick);
    setState(() => _controller = controller);
    // Um frame depois de `play()`, garantindo que a textura já tem o
    // primeiro frame decodificado antes do círculo começar a crescer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  void _onVideoTick() {
    final value = _controller?.value;
    if (_reported || value == null || !value.isInitialized) return;
    if (value.duration > Duration.zero &&
        value.position >= value.duration - _videoEndTolerance) {
      _report(widget.onCompleted);
    }
  }

  void _report(VoidCallback callback) {
    if (_reported || !mounted) return;
    _reported = true;
    _controller?.removeListener(_onVideoTick);
    callback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed && !_reported) {
      controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    return RepaintBoundary(child: _FullscreenVideo(controller: controller));
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
    // Antes tinha um teto fixo de 420 de largura — numa janela desktop/Web
    // comum (bem mais larga que alta), isso deixava o vídeo do tamanho de
    // um celular plantado no meio de uma tela enorme, a maior parte vazia.
    // `FittedBox` com `contain` cresce o vídeo até encostar numa das bordas
    // da caixa de 92% da tela (nunca cropa, sempre mantém a proporção) —
    // usa o espaço disponível de verdade, sem depender de um número mágico.
    return Center(
      child: SizedBox(
        width: screenSize.width * 0.92,
        height: screenSize.height * 0.92,
        child: FittedBox(
          fit: BoxFit.contain,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}
