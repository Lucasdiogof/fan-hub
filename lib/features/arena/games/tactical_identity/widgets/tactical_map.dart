import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Mapa tático 2D — topo PRAGMÁTICO, base DOGMÁTICO, esquerda POSSE, direita
/// VERTICAL, centro 0/0. Conversão de coordenada SEMPRE pela fórmula do
/// pedido (nunca posicionamento manual): `normalizedX = (x+100)/200`,
/// `normalizedY = (100-y)/200` (Y invertido de propósito — pragmático é
/// `+100` e fica no TOPO, então precisa de um `normalizedY` menor).
class TacticalMap extends StatelessWidget {
  const TacticalMap({
    required this.userX,
    required this.userY,
    required this.coaches,
    required this.onCoachTap,
    super.key,
  });

  final int userX;
  final int userY;

  /// Todos os 12 técnicos (não só o Top 3) — o usuário pode tocar em
  /// qualquer ponto do mapa.
  final List<CoachAffinity> coaches;
  final ValueChanged<CoachAffinity> onCoachTap;

  static const _coachDotSize = 12.0;
  static const _userDotSize = 22.0;
  static const _plotPadding = 14.0;

  Offset _positionFor(double x, double y, Size plotSize) {
    final normalizedX = (x + 100) / 200;
    final normalizedY = (100 - y) / 200;
    final usableWidth = plotSize.width - _plotPadding * 2;
    final usableHeight = plotSize.height - _plotPadding * 2;
    return Offset(
      _plotPadding + normalizedX * usableWidth,
      _plotPadding + normalizedY * usableHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AxisLabel(colors.textHint, label: 'PRAGMÁTICO'),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SideAxisLabel(colors.textHint, 'POSSE'),
            const SizedBox(width: 4),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    border: Border.all(color: colors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return Stack(
                          children: [
                            // Linhas de referência x=0 / y=0.
                            Positioned(
                              left: size.width / 2,
                              top: 0,
                              bottom: 0,
                              child: Container(width: 1, color: colors.border),
                            ),
                            Positioned(
                              top: size.height / 2,
                              left: 0,
                              right: 0,
                              child: Container(height: 1, color: colors.border),
                            ),
                            Center(
                              child: Text(
                                '0 / 0',
                                style: TextStyle(
                                  color: colors.textHint,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            for (final coach in coaches)
                              Builder(
                                builder: (context) {
                                  final position = _positionFor(
                                    coach.coach.x,
                                    coach.coach.y,
                                    size,
                                  );
                                  return Positioned(
                                    left: position.dx - _coachDotSize / 2,
                                    top: position.dy - _coachDotSize / 2,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => onCoachTap(coach),
                                      child: Container(
                                        width: _coachDotSize + 12,
                                        height: _coachDotSize + 12,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: _coachDotSize,
                                          height: _coachDotSize,
                                          decoration: BoxDecoration(
                                            color: colors.textHint,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: colors.surface,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Builder(
                              builder: (context) {
                                final position = _positionFor(
                                  userX.toDouble(),
                                  userY.toDouble(),
                                  size,
                                );
                                return Positioned(
                                  left: position.dx - _userDotSize / 2,
                                  top: position.dy - _userDotSize / 2,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: _userDotSize,
                                      height: _userDotSize,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.surface,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.primary.withValues(
                                              alpha: 0.45,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _SideAxisLabel(colors.textHint, 'VERTICAL'),
          ],
        ),
        const SizedBox(height: 4),
        _AxisLabel(colors.textHint, label: 'DOGMÁTICO'),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.color, {required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SideAxisLabel extends StatelessWidget {
  const _SideAxisLabel(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
