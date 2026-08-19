import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/shared/utils/currency.dart';

class CurrentPlanCard extends StatelessWidget {
  const CurrentPlanCard({required this.plan, required this.price, required this.onSeeAllBenefits, super.key});

  final MembershipPlan plan;
  final MembershipPlanPrice price;
  final VoidCallback onSeeAllBenefits;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEU PLANO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textHint, letterSpacing: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(plan.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.textPrimary)),
          if (plan.stadiumSector != null) ...[
            const SizedBox(height: 2),
            Text(
              'Setor ${plan.stadiumSector}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('${formatBrl(price.monthlyPrice)}/mês', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.primary)),
          const SizedBox(height: AppSpacing.lg),
          for (final benefit in plan.benefits.take(3)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 15, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(benefit, style: TextStyle(fontSize: 12.5, color: colors.textPrimary, height: 1.3))),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onSeeAllBenefits,
            style: TextButton.styleFrom(foregroundColor: colors.primary, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            child: const Text('VER TODOS OS BENEFÍCIOS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
