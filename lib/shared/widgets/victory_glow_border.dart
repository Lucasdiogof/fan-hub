import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Borda luminosa sutil e animada — destaque de "o clube está vencendo /
/// venceu" no card da Home. Quem decide QUANDO ativar é o chamador
/// ([active]); a cor vem do design system do clube/tema ([color], hoje
/// `AppColors.cta`), nunca fixa aqui.
///
/// Custo: UM `AnimationController` (só roda com [active] e sem "reduzir
/// movimento"), repintando só a borda dentro de um `RepaintBoundary` — a
/// Home não reconstrói a cada frame. O `Ticker` já pausa sozinho fora de
/// tela via `TickerMode`. Com `disableAnimations` o anel fica estático.
class VictoryGlowBorder extends StatefulWidget {
  const VictoryGlowBorder({
    required this.active,
    required this.color,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final bool active;
  final Color color;
  final double borderRadius;
  final Widget child;

  @override
  State<VictoryGlowBorder> createState() => _VictoryGlowBorderState();
}

class _VictoryGlowBorderState extends State<VictoryGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(VictoryGlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldRun = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('victory-glow'),
                painter: _GlowPainter(
                  progress: _controller,
                  color: widget.color,
                  radius: widget.borderRadius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.progress,
    required this.color,
    required this.radius,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final double radius;

  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(_stroke / 2),
      Radius.circular(radius),
    );
    // Anel base fraco + trecho brilhante que gira devagar; a ponta do
    // gradiente volta ao tom base, então não há emenda visível.
    final base = color.withValues(alpha: 0.35);
    final shader = SweepGradient(
      colors: [base, color, Color.lerp(color, Colors.white, 0.6)!, color, base],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      transform: GradientRotation(progress.value * 2 * math.pi),
    ).createShader(rect);

    canvas
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke * 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..shader = shader
          ..color = Colors.white.withValues(alpha: 0.55),
      )
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..shader = shader,
      );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color || old.radius != radius;
}
