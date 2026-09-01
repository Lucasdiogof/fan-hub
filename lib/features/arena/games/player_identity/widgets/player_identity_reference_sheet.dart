import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_dimension_labels.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';

/// Popover ao tocar numa referência — nome, período, afinidade e as seis
/// características dela, com o aviso de que são dados editoriais (nunca
/// avaliações oficiais). Mesmo padrão de
/// `showTacticalCoachSheet`/`AppBottomSheet`.
Future<void> showPlayerIdentityReferenceSheet(
  BuildContext context,
  PlayerIdentityAffinity affinity,
) {
  final l10n = context.l10n;
  final reference = affinity.reference;
  return AppBottomSheet.show(
    context,
    title: reference.name,
    description: 'Goiás • ${reference.period}',
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
            l10n.playerIdentityAffinityLabel(
              affinity.affinity.toStringAsFixed(1),
            ),
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final d in PlayerIdentityDimension.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.label,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${reference[d]}',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.playerReferenceDisclaimer,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textHint,
            fontSize: 11.5,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}
