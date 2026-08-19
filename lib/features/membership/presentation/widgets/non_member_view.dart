import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/presentation/widgets/help_and_info_section.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_hero.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_plans_carousel.dart';

class NonMemberView extends StatelessWidget {
  const NonMemberView({required this.plans, required this.onSelectPlan, this.pendingMembership, super.key});

  final List<MembershipPlan> plans;
  final ValueChanged<MembershipPlan> onSelectPlan;

  /// Preenchido quando existe uma solicitação em análise — o status ainda
  /// não é `active`, então esta continua sendo a visão "não sócio", só que
  /// avisando que já há um pedido em andamento.
  final Membership? pendingMembership;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        if (pendingMembership != null) ...[
          _PendingBanner(membership: pendingMembership!),
          const SizedBox(height: AppSpacing.lg),
        ],
        const MembershipHero(),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'ESCOLHA SEU PLANO',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: 0.6),
        ),
        const SizedBox(height: AppSpacing.lg),
        MembershipPlansCarousel(plans: plans, onSelectPlan: onSelectPlan),
        const SizedBox(height: AppSpacing.xxxl),
        const HelpAndInfoSection(),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solicitação em análise',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Você pediu o plano ${membership.plan.name}. Assim que a integração oficial estiver disponível, sua adesão será confirmada.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
