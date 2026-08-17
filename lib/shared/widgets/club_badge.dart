import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

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
    final logoUrl = team.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _LoadingBadge(size: size);
          },
          errorBuilder: (context, error, stackTrace) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
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
