import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — continuação da
/// splash nativa, não branco puro por acaso.
const _splashBackground = Color(0xFFF6F8F7);

const _holdDuration = Duration(milliseconds: 1400);

/// Splash estática — só uma imagem sobre [_splashBackground] (sempre a cor
/// neutra da splash nativa, pedido explícito 2026-09-22 — nunca
/// `branding.light.primary`, mesmo quando `ClubConfig.assets.splashLogo`
/// está definido), sem vídeo nem sequência de cenas. A imagem em si ainda
/// varia por `ClubConfig.assets.splashLogo`: `null` (ex.: Bragantino) usa
/// [crestBadge]; definido (ex.: Goiás, mascote do rebrand Esmeraldino App)
/// usa a arte própria — só a imagem muda, o fundo é sempre o mesmo.
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

  /// O brasão já foi pré-carregado — hoje sem uso real pelo pai
  /// (`SplashVideoPage` mostra o conteúdo desde o primeiro frame, sem
  /// revelação nenhuma pra disparar), mantido pra não mudar a assinatura
  /// à toa e porque `VideoSplashView` ainda pode querer sinalizar isso no
  /// futuro.
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

  // Sempre a cor neutra da splash nativa — nunca `branding.light.primary`,
  // mesmo com `splashLogo` definido (pedido explícito 2026-09-22: fundo
  // branco também pro Goiás, que tem mascote própria).
  Color get _backgroundColor => _splashBackground;

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
    final hasSplashLogo = sl<ClubConfig>().assets.splashLogo != null;
    // 200 (era 140, pro brasão vetorial simples) — o mascote novo é uma
    // ilustração mais detalhada, precisa de mais espaço pra ler bem. Só
    // afeta quem tem `splashLogo` definido; Bragantino continua em 140
    // (nunca mudou o valor, só a origem da constante deixou de ser fixa).
    final imageSize = hasSplashLogo ? 200.0 : 140.0;
    final image = Image.asset(
      _logoAsset,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
    );

    return ColoredBox(
      color: _backgroundColor,
      child: Center(
        // `splashLogo` (mascote) vem com fundo quadrado gravado na própria
        // arte — pedido explícito 2026-09-22: mostrar sempre redonda, nunca
        // o quadrado cru. `crestBadge` (fallback sem `splashLogo`, ex.:
        // Bragantino) já é um traço vetorial sem fundo sólido — não precisa
        // desse recorte.
        child: hasSplashLogo
            ? ClipOval(
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: image,
                ),
              )
            : image,
      ),
    );
  }
}
