import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';

/// Pill de resultado — nunca vermelho (regra do design system inteiro):
/// vitória usa `success`, derrota usa `gold`/`error` (o mesmo tom, só o
/// âmbar já usado pra erro em toda a UI), empate fica neutro.
class PassportOutcomePill extends StatelessWidget {
  const PassportOutcomePill({required this.outcome, super.key});

  final PassportOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (label, color) = switch (outcome) {
      PassportOutcome.win => (l10n.passportOutcomeWin, colors.success),
      PassportOutcome.loss => (l10n.passportOutcomeLoss, colors.gold),
      PassportOutcome.draw => (l10n.passportOutcomeDraw, colors.textHint),
      null => (null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
