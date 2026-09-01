import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';

/// Popover ao tocar num ponto do mapa tático — nome, período, afinidade e
/// os dois eixos em rótulo amigável (nunca as coordenadas brutas, ver
/// spec: "não precisa mostrar as coordenadas cruas se prejudicar a
/// compreensão").
Future<void> showTacticalCoachSheet(
  BuildContext context,
  CoachAffinity affinity,
) {
  final l10n = context.l10n;
  final coach = affinity.coach;
  return AppBottomSheet.show(
    context,
    title: coach.coach,
    description: 'Goiás • ${coach.period}',
    confirmLabel: l10n.commonClose,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.tacticalIdentityAffinityLabel(affinity.affinity),
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _StatColumn(
                value: _axisStat(coach.x, negative: 'POSSE', positive: 'VERTICAL'),
              ),
            ),
            Container(width: 1, height: 32, color: context.colors.border),
            Expanded(
              child: _StatColumn(
                value: _axisStat(
                  coach.y,
                  negative: 'DOGMÁTICO',
                  positive: 'PRAGMÁTICO',
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// "65 VERTICAL" / "40 POSSE" — a intensidade (0–100) do lado do eixo pra
/// onde a coordenada pende, nunca a coordenada crua (-100..100).
String _axisStat(double value, {required String negative, required String positive}) {
  final intensity = value.abs().round();
  return '$intensity ${value >= 0 ? positive : negative}';
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
