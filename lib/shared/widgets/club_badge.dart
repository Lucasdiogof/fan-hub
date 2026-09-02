import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/utils/image_proxy.dart';
import 'package:goias_app/shared/utils/inline_svg_css.dart';

/// Safari/iOS no Web (inclusive PWA) tem um bug conhecido do CanvasKit onde
/// imagens de rede viram retângulo preto sólido depois de um repaint em
/// massa (ex.: `MaterialApp` inteiro reconstruindo ao trocar de tema) — a
/// textura da GPU não sobrevive ao rebuild. Só nessa combinação específica,
/// escudo de adversário sai do pipeline CanvasKit/WebGL e vira um elemento
/// `<img>` HTML de verdade (imune a esse bug, já que não passa pela GPU do
/// Flutter) via `webHtmlElementStrategy`. Em qualquer outro ambiente
/// (Android, iOS nativo, Chrome/Edge desktop, Android Web) o caminho
/// continua o de sempre — não vale o custo de um platform view ali.
bool get _isIosWeb => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Badge esportivo de um time — fonte única de verdade pra escudo de clube
/// no app inteiro (nenhuma outra tela busca/renderiza escudo por conta
/// própria). Prioridade: o clube ativo sempre usa o asset oficial local
/// (nunca rede) → `logoUrl` (escudo vindo do Worker/OneFootball, via
/// elemento HTML no Safari/iOS Web — ver `_isIosWeb` — ou pipeline normal
/// do Flutter nos demais ambientes) → `crestAsset` (vetor local de
/// fallback) → escudo desenhado como último recurso. O círculo genérico
/// com sigla nunca é a aparência "normal" — só aparece quando não há
/// nenhum escudo disponível ou o carregamento da rede falha.
///
/// **Decisão de DI (revisão M3.3, explícita, não acidental)**: usa
/// `sl<ClubConfig>()` internamente em vez de receber `ClubConfig` por
/// construtor. Considerado e rejeitado tornar isso explícito — exigiria
/// editar 19 call sites em 15 arquivos (`crowd_lineup_hero_card.dart`,
/// `compact_match_header.dart`, `live_match_hero.dart`,
/// `next_match_hero.dart`, `match_details_page.dart`,
/// `calendar_day_cell.dart`, `match_list_item.dart`, `next_match_card.dart`,
/// `standings_row.dart`, `member_next_match_card.dart`,
/// `featured_event_card.dart` e mais 4), NENHUM dos quais hoje resolve
/// `ClubConfig` de nenhuma forma — um refactor grande só por estética,
/// explicitamente fora do critério desta rodada. `sl<T>()` direto na camada
/// de apresentação já é o padrão DOMINANTE e consistente deste app (100+
/// ocorrências em `lib/features/*/presentation/`, incluindo
/// `calendar_day_cell.dart`/`next_match_hero.dart`/`crowd_lineup_page.dart`,
/// que já fazem exatamente isso com `ClubConfig` desde esta mesma etapa) —
/// a única distinção real é `ClubBadge` morar em `shared/widgets/` em vez
/// de `features/*/presentation/`, uma organização de pasta, não uma
/// fronteira arquitetural. `ClubConfig` é registrado eager (1ª linha de
/// `setupDependencies()`) — sempre disponível em runtime real, nunca
/// opcional. **KEEP.** Custo real pago é só em teste (widget tests que
/// renderizam `ClubBadge` precisam de `sl.registerSingleton<ClubConfig>()`
/// no `setUp` — 4 arquivos já ajustados, ver relatório da M3.3).
class ClubBadge extends StatelessWidget {
  const ClubBadge({
    required this.team,
    this.size = 44,
    this.onDark = false,
    super.key,
  });

  final Team team;
  final double size;

  /// Sobre fundo escuro (Hero, banners), o escudo oficial aparece na cor
  /// original (branco); sobre fundo claro, é tingido na cor do time pra ter
  /// contraste. Só se aplica ao vetor local (`crestAsset`) — logos de rede
  /// já vêm coloridos e são exibidos como estão.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // O clube ativo sempre usa o brasão oficial embutido no app, nunca o
    // que a fonte de dado ao vivo devolve — evita depender da rede pra
    // mostrar o escudo do próprio clube, e garante que é sempre a arte
    // oficial. Nunca muda com o tema: é um `Image.asset` puro, sem filtro
    // de cor nenhum.
    final clubConfig = sl<ClubConfig>();
    if (team.matchesClub(clubConfig)) {
      _debugLog(source: 'asset:active-club');
      return Image.asset(
        clubConfig.assets.crestBadge,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    final rawUrl = team.logoUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      _debugLog(source: 'fallback:no-logo-url');
      return _fallback(context);
    }
    // Alguns nomes de time viram acento cru na URL (ex.: ".../avaí.svg"),
    // que o servidor rejeita sem o percent-encoding correto (404). Só
    // codifica quando há byte não-ASCII de verdade — Uri.encodeFull não é
    // idempotente pra URLs que já vêm com %XX válido (ex.: "%20" viraria
    // "%2520"), então não tocamos em URLs já limpas.
    final hasRawNonAscii = rawUrl.codeUnits.any((c) => c > 127);
    final encodedUrl = hasRawNonAscii ? Uri.encodeFull(rawUrl) : rawUrl;
    // Estável por design: só depende de `team.logoUrl` (dado), nunca de
    // `Theme.of(context)`/tema — trocar tema não pode recriar essa URL nem
    // invalidar o `ImageProvider` que já está decodificado.
    final logoUrl = proxiedImageUrl(encodedUrl);

    if (_isIosWeb) {
      _debugLog(source: 'network:html-element', url: rawUrl, proxied: logoUrl);
      return SizedBox(
        width: size,
        height: size,
        child: _iosWebBadge(context, logoUrl),
      );
    }

    _debugLog(
      source: _isSvg(logoUrl) ? 'network:svg' : 'network:raster',
      url: rawUrl,
      proxied: logoUrl,
    );
    return SizedBox(
      width: size,
      height: size,
      child: _isSvg(logoUrl)
          ? _svgBadge(context, logoUrl)
          : _rasterBadge(context, logoUrl),
    );
  }

  void _debugLog({required String source, String? url, String? proxied}) {
    if (!kDebugMode) return;
    debugPrint(
      '[ClubBadge] team="${team.name}" id=${team.id} '
      'matchesActiveClub=${team.matchesClub(sl<ClubConfig>())} '
      'source=$source isWeb=$kIsWeb platform=$defaultTargetPlatform '
      'url=$url proxied=$proxied',
    );
  }

  /// Escudos da campeonato-brasileiro-api vêm como SVG; do TheSportsDB, como
  /// PNG. `Image.network` não decodifica SVG — sem essa checagem, todo
  /// escudo em SVG cai silenciosamente no fallback de sigla.
  bool _isSvg(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return path.toLowerCase().endsWith('.svg');
  }

  Widget _svgBadge(BuildContext context, String url) {
    return _NetworkSvgBadge(url: url, size: size, fallbackBuilder: _fallback);
  }

  Widget _rasterBadge(BuildContext context, String url) {
    // `CachedNetworkImage` guarda o escudo em disco, então depois da primeira
    // vez ele aparece na hora em qualquer reabertura do app — sem o "flash"
    // do círculo vazio enquanto rebuscava da rede. O `fadeIn` curto suaviza
    // a primeira aparição (quando ainda não está em cache).
    //
    // `memCacheWidth`/`memCacheHeight`: os ícones da OneFootball vêm bem
    // maiores que o badge exibido (ex.: escudo de bolso a 22px). Sem isso,
    // toda vez decodifica o PNG no tamanho original antes de encolher —
    // caro o bastante pra ficar visível quando o calendário mostra várias
    // dezenas de escudos diferentes de uma vez no grid do mês.
    final pixelSize = (size * MediaQuery.of(context).devicePixelRatio).round();
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      memCacheWidth: pixelSize,
      memCacheHeight: pixelSize,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => _LoadingBadge(size: size),
      errorWidget: (context, _, _) => _fallback(context),
    );
  }

  /// Só pro Safari/iOS Web (ver `_isIosWeb`) — pede pro Flutter renderizar
  /// via elemento `<img>` HTML de verdade em vez do pipeline CanvasKit/WebGL
  /// normal. `CachedNetworkImage` não aceita essa estratégia (é exclusiva do
  /// `NetworkImage`/`Image.network` do próprio framework), então esse caminho
  /// não passa pelo cache em disco — sem problema aqui, o navegador já
  /// cacheia o `<img>` sozinho respeitando o `cache-control` de 7 dias que o
  /// Worker já manda (ver `src/media/imageProxy.ts`).
  Widget _iosWebBadge(BuildContext context, String url) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _LoadingBadge(size: size),
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final asset = team.crestAsset;
    if (asset != null) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          asset,
          colorFilter: onDark
              ? null
              : ColorFilter.mode(team.color, BlendMode.srcIn),
        ),
      );
    }
    return _ShieldBadge(team: team, size: size, onDark: onDark);
  }
}

/// `SvgPicture.network` não resolve classe CSS via `<style>` (ver
/// `inlineSvgCssClasses`) — então busca o texto do SVG a mão, corrige e
/// renderiza com `SvgPicture.string`. Cacheado em memória por URL pra não
/// rebaixar/reprocessar o mesmo escudo a cada rebuild/scroll.
class _NetworkSvgBadge extends StatefulWidget {
  const _NetworkSvgBadge({
    required this.url,
    required this.size,
    required this.fallbackBuilder,
  });

  final String url;
  final double size;
  final WidgetBuilder fallbackBuilder;

  @override
  State<_NetworkSvgBadge> createState() => _NetworkSvgBadgeState();
}

class _NetworkSvgBadgeState extends State<_NetworkSvgBadge> {
  static final _cache = <String, String>{};
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.url);
  }

  @override
  void didUpdateWidget(covariant _NetworkSvgBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _load(widget.url);
    }
  }

  static Future<String> _load(String url) async {
    final cached = _cache[url];
    if (cached != null) return cached;

    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final raw = response.data;
    if (raw == null || raw.isEmpty) {
      throw StateError('SVG vazio: $url');
    }
    final normalized = inlineSvgCssClasses(raw);
    _cache[url] = normalized;
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _LoadingBadge(size: widget.size);
        }
        final svg = snapshot.data;
        if (snapshot.hasError || svg == null) {
          return widget.fallbackBuilder(context);
        }
        return SvgPicture.string(
          svg,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              widget.fallbackBuilder(context),
        );
      },
    );
  }
}

class _LoadingBadge extends StatelessWidget {
  const _LoadingBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.06),
      ),
    );
  }
}

class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({
    required this.team,
    required this.size,
    required this.onDark,
  });

  final Team team;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldPainter(
          color: team.color,
          ringColor: Colors.white.withValues(alpha: onDark ? 0.5 : 0.85),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: size * 0.07),
          child: Center(
            child: Text(
              team.shortName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.3,
                letterSpacing: -0.2,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({required this.color, required this.ringColor});

  final Color color;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shieldPath(size);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, Color.lerp(color, Colors.black, 0.35)!],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fillPaint);

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045;
    canvas.drawPath(path, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.ringColor != ringColor;
}

Path _shieldPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * 0.5, 0)
    ..cubicTo(w * 0.5, 0, w * 0.98, h * 0.08, w * 0.98, h * 0.08)
    ..lineTo(w * 0.98, h * 0.52)
    ..cubicTo(w * 0.98, h * 0.78, w * 0.72, h * 0.94, w * 0.5, h)
    ..cubicTo(w * 0.28, h * 0.94, w * 0.02, h * 0.78, w * 0.02, h * 0.52)
    ..lineTo(w * 0.02, h * 0.08)
    ..cubicTo(w * 0.02, h * 0.08, w * 0.5, 0, w * 0.5, 0)
    ..close();
}
