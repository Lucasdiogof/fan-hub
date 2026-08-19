import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/utils/inline_svg_css.dart';

/// Badge esportivo de um time. Prioridade de fonte: `logoUrl` (escudo oficial
/// vindo da API-Football, com loading/erro) → `crestAsset` (vetor local, hoje
/// só o Goiás) → escudo desenhado como último recurso. O círculo genérico com
/// sigla nunca é a aparência "normal" — só aparece quando não há nenhum
/// escudo disponível ou o carregamento da rede falha.
class ClubBadge extends StatelessWidget {
  const ClubBadge({required this.team, this.size = 44, this.onDark = false, super.key});

  final Team team;
  final double size;

  /// Sobre fundo escuro (Hero, banners), o escudo oficial aparece na cor
  /// original (branco); sobre fundo claro, é tingido na cor do time pra ter
  /// contraste. Só se aplica ao vetor local (`crestAsset`) — logos de rede
  /// já vêm coloridos e são exibidos como estão.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final rawUrl = team.logoUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      return _fallback(context);
    }
    // Alguns nomes de time viram acento cru na URL (ex.: ".../avaí.svg"),
    // que o servidor rejeita sem o percent-encoding correto (404). Só
    // codifica quando há byte não-ASCII de verdade — Uri.encodeFull não é
    // idempotente pra URLs que já vêm com %XX válido (ex.: "%20" viraria
    // "%2520"), então não tocamos em URLs já limpas.
    final hasRawNonAscii = rawUrl.codeUnits.any((c) => c > 127);
    final logoUrl = hasRawNonAscii ? Uri.encodeFull(rawUrl) : rawUrl;
    return SizedBox(
      width: size,
      height: size,
      child: _isSvg(logoUrl) ? _svgBadge(context, logoUrl) : _rasterBadge(context, logoUrl),
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
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _LoadingBadge(size: size);
      },
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
          colorFilter: onDark ? null : ColorFilter.mode(team.color, BlendMode.srcIn),
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
  const _NetworkSvgBadge({required this.url, required this.size, required this.fallbackBuilder});

  final String url;
  final double size;
  final WidgetBuilder fallbackBuilder;

  @override
  State<_NetworkSvgBadge> createState() => _NetworkSvgBadgeState();
}

class _NetworkSvgBadgeState extends State<_NetworkSvgBadge> {
  static final _cache = <String, String>{};
  static final _dio = Dio(
    BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)),
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

    final response = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain));
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
          errorBuilder: (context, error, stackTrace) => widget.fallbackBuilder(context),
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.06)),
    );
  }
}

class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge({required this.team, required this.size, required this.onDark});

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
