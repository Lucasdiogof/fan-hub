import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/keepy_uppy_game.dart';

const _green = Color(0xFF3DDC84);

/// Interface por cima do campo — contador principal, combo, barra de
/// sequência e o card de estatísticas. Tudo em `IgnorePointer` pra o toque
/// atravessar direto pro jogo. Só rebuilda quando o placar muda (via
/// `game.hud`), nunca a cada frame.
class KeepyUppyHud extends StatelessWidget {
  const KeepyUppyHud({required this.game, super.key});

  final KeepyUppyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KeepyUppyHudData>(
      valueListenable: game.hud,
      builder: (context, data, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: _Counter(keepUps: data.keepUps, combo: data.combo),
                ),
              ),
              Align(
                alignment: const Alignment(-0.92, -0.25),
                child: _SequenceBar(fill: data.sequenceFill, value: data.keepUps),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _StatsCard(
                    score: data.score,
                    perfects: data.perfects,
                    maxCombo: data.maxCombo,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.keepUps, required this.combo});

  final int keepUps;
  final int combo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$keepUps',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 68,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'EMBAIXADINHAS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: combo >= 2 ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'COMBO x${combo < 2 ? 2 : combo}',
              style: const TextStyle(
                color: _green,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SequenceBar extends StatelessWidget {
  const _SequenceBar({required this.fill, required this.value});

  final double fill;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 6,
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    tween: Tween(begin: 0, end: fill.clamp(0.0, 1.0)),
                    builder: (context, v, _) => FractionallySizedBox(
                      heightFactor: v == 0 ? 0.001 : v,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: _green,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
            const Text(
              'SEQUÊNCIA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.score,
    required this.perfects,
    required this.maxCombo,
  });

  final int score;
  final int perfects;
  final int maxCombo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          _Stat(icon: Icons.emoji_events_rounded, label: 'PONTUAÇÃO', value: '$score'),
          _Divider(),
          _Stat(icon: Icons.adjust_rounded, label: 'PERFEITOS', value: '$perfects'),
          _Divider(),
          _Stat(icon: Icons.bolt_rounded, label: 'COMBO MÁX.', value: '${maxCombo}x'),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: context.colors.border);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: colors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
