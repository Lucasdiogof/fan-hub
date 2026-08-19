import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class MembershipBenefitsPage extends StatelessWidget {
  const MembershipBenefitsPage({required this.plan, super.key});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  PageTitle(plan.name),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final benefit in plan.benefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 18, color: colors.primary),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: TextStyle(fontSize: 14, height: 1.4, color: colors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
