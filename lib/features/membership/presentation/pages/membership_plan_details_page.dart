import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_commitment_period.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';

class MembershipPlanDetailsPage extends StatefulWidget {
  const MembershipPlanDetailsPage({required this.planId, super.key});

  final String planId;

  @override
  State<MembershipPlanDetailsPage> createState() =>
      _MembershipPlanDetailsPageState();
}

class _MembershipPlanDetailsPageState extends State<MembershipPlanDetailsPage> {
  late final MembershipPlan plan = sl<ClubConfig>().membershipProgram.plans
      .firstWhere((p) => p.id == widget.planId);
  late MembershipPlanPrice selectedPrice = plan.defaultPrice;

  // Enquanto o registro está em andamento, esta própria tela não pode ser
  // fechada (nem pelo botão de voltar, nem pelo gesto do sistema) — senão o
  // `context.pop(result)` abaixo tenta completar de novo um Future que o
  // pop antecipado já completou, e o app quebra com "Future already
  // completed".
  bool _registering = false;

  /// Quando o programa tem `externalCheckoutUrl` (provedor terceiro real,
  /// ex. Ingressos SA), o CTA abre esse link em vez de simular um cadastro
  /// que não completa nenhuma adesão de verdade — recriar aquele checkout
  /// aqui dentro enganaria o torcedor.
  String? get _externalCheckoutUrl =>
      sl<ClubConfig>().membershipProgram.externalCheckoutUrl;

  Future<void> _handleCta() async {
    final externalUrl = _externalCheckoutUrl;
    if (externalUrl != null) {
      await openExternalUrl(context, externalUrl);
      return;
    }
    await _startRegistration();
  }

  Future<void> _startRegistration() async {
    if (_registering) return;
    setState(() => _registering = true);
    final result = await context.push<String>(
      '/membership/register',
      extra: (plan: plan, price: selectedPrice),
    );
    if (!mounted) return;
    setState(() => _registering = false);
    if (result != null) context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !_registering,
      child: Scaffold(
        backgroundColor: colors.background,
        body: Column(
          children: [
            Expanded(
              child: DetailPageHeader(
                title: plan.name,
                heroTitle: _PlanHeroTitle(plan: plan),
                onBack: _registering ? () {} : null,
                body: _PlanBody(
                  plan: plan,
                  selectedPrice: selectedPrice,
                  onSelectPrice: (price) =>
                      setState(() => selectedPrice = price),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _registering ? null : _handleCta,
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
                    child: Text(context.l10n.membershipWantToJoin),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanHeroTitle extends StatelessWidget {
  const _PlanHeroTitle({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.highlight) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.gold,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              context.l10n.membershipMostChosen,
              style: const TextStyle(
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
        if (plan.sectorsLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              context.l10n.membershipSector(plan.sectorsLabel.toString()),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.plan,
    required this.selectedPrice,
    required this.onSelectPrice,
  });

  final MembershipPlan plan;
  final MembershipPlanPrice selectedPrice;
  final ValueChanged<MembershipPlanPrice> onSelectPrice;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        if (plan.prices.length > 1) ...[
          Row(
            children: [
              for (final price in plan.prices)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(price.label),
                    selected: selectedPrice == price,
                    onSelected: (_) => onSelectPrice(price),
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
                text: context.l10n.membershipPerMonth,
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
          plan.commitmentPeriod == MembershipCommitmentPeriod.annualContract
              ? context.l10n.membershipAnnualContractInfo(
                  formatBrl(selectedPrice.annualPrice),
                )
              : context.l10n.membershipOrAnnual(
                  formatBrl(selectedPrice.annualPrice),
                ),
          style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.membershipBenefits,
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
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
        if (sl<ClubConfig>().membershipProgram.hasRegulationContent)
          GestureDetector(
            onTap: () => context.push('/membership/regulation'),
            child: Text(
              context.l10n.membershipSeeFullRegulation,
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
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.membershipStillHaveDoubts,
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
                      initialCategoryId: 'planos-e-cancelamento',
                      initialQuery: null,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  child: Text(context.l10n.membershipSeeFaq),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
