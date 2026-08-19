import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/shared/utils/currency.dart';
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  const PageTitle('MINHA ASSOCIAÇÃO'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: ListView(
                      children: [
                        _InfoCard(
                          rows: [
                            _InfoRow('Plano', membership.plan.name),
                            if (membership.plan.stadiumSector != null) _InfoRow('Setor', membership.plan.stadiumSector!),
                            _InfoRow('Situação', _statusLabel(membership.status)),
                            if (membership.memberNumber != null) _InfoRow('Número do sócio', membership.memberNumber!),
                            _InfoRow('Mensalidade', '${formatBrl(membership.planPrice.monthlyPrice)}/mês'),
                            if (membership.startedAt != null) _InfoRow('Sócio desde', _formatDate(membership.startedAt!)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _OptionRow(
                          icon: Icons.gavel_rounded,
                          label: 'Regulamento do Sócio Esmeralda',
                          onTap: () => context.push('/membership/regulation'),
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

String _statusLabel(MembershipStatus status) => switch (status) {
  MembershipStatus.active => 'Ativo',
  MembershipStatus.pending => 'Pendente',
  MembershipStatus.suspended => 'Suspenso',
  MembershipStatus.cancelled => 'Cancelado',
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
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
