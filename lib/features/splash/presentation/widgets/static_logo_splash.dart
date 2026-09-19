import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — continuação da
/// splash nativa, não branco puro por acaso.
const _splashBackground = Color(0xFFF6F8F7);

const _holdDuration = Duration(milliseconds: 1400);

/// Splash estática — só uma imagem sobre um fundo sólido, sem vídeo nem
/// sequência de cenas. Dois modos, escolhidos por
/// `ClubConfig.assets.splashLogo`:
///   - `null` (comportamento de sempre, ex.: Bragantino): [crestBadge]
///     sobre [_splashBackground] (a cor neutra da splash nativa).
///   - definido (ex.: Goiás, desde o rebrand Esmeraldino App):
///     [ClubAssets.splashLogo] sobre `branding.light.primary` — pensado
///     pra uma marca própria que já vem com fundo colorido embutido (tipo
///     app icon), nunca logo nova sobre fundo velho.
/// Também é o fallback de TODA a splash no iOS Web/PWA (mesmo com vídeo
/// configurado) — vídeo (autoplay bloqueado pelo Safari) e sequência de
/// cenas animadas (peso de imagem grande demais pra terminar de carregar
/// antes do timer de segurança em rede móvel) davam trabalho justamente na
/// plataforma mais restrita; uma imagem só, pequena, sem timeline, não tem
/// como falhar do mesmo jeito.
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

  String get _logoAsset =>
      sl<ClubConfig>().assets.splashLogo ?? sl<ClubConfig>().assets.crestBadge;

  Color get _backgroundColor => sl<ClubConfig>().assets.splashLogo == null
      ? _splashBackground
      : sl<ClubConfig>().branding.light.primary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      await precacheImage(AssetImage(_logoAsset), context);
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
      color: _backgroundColor,
      child: Center(
        child: Image.asset(
          _logoAsset,
          // 200 (era 140, pro brasão vetorial simples) — o mascote novo é
          // uma ilustração mais detalhada, precisa de mais espaço pra ler
          // bem. Só afeta quem tem `splashLogo` definido; Bragantino
          // continua em 140 (nunca mudou o valor, só a origem da
          // constante deixou de ser fixa).
          width: sl<ClubConfig>().assets.splashLogo == null ? 140 : 200,
          height: sl<ClubConfig>().assets.splashLogo == null ? 140 : 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
