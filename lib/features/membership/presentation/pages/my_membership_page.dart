import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_contact_config.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class MyMembershipPage extends StatelessWidget {
  const MyMembershipPage({required this.membership, super.key});

  final Membership membership;

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  PageTitle(context.l10n.membershipMyMembership.toUpperCase()),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: ListView(
                      children: [
                        _InfoCard(
                          rows: [
                            _InfoRow(
                              context.l10n.membershipPlanLabel,
                              membership.plan.name,
                            ),
                            if (membership.plan.stadiumSector != null)
                              _InfoRow(
                                context.l10n.membershipSectorLabel,
                                membership.plan.stadiumSector!,
                              ),
                            _InfoRow(
                              context.l10n.membershipSituation,
                              _statusLabel(context.l10n, membership.status),
                            ),
                            if (membership.memberNumber != null)
                              _InfoRow(
                                context.l10n.membershipMemberNumber,
                                membership.memberNumber!,
                              ),
                            _InfoRow(
                              context.l10n.membershipMonthlyFee,
                              '${formatBrl(membership.planPrice.monthlyPrice)}${context.l10n.membershipPerMonth}',
                            ),
                            _InfoRow(
                              context.l10n.membershipAnnualFee,
                              formatBrl(membership.planPrice.annualPrice),
                            ),
                            if (membership.startedAt != null)
                              _InfoRow(
                                context.l10n.membershipMemberSince,
                                _formatDate(membership.startedAt!),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          context.l10n.membershipBenefits,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.textHint,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              for (final benefit in membership.plan.benefits)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 17,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          benefit,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _OptionRow(
                          icon: Icons.gavel_rounded,
                          label: context.l10n.membershipRegulationName,
                          onTap: () => context.push('/membership/regulation'),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => openExternalUrl(
                              context,
                              MembershipContactConfig.whatsappUrlWithMessage(
                                context.l10n.membershipCancelWhatsapp(
                                  membership.plan.name,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.error,
                              side: BorderSide(color: colors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                            child: Text(context.l10n.membershipCancel),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.membershipCancelInfo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textHint,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
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

String _statusLabel(AppLocalizations l10n, MembershipStatus status) =>
    switch (status) {
      MembershipStatus.active => l10n.membershipStatusActive,
      MembershipStatus.pending => l10n.membershipStatusPending,
      MembershipStatus.suspended => l10n.membershipStatusSuspended,
      MembershipStatus.cancelled => l10n.membershipStatusCancelled,
      MembershipStatus.none => '-',
    };

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: rows),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
