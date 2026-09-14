import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/partners/domain/entities/partner.dart';
import 'package:goias_app/features/partners/presentation/widgets/partner_card.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class PartnersPage extends StatelessWidget {
  const PartnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clubConfig = sl<ClubConfig>();
    final partners = clubConfig.institutionalContent.partners;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BackButton(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.partnersTitle(
                          clubConfig.identity.shortName,
                        ),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.partnersSubtitle(
                          clubConfig.identity.shortName,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: partners.any((p) => p.tier != null)
                      // Só agrupa em seções (Institucional/Premium/
                      // Regional/Fornecedores) quando o clube já
                      // categorizou os parceiros por tier — nunca um
                      // `if (club == bragantino)`, e o Goiás (sem
                      // nenhum `tier` preenchido hoje) continua com a
                      // grid única de sempre, comportamento intacto.
                      ? _TieredPartnersList(partners: partners)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxxl,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 230,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 1.3,
                              ),
                          itemCount: partners.length,
                          itemBuilder: (context, index) =>
                              PartnerCard(partner: partners[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ordem fixa e final — Institucional primeiro (relação estrutural, nunca
/// misturada com patrocínio comercial), depois Premium/Regional/
/// Fornecedores. Seção sem nenhum parceiro simplesmente não aparece (nunca
/// um cabeçalho vazio).
const _tierOrder = [
  PartnerRelationshipTier.institutional,
  PartnerRelationshipTier.premiumSponsor,
  PartnerRelationshipTier.regionalSponsor,
  PartnerRelationshipTier.officialSupplier,
];

class _TieredPartnersList extends StatelessWidget {
  const _TieredPartnersList({required this.partners});

  final List<Partner> partners;

  String _tierLabel(BuildContext context, PartnerRelationshipTier tier) =>
      switch (tier) {
        PartnerRelationshipTier.institutional =>
          context.l10n.partnersTierInstitutional,
        PartnerRelationshipTier.premiumSponsor =>
          context.l10n.partnersTierPremium,
        PartnerRelationshipTier.regionalSponsor =>
          context.l10n.partnersTierRegional,
        PartnerRelationshipTier.officialSupplier =>
          context.l10n.partnersTierOfficialSupplier,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        for (final tier in _tierOrder) ...[
          if (partners.where((p) => p.tier == tier).toList()
              case final tierPartners when tierPartners.isNotEmpty) ...[
            Text(
              _tierLabel(context, tier).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.3,
              ),
              itemCount: tierPartners.length,
              itemBuilder: (context, index) =>
                  PartnerCard(partner: tierPartners[index]),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
