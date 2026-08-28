import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_assets.dart';

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — continuação da
/// splash nativa, não branco puro por acaso.
const _splashBackground = Color(0xFFF6F8F7);

const _holdDuration = Duration(milliseconds: 1400);

/// Splash simples pro iOS Web/PWA — só o brasão oficial sobre a cor de
/// fundo da splash nativa, sem vídeo nem sequência de imagens. Existe
/// porque tanto o vídeo (autoplay bloqueado pelo Safari) quanto a
/// sequência de 3 cenas animadas (peso de imagem grande demais pra
/// terminar de carregar antes do timer de segurança em rede móvel) davam
/// trabalho justamente na plataforma mais restrita — uma imagem só,
/// pequena, sem timeline, não tem como falhar do mesmo jeito.
class StaticLogoSplash extends StatefulWidget {
  const StaticLogoSplash({
    required this.onReady,
    required this.onCompleted,
    super.key,
  });

  /// O brasão já foi pré-carregado — pai usa isso pra disparar a
  /// revelação em círculo.
  final VoidCallback onReady;

  /// Tempo de exibição encerrado.
  final VoidCallback onCompleted;

  @override
  State<StaticLogoSplash> createState() => _StaticLogoSplashState();
}

class _StaticLogoSplashState extends State<StaticLogoSplash> {
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      await precacheImage(const AssetImage(AppAssets.goiasCrestBadge), context);
    } catch (_) {
      // Asset local, praticamente nunca falha — mas se falhar, mostra o
      // que der (o `Image.asset` no build já tem seu próprio tratamento de
      // erro implícito do framework) em vez de travar a splash esperando.
    }
    if (!mounted) return;
    widget.onReady();
    _holdTimer = Timer(_holdDuration, () {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _splashBackground,
      child: Center(
        child: Image.asset(
          AppAssets.goiasCrestBadge,
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
