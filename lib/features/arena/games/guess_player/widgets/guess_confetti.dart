import 'dart:math';

import 'package:flutter/material.dart';

/// Acabamento bem discreto pro acerto — algumas partículas em verde/dourado
/// do clube saindo do centro, sem exagero de confete/neon.
class GuessConfetti extends StatefulWidget {
  const GuessConfetti({super.key});

  @override
  State<GuessConfetti> createState() => _GuessConfettiState();
}

class _GuessConfettiState extends State<GuessConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFF29A85C),
    Color(0xFFC79A3D),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    final random = Random();
    _particles = List.generate(18, (i) {
      final angle = (i / 18) * 2 * pi + random.nextDouble() * 0.3;
      return _Particle(
        angle: angle,
        distance: 60 + random.nextDouble() * 60,
        size: 4 + random.nextDouble() * 4,
        color: _colors[random.nextInt(_colors.length)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final particle in particles) {
      final offset =
          Offset(cos(particle.angle), sin(particle.angle)) *
          particle.distance *
          eased;
      final paint = Paint()..color = particle.color.withValues(alpha: fade);
      canvas.drawCircle(
        center + offset,
        particle.size * (1 - progress * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
