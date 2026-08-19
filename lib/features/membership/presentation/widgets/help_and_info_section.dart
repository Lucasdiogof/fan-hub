import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_contact_config.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_options_card.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';

/// Presente tanto pra quem é sócio quanto pra quem não é — dúvidas,
/// regulamento e atendimento não dependem de já ter uma associação ativa.
class HelpAndInfoSection extends StatelessWidget {
  const HelpAndInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AJUDA E INFORMAÇÕES',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textHint, letterSpacing: 0.6),
        ),
        const SizedBox(height: AppSpacing.md),
        MembershipOptionsCard(
          options: [
            MembershipOption(
              icon: Icons.help_outline_rounded,
              label: 'Dúvidas frequentes',
              onTap: () => context.push('/membership/faq'),
            ),
            MembershipOption(
              icon: Icons.gavel_rounded,
              label: 'Regulamento do Sócio Esmeralda',
              onTap: () => context.push('/membership/regulation'),
            ),
            MembershipOption(
              icon: Icons.support_agent_rounded,
              label: 'Falar com o atendimento',
              onTap: () => openExternalUrl(context, MembershipContactConfig.whatsappUrl),
            ),
          ],
        ),
      ],
    );
  }
}
