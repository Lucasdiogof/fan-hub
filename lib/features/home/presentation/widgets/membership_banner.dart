import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class MembershipBanner extends StatelessWidget {
  const MembershipBanner({this.onViewPlans, super.key});

  final VoidCallback? onViewPlans;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.banner),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'SÓCIO ESMERALDA',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.homeMembershipPitch,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.22,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Benefit(label: context.l10n.homeMembershipBenefit1),
            const SizedBox(height: AppSpacing.sm),
            _Benefit(label: context.l10n.homeMembershipBenefit2),
            const SizedBox(height: AppSpacing.sm),
            _Benefit(label: context.l10n.homeMembershipBenefit3),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewPlans,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
                child: Text(context.l10n.homeMembershipCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 17, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
      ],
    );
  }
}
