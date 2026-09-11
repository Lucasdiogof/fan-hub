import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Boas-vindas oficiais ao novo sócio, exibida só depois de um resultado de
/// sucesso de [MembershipRepository.submitRegistration] — nunca só porque o
/// formulário chegou ao fim. Não busca dado nenhum sozinha: tudo vem da
/// associação real recém-criada.
class MembershipSuccessPage extends StatelessWidget {
  const MembershipSuccessPage({
    required this.membership,
    required this.holderName,
    required this.onGoToMemberArea,
    required this.onGoHome,
    this.holderCpf,
    super.key,
  });

  final Membership membership;
  final String holderName;
  final String? holderCpf;
  final VoidCallback onGoToMemberArea;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _SuccessHero(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ContentWidth.detail.maxWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    children: [
                      _SectionHeader(context.l10n.membershipYourMembership),
                      const SizedBox(height: AppSpacing.md),
                      _SummaryCard(
                        membership: membership,
                        holderName: holderName,
                        holderCpf: holderCpf,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeader(context.l10n.membershipYourBenefits),
                      const SizedBox(height: AppSpacing.md),
                      _BenefitsSummary(plan: membership.plan),
                      const SizedBox(height: AppSpacing.xl),
                      const _NextSteps(),
                      const SizedBox(height: AppSpacing.xxxl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onGoToMemberArea,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          child: Text(context.l10n.membershipGoToMemberArea),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: onGoHome,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                          ),
                          child: Text(
                            context.l10n.membershipBackToHome,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: colors.textHint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.brandDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.hero),
          bottomRight: Radius.circular(AppRadius.hero),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ClubBadge.activeClub(size: 20, onDark: true),
              const SizedBox(width: AppSpacing.sm),
              Text(
                sl<ClubConfig>().productNames.membershipProgramName
                    .toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _AnimatedSuccessCheck(),
          const SizedBox(height: AppSpacing.lg),
          if (sl<ClubConfig>().capabilities.membershipCommerceMode ==
              CommerceMode.demo) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Text(
                context.l10n.membershipStatusDemoBadge.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            context.l10n.membershipWelcome(
              sl<ClubConfig>().productNames.membershipProgramName.toUpperCase(),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.membershipSuccessMessage(
              sl<ClubConfig>().identity.shortName,
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Curta e discreta — um "pop" elegante no check, não uma animação de
/// celebração infantil (confete, bounce exagerado etc.).
class _AnimatedSuccessCheck extends StatefulWidget {
  const _AnimatedSuccessCheck();

  @override
  State<_AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<_AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.membership,
    required this.holderName,
    this.holderCpf,
  });

  final Membership membership;
  final String holderName;
  final String? holderCpf;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plan = membership.plan;
    final price = membership.planPrice;
    final maskedCpf = holderCpf == null ? null : _maskCpf(holderCpf!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const _ActivePill(),
            ],
          ),
          if (price.label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              price.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ],
          if (plan.sectorsLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.lg),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatBrl(price.monthlyPrice),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: context.l10n.membershipPerMonth,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.membershipAnnualPlan(formatBrl(price.annualPrice)),
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.lg),
          _LabelValue(label: context.l10n.membershipHolder, value: holderName),
          if (maskedCpf != null && maskedCpf.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'CPF $maskedCpf',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
          if (membership.startedAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            _LabelValue(
              label: context.l10n.membershipAssociatedSince,
              value: _formatDate(membership.startedAt!),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textHint,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: colors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          context.l10n.membershipStatusActive.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.success,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _BenefitsSummary extends StatelessWidget {
  const _BenefitsSummary({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = plan.benefits.take(4).toList();
    final hasMore = plan.benefits.length > shown.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final benefit in shown)
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
          if (hasMore)
            GestureDetector(
              onTap: () => context.push('/membership/plans/${plan.id}'),
              child: Text(
                context.l10n.membershipSeeAllBenefits,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextSteps extends StatelessWidget {
  const _NextSteps();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.explore_rounded, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.membershipWhatNow,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.membershipWhatNowMessage,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _maskCpf(String rawCpf) {
  final digits = rawCpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return '';
  return '•••.•••.•••-${digits.substring(9)}';
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
