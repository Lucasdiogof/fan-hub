import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_state.dart';
import 'package:goias_app/features/membership/presentation/widgets/digital_membership_card.dart';
import 'package:goias_app/features/membership/presentation/widgets/help_and_info_section.dart';
import 'package:goias_app/features/membership/presentation/widgets/member_next_match_card.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_options_card.dart';

/// Experiência de quem já é sócio ativo — gerenciamento da associação, não
/// vitrine de planos.
class MemberView extends StatelessWidget {
  const MemberView({required this.state, super.key});

  final MembershipState state;

  @override
  Widget build(BuildContext context) {
    final membership = state.membership!;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        InkWell(
          onTap: () => context.push('/membership/my', extra: membership),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: DigitalMembershipCard(
            holderName: state.user?.name ?? '',
            planName: membership.plan.name,
            status: membership.status,
            memberNumber: membership.memberNumber,
          ),
        ),
        if (state.nextMatch != null) ...[
          const SizedBox(height: AppSpacing.xl),
          MemberNextMatchCard(
            match: state.nextMatch!,
            onCheckIn: () => context.push(
              '/membership/coming-soon',
              extra: (title: 'CHECK-IN', message: 'O check-in do Sócio Esmeralda ainda não está disponível no app.'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          'OUTRAS OPÇÕES',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textHint, letterSpacing: 0.6),
        ),
        const SizedBox(height: AppSpacing.md),
        MembershipOptionsCard(
          options: [
            MembershipOption(
              icon: Icons.badge_outlined,
              label: 'Minha associação',
              onTap: () => context.push('/membership/my', extra: membership),
            ),
            MembershipOption(
              icon: Icons.family_restroom_rounded,
              label: 'Dependentes',
              onTap: () => context.push(
                '/membership/coming-soon',
                extra: (title: 'DEPENDENTES', message: 'A gestão de dependentes ainda está sendo preparada.'),
              ),
            ),
            MembershipOption(
              icon: Icons.receipt_long_rounded,
              label: 'Pagamentos',
              onTap: () => context.push(
                '/membership/coming-soon',
                extra: (title: 'PAGAMENTOS', message: 'O histórico de pagamentos ainda está sendo preparado.'),
              ),
            ),
            MembershipOption(
              icon: Icons.history_rounded,
              label: 'Histórico de check-ins',
              onTap: () => context.push(
                '/membership/coming-soon',
                extra: (title: 'HISTÓRICO DE CHECK-INS', message: 'Essa área ainda está sendo preparada.'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        const HelpAndInfoSection(),
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: TextButton(
            onPressed: () => context.push('/membership/plans'),
            style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
            child: const Text('Conhecer outros planos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
