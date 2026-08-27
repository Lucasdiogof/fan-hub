import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/shared/utils/currency.dart';

/// Mostrado no topo do fluxo de associação — o usuário nunca perde de vista
/// o que está contratando enquanto preenche os dados.
class SelectedPlanBanner extends StatelessWidget {
  const SelectedPlanBanner({
    required this.plan,
    required this.price,
    this.onChangePlan,
    super.key,
  });

  final MembershipPlan plan;
  final MembershipPlanPrice price;
  final VoidCallback? onChangePlan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      plan.name,
      if (plan.stadiumSector != null) plan.stadiumSector!,
      if (price.label.isNotEmpty) price.label,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.membershipChosenPlan,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${formatBrl(price.monthlyPrice)}${context.l10n.membershipPerMonth}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (onChangePlan != null)
            TextButton(
              onPressed: onChangePlan,
              style: TextButton.styleFrom(foregroundColor: colors.primary),
              child: Text(
                context.l10n.membershipChangePlan,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
