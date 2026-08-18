import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/partners/data/partners_data.dart';
import 'package:goias_app/features/partners/presentation/widgets/partner_card.dart';
import 'package:goias_app/shared/widgets/section_header.dart';

/// Exposição discreta no fim da Home — carrossel horizontal, mesma fonte de
/// dados da PartnersPage completa. Não compete com próximo jogo/ingressos/
/// notícias porque só aparece depois delas.
class PartnersHomeSection extends StatelessWidget {
  const PartnersHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'PARCEIROS DO GOIÁS',
          actionLabel: 'Ver todos',
          onAction: () => context.push('/partners'),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PartnersData.all.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final partner = PartnersData.all[index];
              return SizedBox(
                width: 108,
                child: PartnerCard(partner: partner, logoHeight: 34, padding: AppSpacing.sm),
              );
            },
          ),
        ),
      ],
    );
  }
}
