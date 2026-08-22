import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_models.dart';

const _goalDot = Color(0xFF3DDC84);
const _missDot = Color(0xFFE0625A);

class PenaltyHud extends StatelessWidget {
  const PenaltyHud({required this.game, super.key});

  final PenaltyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PenaltyHudData>(
      valueListenable: game.hud,
      builder: (context, data, _) {
        return SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 5; i++)
                              _Dot(result: i < data.attempts.length ? data.attempts[i] : null),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${data.goals} ${data.goals == 1 ? 'GOL' : 'GOLS'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.lastResult != null) _ResultFlash(result: data.lastResult!),
            ],
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.result});

  final PenaltyResult? result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final Color color;
    if (r == null) {
      color = Colors.white.withValues(alpha: 0.25);
    } else if (r.isGoal) {
      color = _goalDot;
    } else {
      color = _missDot;
    }
    return Container(
      width: 13,
      height: 13,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: r == null ? Colors.transparent : color,
        border: Border.all(color: r == null ? color : Colors.transparent, width: 1.5),
      ),
    );
  }
}

class _ResultFlash extends StatelessWidget {
  const _ResultFlash({required this.result});

  final PenaltyResult result;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          result.label,
          style: TextStyle(
            color: result.isGoal ? _goalDot : Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
