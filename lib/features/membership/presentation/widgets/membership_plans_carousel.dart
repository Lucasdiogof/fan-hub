import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_plan_card.dart';

/// Horizontal com o próximo card parcialmente visível — mobile-first (~85%
/// da largura); em telas largas (tablet/PWA) mostra 2-3 cards por vez.
class MembershipPlansCarousel extends StatelessWidget {
  const MembershipPlansCarousel({
    required this.plans,
    required this.onSelectPlan,
    super.key,
  });

  final List<MembershipPlan> plans;
  final ValueChanged<MembershipPlan> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 700
            ? constraints.maxWidth / 2.6
            : constraints.maxWidth * 0.85;
        return SizedBox(
          height: 380,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plans.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return SizedBox(
                width: cardWidth,
                child: MembershipPlanCard(
                  plan: plan,
                  onTap: () => onSelectPlan(plan),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
