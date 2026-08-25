import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/presentation/widgets/help_and_info_section.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_hero.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_plans_carousel.dart';

class NonMemberView extends StatelessWidget {
  const NonMemberView({
    required this.plans,
    required this.onSelectPlan,
    super.key,
  });

  final List<MembershipPlan> plans;
  final ValueChanged<MembershipPlan> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        const MembershipHero(),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'ESCOLHA SEU PLANO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        MembershipPlansCarousel(plans: plans, onSelectPlan: onSelectPlan),
        const SizedBox(height: AppSpacing.xxxl),
        const HelpAndInfoSection(),
      ],
    );
  }
}
