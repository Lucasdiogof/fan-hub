import 'package:flutter/material.dart';
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
              'Esteja ainda mais perto do Goiás\ne faça parte dessa história!',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.22,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _Benefit(label: 'Prioridade de acesso ao estádio'),
            const SizedBox(height: AppSpacing.sm),
            const _Benefit(label: 'Economia no valor do ingresso'),
            const SizedBox(height: AppSpacing.sm),
            const _Benefit(label: 'Descontos exclusivos e muito mais'),
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
                child: const Text('SEJA SÓCIO ESMERALDINO'),
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
