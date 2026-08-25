import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_plans_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';

class MembershipPlanDetailsPage extends StatefulWidget {
  const MembershipPlanDetailsPage({required this.planId, super.key});

  final String planId;

  @override
  State<MembershipPlanDetailsPage> createState() =>
      _MembershipPlanDetailsPageState();
}

class _MembershipPlanDetailsPageState extends State<MembershipPlanDetailsPage> {
  late final MembershipPlan plan = MembershipPlansCatalog.plans.firstWhere(
    (p) => p.id == widget.planId,
  );
  late MembershipPlanPrice selectedPrice = plan.defaultPrice;

  Future<void> _startRegistration() async {
    final result = await context.push<String>(
      '/membership/register',
      extra: (plan: plan, price: selectedPrice),
    );
    if (result != null && mounted) context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      children: [
                        if (plan.highlight) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.gold,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'MAIS ESCOLHIDO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.tagline,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (plan.stadiumSector != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'Setor ${plan.stadiumSector}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        if (plan.prices.length > 1) ...[
                          Row(
                            children: [
                              for (final price in plan.prices)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.sm,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(price.label),
                                    selected: selectedPrice == price,
                                    onSelected: (_) =>
                                        setState(() => selectedPrice = price),
                                    selectedColor: colors.secondary,
                                    labelStyle: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: selectedPrice == price
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                    side: BorderSide(
                                      color: selectedPrice == price
                                          ? colors.primary
                                          : colors.border,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: formatBrl(selectedPrice.monthlyPrice),
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: '/mês',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ou ${formatBrl(selectedPrice.annualPrice)} no plano anual',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'BENEFÍCIOS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final benefit in plan.benefits)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        GestureDetector(
                          onTap: () => context.push('/membership/regulation'),
                          child: Text(
                            'Consulte o regulamento completo →',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            borderRadius: BorderRadius.circular(
                              AppRadius.cardSmall,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ainda tem dúvidas sobre este plano?',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => context.push(
                                    '/membership/faq',
                                    extra: (
                                      initialCategoryId:
                                          'planos-e-cancelamento',
                                      initialQuery: null,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.button,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  child: const Text('VER DÚVIDAS FREQUENTES'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.huge),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startRegistration,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      child: const Text('QUERO SER SÓCIO'),
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
